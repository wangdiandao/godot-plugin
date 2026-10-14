# Authoring and extension specification

**English** | [简体中文](authoring.zh.md)

[Documentation](README.md) · [Development](development.md) · [Testing](testing.md)

## Layer responsibilities

`SKILL.md` is the task entry point and retains the decisions and acceptance conditions needed to finish the work. `references/` holds actual APIs, platform differences and long examples. `assets/examples/` contains complete projects that run independently after copying. Add dedicated `scripts/` only for repeated domain-specific operations; do not create empty directories.

Shared execution, saving, recovery and evidence contracts live in `shared/references/`. Load relevant files on demand for first execution, persistence, failures or evidence updates. Default shared tools use native Godot capabilities. C# and GDExtension enable only the toolchains their tasks require. Do not create wrapper services for operations already supported by `--import` / `--export-release`.

## Ten contracts for each Skill

| Requirement | Location and check |
|---|---|
| Name and trigger description | Frontmatter; matches the directory and defines adjacent-domain boundaries |
| Use cases and boundaries | Entry purpose; broad descriptions must not capture all Godot requests |
| Prerequisites | Engine, mode, resources and platform conditions; explain the automatic check path |
| Execution workflow | Ordered steps and key branches; each domain can finish independently |
| CLI/API | native.md and runnable examples; verify version, signature and context |
| File saving | Minimal diff, references, owner, UID, caches and readback |
| Error recovery | Explicit cause; at most two evidence-based repairs for the same failure |
| Verification | Observable assertions, logs, exit codes and outputs; include failure criteria |
| Official sources | Fixed-version links near conclusions; check source bindings for disputed APIs |
| Examples and pitfalls | Runs in a clean directory; complete commands, outputs, side effects and cleanup scope |

Organize the entry as purpose → prerequisite checks → workflow → saving/recovery → acceptance → on-demand material. UI display_name, short_description and default_prompt match the actual trigger boundary; allow_implicit_invocation=true by default. The default prompt must contain that `$skill-name`.

## Adding capabilities

1. Select an existing Skill for the user's intent first. Add one only for an independent responsibility with a clear trigger boundary.
2. When available in the research session, resolve Godot Engine through Context7 and query each concept separately; still verify matching-version official sources. Do not make the research MCP a runtime dependency.
3. Verify interfaces through ClassDB and minimal calls. Check the actual execution mode for editor-only features; do not describe internal C++ methods as script APIs.
4. Add a complete minimal project. Each case accepts an explicit output directory, exits explicitly and emits results; test outputs do not modify source-project business files.
5. Update `tests/cases.json`, associating Skill, inputs, conditions and expectations. New negative cases specify expected failure text. Normal cases reuse bundled examples; faults live in separate fixtures.
6. Update positive, non-goal and adjacent requests in `tests/routing/prompts.json`. Record human review separately from actual host model selection.
7. Run necessary native checks. Update capabilities' tested scope only after passing results. New platforms require actual execution; cross-platform APIs do not imply a pass.
8. Synchronize the root manifest, Codex/Claude Code/Cursor compatibility manifests, Gemini extension manifest and marketplace entry; raise the version. Synchronize English README.md and Simplified Chinese README.zh.md. Generate packages, read back ZIPs, check shared references and run after relocation before delivery.

## Test commands

Run these commands from the source root. Replace GODOT/PLUGIN/OUT/TEMPLATES with absolute paths first. OUT must be a new writable directory; create the parent of `--log-file` beforehand.

```text
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/shared/scripts/run_checks.gd --log-file OUT/suite.log -- --manifest PLUGIN/tests/cases.json --out OUT/cases
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/integration/desktop.gd --log-file OUT/desktop.log -- --plugin PLUGIN --templates TEMPLATES --out OUT/desktop
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/integration/assets.gd --log-file OUT/assets.log -- --plugin PLUGIN --out OUT/assets
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/integration/failures.gd --log-file OUT/failures.log -- --plugin PLUGIN --out OUT/failures
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/package.gd --log-file OUT/package.log -- --root PLUGIN --out PLUGIN/dist
```

The desktop integration test requires Windows, a real GPU and matching Windows/Web templates; it is not an automated cross-platform test. For repeated multiplayer checks, point run_checks' manifest at `tests/integration/multiplayer-repeat.json` to run six rounds of the same assertions. Native rendering/capture/game cases open brief windows and exit automatically; multiplayer uses only local loopback.

The author structure check `python -X utf8 tests/validate_structure.py --root PLUGIN --schema artifacts/research/plugin.schema.json` uses Python, PyYAML and jsonschema; replace PLUGIN with an absolute path. It is maintenance-only, excluded from installation packages and not a game-development runtime requirement. skill-creator's quick_validate.py can also check individual Skills; use Python UTF-8 mode for Chinese on Windows. Structure checks do not replace behavior tests.

When adding host packaging, structure checks compare name/version/description across all manifests, reciprocal language links and every link in the actual Skill inventory. Claude Code can validate its manifest with `claude plugin validate --strict PLUGIN/.claude-plugin/plugin.json`. The packager checks all manifests and READMEs, excluded directories and per-file hashes. Extract both ZIPs into new isolated directories, then run source structure checks and bundled native examples. Host discovery/model selection and GDScript execution are separate evidence; manifest validation alone does not certify a complete Agent workflow. See [compatibility.md](compatibility.md).

## Saving, cleanup and evidence updates

Record content and hashes before modifying existing files. Recovery overwrites only versions still belonging to this operation. Preserve both sides of concurrent user changes; do not evade issues by clearing the entire `.godot` directory. Retain failed outputs for diagnosis and use new output directories for repeated runs.

Clean only isolated directories created by this task. Normalize paths first and confirm the absolute target is within the intended parent. Do not delete user resources, production saves or unknown PIDs. Releases exclude temporary engines, templates, original research sources and test caches.

Maintain sources, conditions, examples, test IDs and precise tested/untested scope in `docs/capabilities.json`. Put summary results in `docs/validation-results.json` and raw logs in `artifacts/`. A passing negative case means that the expected failure was correctly identified, not that the failed operation succeeded.
