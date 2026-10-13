# Testing policy

**English** | [简体中文](testing.zh.md) · [Documentation](README.md)

## Match verification to the change

| Change | Required evidence |
|---|---|
| Documentation/metadata | Structure, local Markdown links, inventory and language consistency |
| Skill behavior | Affected normal cases and negative controls with expected causes |
| Shared execution | Core suite, logs, process lifecycle, timeouts and result interpretation |
| Rendering/UI | Real GPU/window and suitable input/artifact checks |
| Audio | State/data checks plus listening when audible quality is claimed |
| Packaging | Required/excluded members, byte/hash readback and relocated execution |
| Host discovery/routing | Actual installed-host discovery and model invocation, recorded separately from manifest checks |

Headless logic checks, manifest validity, semantic routing and user-visible acceptance establish different facts. Run only the checks appropriate to the change and state the remaining scope explicitly.

## Author structure check

From the repository root:

```text
python -X utf8 tests/validate_structure.py --root .
```

This requires Python and PyYAML for maintenance, not plugin runtime. It checks host metadata, Skill contracts, capability/case references, both root READMEs and local Markdown links in Skills, shared files and docs.

With the existing local research schema and `jsonschema` available:

```text
python -X utf8 tests/validate_structure.py --root . --schema artifacts/research/plugin.schema.json --report artifacts/docs-structure.json
```

The schema is ignored and not included in a clean checkout. The first command does not perform schema validation; do not report it as a schema pass. Generated reports stay outside Git.

## Native checks

Full suite, desktop/assets/failure integrations and package commands are maintained in [authoring.md](authoring.md). Resolve `GODOT`, `PLUGIN`, `OUT` and templates to actual absolute paths, use a fresh output directory and create log parents. Examples and helpers follow the [execution contract](../shared/references/execution.md). Source case manifests are not part of the installation archive; reproduction of source-suite commands requires a source checkout.

## Result interpretation

Helpers emit `GODOT_PLUGIN_RESULT:` JSON with engine/platform, status, checks, errors and artifacts. Check the child report together with complete outer-process logs, exit code, wall-clock termination and actual outputs. A `passed` marker cannot hide an error during startup/shutdown or a missing saved file.

Negative controls pass only when the expected failure cause is recognized. `unsupported`, missing-toolchain controls and intentional timeouts do not certify successful execution of the blocked operation. Historical reports are indexed in [evidence](evidence.md); record new commands/results in the PR instead of borrowing old evidence.
