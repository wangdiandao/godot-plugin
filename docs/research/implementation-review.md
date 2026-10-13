# Implementation review for Issue #7

Review date: 2026-10-13. Reviewed the 23 Skill entrypoints, domain recipes, executable fixtures and relevant runner integration as they became available. This is a code and implementation review, independent of the implementation agents. Only this report and ignored isolated probes were created by the reviewer; Skill changes belong to their implementing agents.

## Findings

1. **P2 — Native integer boundary narrows before validation.** `skills/godot-gdextension/assets/examples/minimal/native.cpp` originally declared score, getter, setter and add parameter as C++ `int`. Godot's Variant integer is 64 bits. Starting at score 50, actual `add(2147483648)` returned 0, `add(4294967296)` returned 50, `add(9223372036854775807)` returned 49 and `add(-2147483649)` returned 100. Setting score 4294967296 returned 0. The native clamp executes after narrowing; its comment about hostile-input overflow and int32-max test did not cover the actual scripting boundary. Fix: use int64_t throughout the public property/method/signal contract and compare delta bounds before arithmetic; add actual 64-bit extreme setter/method assertions.
2. **P2 — Managed integer boundary has the same narrowing.** `skills/godot-csharp/assets/examples/minimal/ExampleResource.cs` originally exposed C# `int` Score, Add and signal. Matching Godot .NET execution produced the same five wrong values. Fix: use `long` across this dynamic boundary and clamp the delta before addition, because casting the old expression to long alone is no longer overflow-safe when the delta is itself long. Add upper/lower/extreme boundary calls.
3. **P2 — ORM and StandardMaterial multiplier semantics are conflated.** `skills/godot-rendering/references/native.md` originally stated ORM RGB channel mapping immediately followed by scalar roughness/metallic multiplying their maps. In pinned engine `scene/resources/material.cpp`, lines 1660 and 1698 multiply the StandardMaterial3D separate textures; lines 1714–1715 assign ORM green/blue directly. The recipe needs an explicit distinction so an agent does not attempt an ineffective ORM scalar adjustment.

All three findings were reported to the coordinator immediately and are resolved. Independent corrected runtime verification and source reinspection are recorded below. No unresolved actionable finding remains within the reviewed implementation scope.

## Actual independent probes

Engine: standard and .NET Godot 4.7.2, engine hash ed1daf0bf001b61586d9930840f2f1394092c079. Windows host. Probe execution is headless.

Copied the previously built native moved project into `artifacts/validation/implementation-review/native-wide`, and the previously built managed project including its matching assembly into `artifacts/validation/implementation-review/managed-wide`. Existing source artifacts and compiler outputs were not overwritten. Created a new probe.gd in each disposable copy, then ran:

```text
artifacts/tooling/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path PLUGIN/artifacts/validation/implementation-review/native-wide --script PLUGIN/artifacts/validation/implementation-review/native-wide/probe.gd --log-file PLUGIN/artifacts/validation/implementation-review/native-wide/probe.log
artifacts/extension-implementation/godot-mono/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe --headless --path PLUGIN/artifacts/validation/implementation-review/managed-wide --script PLUGIN/artifacts/validation/implementation-review/managed-wide/probe.gd --log-file PLUGIN/artifacts/validation/implementation-review/managed-wide/probe.log
```

Both processes exited 0. That indicates each diagnostic probe completed, not that the original boundary behavior passed. Logs preserve WIDE_NATIVE/WIDE_MANAGED observations and scripts preserve exact inputs. Historical build evidence was used only to select compatible existing libraries/assemblies; the calls above were executed during this review.

## Substantive review scope

- Foundation: runnable project configuration versus ConfigFile-only claims; persistent signals and owned/unowned node readback; typed signal/await cleanup; strict saves, migration, conflict detection and preserved corruption; external/internal/ALL resource duplicate policy and aliasing; composition root readiness, service replacement and teardown; public bindings versus internal functions; complete game-loop persistence and restart evidence.
- Content: import/reimport and source/metadata preservation; TileSet peering/empty boundaries and coordinate spaces; mesh and transform ownership; CharacterBody velocity units, ray masks and trigger timing; navigation mesh/map synchronization, cross-region endpoints, exclusions and disabled regions; persisted animation evaluation and root-motion extraction versus double application.
- Rendering/UI/audio/performance: selected backend and actual shader pixel evidence; material/resource readback versus light/particle visual scope; HDR output prerequisites and getter distinctions; inherited Theme/overrides plus real keyboard/pointer dispatch; packaged glyph/IME/screen-reader limitations; WAV/bus readback and nonlooping lifecycle versus actual listening; benchmark timing scope, raw paired samples, equivalence and stale-snapshot policy versus universal gain claims.
- Extension: editor MainLoop/addon-driven acceptance, scene ownership and actual undo manager operations, add_do_reference lifetime, dock registration/removal and two disable cycles; managed partial/resource export/generated signal contracts; native property registration/init level/ABI/platform tags/static runtime dependencies and moved-library acceptance; conditional Windows export versus preset-only serialization; multiplayer authoritative sender/ownership/budget bounds, replication and reconnect cleanup; validation fixture categories and unrelated-error/missing-report rejection; runner timeout, result/log/exit checks and isolated project copies.

