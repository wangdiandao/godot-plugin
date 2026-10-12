# Repository Guidelines

## Project Structure & Module Organization

This Codex plugin uses native Godot CLI and GDScript; its documented baseline is Godot 4.7.2 standard edition.

- `skills/godot-*/`: 18 domain skills, each with `SKILL.md`, `agents/openai.yaml`, `references/native.md`, and runnable `assets/examples/minimal/` projects.
- `shared/scripts/`: reusable execution, inspection, screenshot, and template helpers; `shared/host/` provides a neutral tool project.
- `tests/`: case manifests, routing prompts, failure fixtures, and integration scripts.
- `docs/`: authoring rules, capability evidence, and validation summaries.
- `plugin.json`, `.codex-plugin/plugin.json`, and `.agents/plugins/marketplace.json`: coordinated plugin metadata.
- `artifacts/` and `dist/`: local evidence and generated packages; exclude research downloads and caches from releases.

## Build, Test, and Development Commands

Run from the repository root. Replace `GODOT`, `PLUGIN`, and `OUT` with absolute paths; use a fresh writable output directory.

```text
python -X utf8 tests/validate_structure.py --root PLUGIN
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/shared/scripts/run_checks.gd -- --manifest PLUGIN/tests/cases.json --out OUT/cases
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/package.gd -- --root PLUGIN --out PLUGIN/dist
```

These validate structure, run regression cases, and build packages. Python and PyYAML are author-only dependencies; schema validation needs jsonschema. See `docs/authoring.md` for integration commands and template requirements.

## Coding Style & Naming Conventions

Match existing files: tabs and explicit types in GDScript, four spaces in Python, and two spaces in JSON. Use `snake_case` for functions and variables, and `godot-<domain>` for skill directories. Keep skill frontmatter names aligned with directories and default prompts. No dedicated formatter or linter is configured; use structural and native checks.

## Testing Guidelines

Tests use a custom GDScript runner and Python structural checks. Add descriptive case IDs to `tests/cases.json`; keep intentional failures in isolated fixtures. Update routing prompts when trigger boundaries change. Validate logs, exit codes, assertions, and artifacts together. Rendering needs a real GPU; desktop integration needs Windows and matching export templates. No percentage coverage threshold is defined. Record only executed evidence in capability and validation summaries.

## Commit & Pull Request Guidelines

Git history is unavailable. Use imperative subjects describing the affected area. PRs should explain behavior changes, link issues, list executed checks and platform conditions, and include screenshots for visual changes. Synchronize manifests and marketplace metadata for releases.

## Agent-Specific Instructions

Use Context7 for current library, SDK, API, and CLI documentation questions; resolve the library first, then query each concept separately. Confirm Godot bindings against version-matched official sources. Context7 remains a research tool, not a runtime dependency. Preserve user edits and scope cleanup to verified, task-created directories.
