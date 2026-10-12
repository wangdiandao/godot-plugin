# Repository Guidelines

## Project Structure & Module Organization

This Codex plugin uses Godot CLI/GDScript; baseline: Godot 4.7.2 standard edition.

- `skills/godot-*/`: domain skills, references, UI metadata, and runnable examples.
- `shared/`: native tools, neutral host project, and execution conventions.
- `tests/`: manifests, routing prompts, fixtures, and integration scripts.
- `docs/`: authoring rules and validation evidence.
- `plugin.json`, `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`: coordinated metadata.
- `artifacts/`, `dist/`: ignored evidence and packages; exclude caches/research from releases.

## Build, Test, and Development Commands

From the root, replace `GODOT`, `PLUGIN`, `OUT` with absolute paths; use fresh output directories.

```text
python -X utf8 tests/validate_structure.py --root PLUGIN
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/shared/scripts/run_checks.gd -- --manifest PLUGIN/tests/cases.json --out OUT/cases
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/package.gd -- --root PLUGIN --out PLUGIN/dist
```

Commands check structure, run regressions, and package releases. Python/PyYAML are author-only dependencies; optional schema validation needs jsonschema. See `docs/authoring.md` for integration requirements.

## Coding Style & Naming Conventions

Use tabs and explicit types in GDScript, four spaces in Python, two in JSON; `snake_case` functions/variables and `godot-<domain>` directories. No dedicated formatter/linter is configured.

## Testing Guidelines

Use the custom GDScript runner and Python checks. Add descriptive case IDs and isolated negative fixtures. Assess logs, exit codes, assertions, and artifacts together. Rendering needs a GPU; desktop integration needs Windows/matching templates. Record executed evidence only; no percentage threshold applies.

## Contribution Workflow

Open an upstream Issue before editing; use `.github/ISSUE_TEMPLATE/` for problem, scope, environment, acceptance criteria, and validation plan. Search duplicates first.

External contributors fork `wangdiandao/godot-plugin`; maintainers may use repository branches. Branch from updated `main` as `type/<issue>-<summary>`. Use imperative commits: `docs: clarify acceptance (#1)`.

Submit a templated PR with `Closes #<number>`, results, evidence, and untested scope. Resolve feedback; structure checks and relevant native tests must pass. Maintainers approve before merge; AI cannot approve/merge its own PR. Initial `v0.1.0` import is the sole bootstrap exception.

## Skill Creation & Modification

Follow [CONTRIBUTING.md](CONTRIBUTING.md) and [authoring rules](docs/authoring.md). Preserve required sections, frontmatter, UI metadata, references, and standalone examples. Update cases, routing, capabilities, inventory, and fixed skill-count validation together. Include governance in source packages and MIT licensing in both archives.

## Agent-Specific Instructions

For library/SDK/API/CLI questions, resolve Context7 IDs then query concepts separately. Verify Godot bindings against version-matched official sources. Preserve user edits; clean only verified task-created directories. Context7 is research-only.
