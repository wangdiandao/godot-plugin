# Independent forward task evaluation

Evaluated on 2026-10-13 in a delegated Codex task on Windows x86_64, against Godot 4.7.2-stable official (`ed1daf0bf`). The exact Codex model identifier/build is not exposed. The evaluator read all 23 skill descriptions before choosing routes and did not read `tests/routing/prompts.json` or its expected fields.

This is actual Codex subagent semantic routing and native task execution. It does **not** establish installed Desktop UI autoload, implicit host discovery, or other clients' routing. The evaluator authored 69 natural requests (develop/modify/diagnose per skill), selected skills semantically, then ran one representative natural request and one explicit `$skill` request per skill in separate fresh copies. The 46 modify/diagnose requests were selected but not independently implemented; some representative fixtures exercise their named modifications and failure branches. Self-authored requests can favor known descriptions, so no accuracy percentage is claimed.

Final explicit and natural representative suites each contain **21 passed tasks and 2 correct dependency blocks**. The standard C# and unbuilt native examples return blocked/2; this is prerequisite detection, not compilation success. A fresh independent managed `dotnet build --no-restore` and Mono execution additionally passed 14 checks. A moved compiled native library passed 13 runtime checks, but its initial `--import` exited `3221225477` (Windows access violation); the original unseeded phase remains a recorded failure. The final isolated bootstrap/import/runtime pipeline was subsequently verified separately by the coordinator and independent implementation reviewer; see the update below. Native compilation evidence belongs to the extension implementation pass, not this evaluator.

## Actual observed task scope

| Skill | Explicit / natural | Checks | Evidence and limits |
|---|---|---:|---|
| godot-2d | passed / passed | 10 | Terrain connection/boundary bits, persistence and transformed cell coordinates; no rendered seam acceptance. |
| godot-3d | passed / passed | 7 | Independent box resize, camera/light/resource readback; no complex model or skeleton creation. |
| godot-animation | passed / passed | 9 | Actual track evaluation and reloaded keys/duration; skeletal retargeting and blend UX untested. |
| godot-api | passed / passed | 8 | Public binding checks plus actual pack/save ownership behavior; not every engine API. |
| godot-architecture | passed / passed | 16 | Injection before ready, idempotent wiring, replacement and teardown, stored behavior. |
| godot-assets | passed / passed | 3 | Minimal PNG roundtrip plus independent 17-check import/reimport/missing-source/glTF recovery supplement. |
| godot-audio | passed / passed | 12 | Saved PCM/bus/send/limiter, mute/unmute, missing bus and completion; no listening evidence. |
| godot-csharp | blocked / blocked | 1 | Standard dependency block; independent .NET build and 14 Mono runtime checks including int64 bounds. |
| godot-data | passed / passed | 29 | Migration/schema rejection, guarded writes/conflict, backup/readback and corruption/future preservation. |
| godot-editor-tools | passed / passed | 11 | Actual editor activation twice, cleanup, undo/redo, owner/save readback; dock UX untested. |
| godot-export | passed / passed | 11 | Actual Windows import/export/executable startup with matching local templates; no store/signing/browser test. |
| godot-gdextension | blocked / blocked | 1 | Unbuilt dependency block; compiled moved native runtime 13 checks; import crash separately failed. |
| godot-gdscript | passed / passed | 5 | Typed signal, await, reconnect/disconnect lifecycle; no standalone complex refactor. |
| godot-multiplayer | passed / passed | 4 | Server/two clients/reconnect; spawn/replication/RPC plus authority/bounds/budget guards; loopback only. |
| godot-navigation | passed / passed | 7 | CPU bake, save/readback, two-region path and excluded/disabled destinations; no avoidance movement. |
| godot-performance | passed / passed | 39 | 512 actor CPU query benchmark, warmup and 31 pairs with equivalence/invalid guards; speedup not required. |
| godot-physics | passed / passed | 7 | Landing/contact, movement distance, ray hit/wrong mask and trigger enter/exit; native 2D only. |
| godot-project | passed / passed | 7 | Persistent input/Autoload config then actual generated project bootstrap; no whole-project version migration. |
| godot-rendering | passed / passed | 7 | Real GPU shader saved parameters, independent uniform change and changed pixels; HDR untested. |
| godot-scenes | passed / passed | 6 | Owned/unowned node distinction and reloaded persistent signal execution; arbitrary inheritance edits untested. |
| godot-ui | passed / passed | 15 | Saved Theme inheritance/local override, real event dispatch, overlay block/repair and translation lookup. |
| godot-validation | passed / passed | 14 | Bounded faults and exact-cause matching: parse/runtime/missing/error-exit0/timeout/unrelated/missing-report. |
| godot-workflow | passed / passed | 9 | Game-2D actual start/movement/win/save/restart self-test; complete new user game creation untested. |

## Findings and recovery

The initial restricted attempt failed editor user-directory access, export/import subprocesses, loopback networking and display-related checks. Those logs remain preserved; unrestricted retries were new actual runs rather than relabeled results. The unrestricted UI attempt exposed a real Windows path defect: backslashes in output paths were serialized into external Theme references and interpreted as escape sequences on reload. The parent normalized output paths; this evaluator copied the corrected fixture and passed all 15 checks through both explicit and natural tasks with backslash `--out` arguments.

The native import access violation is not ignored because its log contains no `ERROR:` text. Process exit is part of the acceptance contract. Subsequent clean runtime checks prove class loading, int64 method/property clamps, signal delivery and uncached persisted state; they cannot prove a clean import/shutdown phase.

## Commands and evidence

Exact argument arrays, source hashes, exits, durations, check reports and absolute logs are stored in [actual-results.json](../../tests/routing/actual-results.json). Runtime directories are ignored artifacts, not source/package content.

- Explicit: `python -X utf8 artifacts/validation/task-evaluation/run.py` → `run-20261013-162255/execution-results.json`.
- Natural: `python -X utf8 artifacts/validation/task-evaluation/run.py --natural` → `run-20261013-162014/execution-results.json`.
- Supplemental: `python -X utf8 artifacts/validation/task-evaluation/run-more.py` → `supplement-20261013-162114/results.json`.
- All task projects/output files reside under `artifacts/validation/task-evaluation/`; original implementation files were not edited by the evaluator. Python is authoring evidence orchestration, not a published Godot runtime dependency.

Real listening, microphone/device latency, physical HDR, accessibility/CJK glyph coverage, gamepad hardware, foreign-platform exports and installed host autoload remain untested. The benchmark measures CPU query distributions and correctness; it does not require or claim universal speedup.

Recorded local workspace prefixes are represented by PLUGIN in published command/log references; original logs remain ignored. This changes presentation only, not the recorded results.

## Subsequent native pipeline resolution

The coordinator and independent implementation reviewer each copied the rebuilt release/debug fixture into a zero-cache directory, ran the final public-load-validated discovery bootstrap, ran a separate editor import with normal cache access, and then ran all13 runtime assertions. All phases exited0 with clean logs. Repeat bootstrap preserved existing registry bytes. The original unseeded crash remains in historical_attempts; the operating recipe now uses this verified4.7.2-specific startup sequence. Original evaluator tasks above are not relabeled or replaced. Details: [implementation review](implementation-review.md) and [extension evidence](extension-implementation.md).