The recipes provide concrete develop/modify/diagnose decisions rather than class catalogs. Several fixtures deliberately validate CPU/resource state only; their written boundaries were inspected and are useful, not defects to turn into unearned visual/audio claims.

## Limits

This review did not independently rerun the full global suite, exports, six multiplayer repeats or GPU rendering; those remain the implementing/coordinating agents' explicitly recorded runs. It did inspect their source-level assertions and reporting boundaries. Physical HDR, actual audio listening/microphone behavior, rig-specific animation, native/editor UI appearance, screen-reader/IME/device acceptance, foreign platforms and live model-trigger selection cannot be inferred from these headless probes. Pinned engine source is an extracted source artifact, not a complete Git checkout; its embedded HEAD hash was used as identity without trusting git -C ancestor discovery.


## Resolution verification

The native implementation now uses int64_t for score/getter/setter/Add and the managed implementation uses long for score/property/Add/generated signal. Both compare bounds before addition; this avoids narrowing and INT64_MIN/MAX arithmetic overflow. The fixtures include actual wide Add and setter calls, not just checks of a separate helper. The ORM recipe now explicitly separates ORM direct channel consumption from StandardMaterial3D texture/scalar multiplication, consistent with the pinned material source.

Copied the rebuilt native debug project and latest managed build into new reviewer-owned directories native-wide-fixed and managed-wide-fixed. Reused the original diagnostic inputs unchanged. Fixed calls returned positives →100, negatives →0 and wide setter →100 on both binaries. Then ran each complete corrected bundled fixture, including INT64_MIN/MAX, generated signal delivery and independent serialized readback: native 13/13 assertions passed; managed 14/14 passed. Both fixture processes exited 0, emitted structured passed results and had no engine errors in fixture.log. Fixed probe logs also contain no engine errors.

Exact runtime arguments (ENGINE selects the standard native or .NET binary already identified above; CASE selects native-wide-fixed or managed-wide-fixed):

```text
ENGINE --headless --path PLUGIN/artifacts/validation/implementation-review/CASE --script PLUGIN/artifacts/validation/implementation-review/CASE/probe.gd --quit-after 30 --log-file PLUGIN/artifacts/validation/implementation-review/CASE/fixed-probe.log
ENGINE --headless --path PLUGIN/artifacts/validation/implementation-review/CASE --script PLUGIN/artifacts/validation/implementation-review/CASE/example.gd --quit-after 60 --log-file PLUGIN/artifacts/validation/implementation-review/CASE/fixture.log -- --out PLUGIN/artifacts/validation/implementation-review/CASE/output
```

The first native fixed-host diagnostic failed because the copied project had not generated its GDExtension registration cache; it emitted Cannot get class NativeRecipe and was interrupted through its owned execution session. It is preserved in probe.log and does not count as a passing library call. Registration was generated with the standard editor's --headless --editor --path CASE --import command. That import emitted a user:// snapshot-storage error under the restricted reviewer environment, so this report does not claim clean independent import acceptance. After registration, both fixed runtime probes and complete fixtures passed as described. Implementing-agent clean import/build/release/movement evidence remains separately recorded in extension-implementation.md.

The report's whitespace check `git diff --check -- docs/research/implementation-review.md` returned 0. This check is formatting evidence only.

Local absolute workspace paths in the recorded commands are represented by PLUGIN for portability; probe inputs and result observations are unchanged.

## Reopened cold-import finding

A later clean-directory integration run established a further acceptance gap: first import with the active native extension exits with Windows access violation 0xC0000005 (-1073741819), while a previously scanned host can import and execute all 13 runtime assertions. The coordinator and extension implementation agent reproduced the active/inactive and cold/cached distinction. This invalidates any inference from cached import/runtime success to cold install acceptance. The integer-boundary and ORM findings remain resolved; cold native import is under investigation and this report's earlier statement about no unresolved findings is superseded by this section.

The reviewer independently ran fresh active projects under GDB. Targeting the console wrapper only observed its child exit3221225477 and SIGSEGV termination; that wrapper cannot provide the engine child's stack. A direct GUI-engine debugger investigation is in progress. Reviewer fixture directories native-cold-debugger, native-cold-debugger-02 and native-cold-debugger-03 are isolated and logs remain under artifacts/validation/implementation-review.

Pinned engine source explicitly adapts ClassCreationInfo5 to6 (`core/extension/gdextension.cpp`402–442) and handles legacy Resource create_instance2 refcount expectations (`core/object/class_db.cpp`541–574). Therefore a classInfo5 registration is not, by itself, evidence that the 4.5 binding is unsupported. Cold scanning loads an extension after startup through GDExtensionManager::_load_extension_internal; cached scanning loads it at startup. Documentation/default-property inspection can instantiate and destroy extension Resources, but no specific source path is yet established as the crash cause. Do not describe a compatibility-bound bump or cached rerun as a verified fix.

