"""Evidence-gate regression cases; no Godot or network access needed."""
import copy
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from research_inventory import REVISION, validate, validate_generated


class ResearchEvidenceTests(unittest.TestCase):
    def setUp(self):
        scratch = Path(__file__).resolve().parent.parent / "artifacts" / "research-inventory-tests"
        scratch.mkdir(parents=True, exist_ok=True)
        self.work = tempfile.TemporaryDirectory(dir=scratch)
        self.addCleanup(self.work.cleanup)
        self.reviews = Path(self.work.name)
        self.inventory = {
            "revision": REVISION,
            "pages": [{"path": "classes/class_node.rst", "sha256": "current-hash"}],
        }
        self.review = {
            "path": "classes/class_node.rst", "sha256": "current-hash",
            "status": "read", "reviewer": "reviewer-a", "skills": ["godot-scenes"],
            "findings": ["New descendants need scene ownership before packing."],
        }

    def write(self, entries, name="a.json"):
        (self.reviews / name).write_text(json.dumps(entries), encoding="utf-8")

    def result(self):
        return validate(self.inventory, self.reviews)

    def test_downloaded_inventory_does_not_pass_reading_gate(self):
        result = self.result()
        self.assertFalse(result["complete"])
        self.assertEqual((result["read"], result["pending"]), (0, 1))

    def test_complete_authored_evidence_passes(self):
        self.write([self.review])
        self.assertTrue(self.result()["complete"])

    def test_source_change_invalidates_existing_review(self):
        self.write([self.review])
        self.inventory["pages"][0]["sha256"] = "changed-hash"
        result = self.result()
        self.assertFalse(result["complete"])
        self.assertEqual(result["read"], 0)
        self.assertIn("Stale review", result["errors"][0])

    def test_duplicate_reviewers_do_not_double_count_or_pass(self):
        self.write([self.review])
        second = dict(self.review, reviewer="reviewer-b")
        self.write([second], "b.json")
        result = self.result()
        self.assertFalse(result["complete"])
        self.assertEqual(result["read"], 1)
        self.assertIn("Duplicate review", result["errors"][0])

    def test_unknown_source_cannot_satisfy_missing_page(self):
        self.write([dict(self.review, path="other-version/node.rst")])
        self.assertFalse(self.result()["complete"])
        self.assertEqual(self.result()["read"], 0)

    def test_unread_and_unmapped_or_empty_reviews_fail(self):
        for changes in [
            {"status": "downloaded"}, {"findings": []}, {"findings": [""]},
            {"findings": "not an authored findings array"}, {"skills": []},
            {"reviewer": ""}, {"skills": "godot-scenes"}, {"boundary": []},
        ]:
            with self.subTest(changes=changes):
                self.write([dict(self.review, **changes)])
                self.assertFalse(self.result()["complete"])
                self.assertEqual(self.result()["read"], 0)

    def test_explicit_scope_boundary_is_valid(self):
        self.write([dict(self.review, skills=[], boundary="Engine contributor internals.")])
        self.assertTrue(self.result()["complete"])

    def test_duplicate_inventory_and_malformed_records_fail(self):
        self.inventory["pages"].append(copy.deepcopy(self.inventory["pages"][0]))
        self.write([self.review])
        self.assertFalse(self.result()["complete"])
        self.inventory["pages"].pop()
        for value in [{"entries": [self.review]}, ["invalid"]]:
            self.write(value)
            self.assertFalse(self.result()["complete"])

    def test_unregistered_skill_mapping_fails(self):
        self.write([dict(self.review, skills=["godot-typo"])])
        self.assertFalse(self.result()["complete"])

    def test_wrong_revision_and_empty_inventory_cannot_pass(self):
        self.write([self.review])
        self.inventory["revision"] = "other-version"
        self.assertFalse(self.result()["complete"])
        self.inventory["revision"] = REVISION
        self.inventory["pages"] = []
        self.assertFalse(self.result()["complete"])

    def test_actual_source_change_invalidates_gate(self):
        source = self.reviews / "source"
        (source / "classes").mkdir(parents=True)
        payload = b"Pinned source"
        path = source / "classes/class_node.rst"
        path.write_bytes(payload)
        digest = hashlib.sha256(payload).hexdigest()
        self.inventory["pages"][0]["sha256"] = digest
        self.write([dict(self.review, sha256=digest)])
        self.assertTrue(validate(self.inventory, self.reviews, source)["complete"])
        path.write_bytes(b"Changed source")
        self.assertFalse(validate(self.inventory, self.reviews, source)["complete"])
        path.write_bytes(payload)
        (source / "classes/class_resource.rst").write_bytes(b"Omitted source")
        self.assertFalse(validate(self.inventory, self.reviews, source)["complete"])

    def test_generated_pages_require_authored_reviews_and_matching_html(self):
        html = self.reviews / "html"
        html.mkdir()
        rows = []
        for name in ("search.html", "genindex.html"):
            payload = name.encode()
            (html / name).write_bytes(payload)
            rows.append(dict(path=name, source_revision=REVISION, status="read",
                             reviewer="reviewer", build="Pinned Sphinx build",
                             sha256=hashlib.sha256(payload).hexdigest(),
                             skills=["godot-api"], findings=["Navigation content reviewed."]))
        filename = self.reviews / "generated.json"
        filename.write_text(json.dumps(rows), encoding="utf-8")
        self.assertTrue(validate_generated(filename, html)["complete"])
        (html / "search.html").write_text("Changed HTML")
        self.assertFalse(validate_generated(filename, html)["complete"])
        for changes in ({"status": "pending"}, {"findings": []}, {"source_revision": "other"}):
            filename.write_text(json.dumps([dict(rows[0], **changes), rows[1]]), encoding="utf-8")
            self.assertFalse(validate_generated(filename)["complete"])

    def test_missing_or_duplicate_generated_page_fails(self):
        filename = self.reviews / "generated.json"
        filename.write_text("[]", encoding="utf-8")
        self.assertEqual(validate_generated(filename)["pending"], 2)
        filename.write_text('[{"path":"search.html"},{"path":"search.html"}]', encoding="utf-8")
        self.assertIn("Unknown or duplicate generated page: search.html",
                      validate_generated(filename)["errors"])


if __name__ == "__main__":
    unittest.main()
