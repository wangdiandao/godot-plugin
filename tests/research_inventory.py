"""Author-only inventory for the pinned English documentation review.

Enumeration never marks a document as read. Review files are authored separately.
"""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

REVISION = "9adca4c1c72917bfe1b7be3108abed5ce26696a6"
ROOT_PAGES = {"index.rst", "404.rst"}
AREAS = {"about", "classes", "community", "engine_details", "getting_started", "tutorials"}
SKILLS = {"godot-" + name for name in (
    "2d", "3d", "animation", "api", "assets", "audio", "data", "export",
    "gdscript", "multiplayer", "navigation", "physics", "project", "rendering",
    "scenes", "ui", "validation", "workflow", "architecture", "performance",
    "editor-tools", "csharp", "gdextension",
)}
GENERATED_PAGES = {"search.html", "genindex.html"}


def inventory(snapshot):
    revision = subprocess.check_output(
        ["git", "-C", str(snapshot), "rev-parse", "HEAD"], text=True
    ).strip()
    if revision != REVISION:
        raise ValueError(f"Unexpected documentation revision: {revision}")
    if subprocess.check_output(
        ["git", "-C", str(snapshot), "status", "--porcelain"], text=True
    ).strip():
        raise ValueError("Documentation snapshot has local changes")
    pages = []
    tracked = subprocess.check_output(
        ["git", "-C", str(snapshot), "ls-files", "-z"], text=True
    ).split("\0")
    for relative in sorted(name for name in tracked if name.endswith(".rst")):
        source = snapshot / relative
        relative = source.relative_to(snapshot).as_posix()
        if relative not in ROOT_PAGES and relative.split("/")[0] not in AREAS:
            raise ValueError(f"Unclassified RST source: {relative}")
        payload = source.read_bytes()
        pages.append({
            "path": relative,
            "url": "https://docs.godotengine.org/en/4.7/" + relative[:-4] + ".html",
            "source_url": f"https://github.com/godotengine/godot-docs/blob/{revision}/{relative}",
            "sha256": hashlib.sha256(payload).hexdigest(),
            "bytes": len(payload),
            "status": "pending",
        })
    return {"schema_version": 1, "revision": revision, "pages": pages}


def validate(data, review_dir, source_root=None):
    expected = {page["path"]: page for page in data["pages"]}
    reviewed = {}
    errors = []
    if data.get("revision") != REVISION:
        errors.append("Inventory revision is not the pinned documentation revision")
    if not expected:
        errors.append("Inventory has no pages")
    if len(expected) != len(data["pages"]):
        errors.append("Duplicate inventory paths")
    if source_root is not None:
        actual_paths = {path.relative_to(source_root).as_posix() for path in source_root.rglob("*.rst") if path.is_file()}
        if actual_paths != set(expected):
            errors.append("Inventory does not cover exactly the local RST source pages")
        for path, page in expected.items():
            source = source_root / path
            if not source.is_file() or hashlib.sha256(source.read_bytes()).hexdigest() != page["sha256"]:
                errors.append(f"Source does not match inventory: {path}")
    for filename in sorted(review_dir.glob("*.json")):
        entries = json.loads(filename.read_text(encoding="utf-8"))
        if not isinstance(entries, list):
            errors.append(f"Review file must contain an array: {filename.name}")
            continue
        for entry in entries:
            if not isinstance(entry, dict):
                errors.append(f"Review entry must be an object: {filename.name}")
                continue
            path = entry.get("path")
            if path not in expected:
                errors.append(f"Unknown page: {path}")
                continue
            if path in reviewed:
                errors.append(f"Duplicate review: {path}")
                continue
            entry_errors = []
            if entry.get("sha256") != expected[path]["sha256"]:
                entry_errors.append(f"Stale review: {path}")
            if entry.get("status") != "read":
                entry_errors.append(f"Invalid review status: {path}")
            findings = entry.get("findings")
            if not isinstance(findings, list) or not findings or not all(
                isinstance(finding, str) and finding.strip() for finding in findings
            ) or not isinstance(entry.get("reviewer"), str) or not entry["reviewer"].strip():
                entry_errors.append(f"Missing authored findings/reviewer: {path}")
            skills = entry.get("skills", [])
            boundary = entry.get("boundary", "")
            if not isinstance(skills, list) or not all(
                isinstance(skill, str) and skill in SKILLS
                for skill in skills
            ) or not isinstance(boundary, str):
                entry_errors.append(f"Malformed skill mapping or boundary: {path}")
            elif not skills and not boundary.strip():
                entry_errors.append(f"Missing skill mapping or boundary: {path}")
            errors.extend(entry_errors)
            reviewed[path] = not entry_errors
    valid = sum(reviewed.values())
    return {
        "revision": data["revision"], "total": len(expected),
        "read": valid, "pending": len(expected) - valid,
        "source_bytes": sum(page.get("bytes", 0) for page in expected.values()),
        "read_source_bytes": sum(expected[path].get("bytes", 0) for path, ok in reviewed.items() if ok),
        "errors": errors,
        "complete": not errors and valid == len(expected),
    }