### Native cold-load diagnosis and debugger scope

Subsequent implementation-agent controls narrowed the trigger: modern godot-cpp b8530af with actual 4.7.2 API still crashes; empty exposed Resource still crashes; zero class registration and internal/unexposed registration exit0. Instrumented generated create_instance and base Wrapped construction did not execute before the fault. Normal cold editor --quit-after20 also fails, so this is not solely an --import flag issue. Precreating only the engine's extension registry, without reusing imported resources, causes startup loading and avoids the observed failure; repeated acceptance of the final bootstrap procedure is still required.

The reviewer captured an interactive GDB interruption trace in native-cold-debugger-06/debugger.txt. This was an interrupted busy/faulted debug run, not a clean import or a precise SIGSEGV fault trace. Main thread was waiting in heap allocation; another engine thread was repeatedly freeing memory. No custom library stack frame was shown in those relevant stacks. The official binary has no available debugging symbols, so NoHotPatch export labels cannot identify exact engine C++ functions. Only the debugger's own inferior was killed on exit.

A source-backed explanation is consistent with those controls: `GDExtensionManager::ensure_extensions_loaded` emits extensions_reloaded for newly scanned extensions; `EditorNode::_gdextensions_reloaded` invokes `EditorHelp::generate_doc(true,false)`. That method waits the previous worker, then starts a new documentation worker. A previous `_load_doc_thread` can already have queued the deferred `_gen_extensions_docs` callback; this callback itself does not wait for the current worker and mutates the same DocTools class data that the new worker loads/merges. The relevant fixed source is core/extension/gdextension_manager.cpp366–431, editor/editor_node.cpp625–634, and editor/doc/editor_help.cpp3027–3045,3083–3090,3254–3277. This is an inference about the engine race consistent with controls and heap symptoms, not a symbolized crash proof or a shipped engine patch. Startup registry loading avoids the late-added signal path without removing the Resource's intended public/editor semantics.

## Final cold-start workflow verification

The task-level acceptance gap is resolved by the explicit, version-scoped runtime bootstrap followed by a separate editor import and behavior process. This does not claim that the engine's unseeded cold-load defect was repaired. The shipped native reference names that remaining engine boundary, keeps the underlying cause uncertain, and prohibits silently applying this workaround outside the reviewed task copy/version.

The reviewer started a new `artifacts/validation/implementation-review/native-bootstrap-final` directory from the shipped Skill source and the rebuilt int64 native debug DLL, with an explicit check that no .godot directory existed before the first call. Copied the inactive manifest template to the active filename only in this disposable copy. Ran bootstrap.gd with --allow-recipe-bootstrap: exit0, actual runtime library/class preflight, flushed write and exact registry readback. Then started a new ordinary editor --import process with normal approved user-cache access: exit0 and clean import.log. Finally started the native example in another process: exit0, all13 assertions passed, clean runtime.log and saved independent Resource readback.

Exact argument sequence, where ENGINE is the identified standard4.7.2 console executable and EXAMPLE is the absolute native-bootstrap-final path:

```text
ENGINE --headless --path EXAMPLE --script EXAMPLE/bootstrap.gd --quit-after 30 --log-file EXAMPLE/bootstrap.log -- --allow-recipe-bootstrap
ENGINE --headless --path EXAMPLE --import --log-file EXAMPLE/import.log
ENGINE --headless --path EXAMPLE --script EXAMPLE/example.gd --quit-after 60 --log-file EXAMPLE/runtime.log -- --out EXAMPLE/output
```

An additional bootstrap run supplied an existing valid registry surrounded by extra blank lines. Its prior SHA256 was captured; after bootstrap exit0 the SHA256 was unchanged. This proves duplicate avoidance and byte preservation for the existing fixture registry. `preserve.log` records preserved_existing_entries=true. All four final bootstrap/import/runtime/preservation logs were scanned with `rg -n 'ERROR:|SCRIPT ERROR:|WARNING:' ... --glob '*.log'`: no matches. A first log-scan command mistakenly used an unexpanded Windows *.log path and failed as a shell search; it was corrected without rerunning or relabeling the successful native operations.

Public API use and the configured hidden/nonhidden project-data directory choice were reinspected against pinned source. ensure_extensions_loaded and get_extension_list_config_file are internal and the fixture does not call them as scripting APIs. The helper's written registry is a generated startup discovery file, not fabricated import data, and is never included in packages.

Final review result: the three original implementation findings and the native first-run workflow gap are addressed, with no unresolved actionable finding in the documented plugin workflow. The unseeded Windows4.7.2 editor defect and unverified engine race explanation remain explicitly recorded limitations. This reviewer did not independently rebuild release libraries or rerun moved release variants; those checks remain the implementation agent's separate evidence.