def validate_generated(filename, html_root=None):
    entries = json.loads(filename.read_text(encoding="utf-8"))
    errors = []
    seen = set()
    read = 0
    if not isinstance(entries, list):
        return {"total": 2, "read": 0, "pending": 2,
                "errors": ["Generated reviews must contain an array"], "complete": False}
    for entry in entries:
        if not isinstance(entry, dict):
            errors.append("Generated review must be an object")
            continue
        path = entry.get("path")
        if path not in GENERATED_PAGES or path in seen:
            errors.append(f"Unknown or duplicate generated page: {path}")
            continue
        seen.add(path)
        valid = (
            entry.get("source_revision") == REVISION
            and entry.get("status") == "read"
            and isinstance(entry.get("reviewer"), str) and bool(entry["reviewer"].strip())
            and isinstance(entry.get("build"), str) and bool(entry["build"].strip())
            and isinstance(entry.get("sha256"), str)
            and re.fullmatch(r"[a-f0-9]{64}", entry["sha256"]) is not None
            and isinstance(entry.get("findings"), list) and bool(entry["findings"])
            and all(isinstance(value, str) and value.strip() for value in entry["findings"])
            and isinstance(entry.get("skills"), list) and bool(entry["skills"])
            and all(isinstance(value, str) and value in SKILLS for value in entry["skills"])
        )
        if html_root is not None:
            source = html_root / path
            valid = valid and source.is_file() and hashlib.sha256(source.read_bytes()).hexdigest() == entry.get("sha256")
        if valid:
            read += 1
        else:
            errors.append(f"Invalid or stale generated review: {path}")
    errors.extend(f"Missing generated page: {path}" for path in sorted(GENERATED_PAGES - seen))
    return {"total": 2, "read": read, "pending": 2 - read,
            "errors": errors, "complete": not errors and read == 2}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--snapshot", type=Path)
    parser.add_argument("--inventory", type=Path, required=True)
    parser.add_argument("--reviews", type=Path)
    parser.add_argument("--source", type=Path, help="Verify inventory against the local RST snapshot")
    parser.add_argument("--generated-reviews", type=Path)
    parser.add_argument("--html-root", type=Path, help="Verify generated HTML hashes")
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    if args.snapshot:
        data = inventory(args.snapshot.resolve())
        args.inventory.parent.mkdir(parents=True, exist_ok=True)
        args.inventory.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    else:
        data = json.loads(args.inventory.read_text(encoding="utf-8"))
    result = validate(data, args.reviews or args.inventory.parent / "page-reviews", args.source)
    if args.html_root and not args.generated_reviews:
        parser.error("--html-root requires --generated-reviews")
    if args.generated_reviews:
        result["generated"] = validate_generated(args.generated_reviews, args.html_root)
        result["errors"].extend(result["generated"]["errors"])
        result["complete"] = result["complete"] and result["generated"]["complete"]
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return int(bool(result["errors"]) or (args.require_complete and not result["complete"]))


if __name__ == "__main__":
    raise SystemExit(main())
