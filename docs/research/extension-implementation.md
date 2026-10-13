# Extension and delivery implementation evidence

Date: 2026-10-13. Issue #7, branch `feat/7-skill-deepening`. Scope: new godot-editor-tools, godot-csharp, godot-gdextension; existing godot-multiplayer, godot-export, godot-validation. No global manifests, routing/capability registries, README or PR operations are changed by this subtask.

中文概览：六个 Skill 的入口/配方与案例已落实；真实执行通过故障检测、联网、Windows 导出、编辑器生命周期、C# 与原生编译/行为。原生扩展首次扫描导入存在真实崩溃，已提供并重复验证仅用于隔离 4.7.2 配方的启动发现清单 bootstrap；无 bootstrap 的冷导入仍为失败，不能由运行成功替代。界面视觉、远端平台及托管调试器未测。

## Versions, provenance and conditional dependencies

- Documentation gate was completed before implementation: Godot English 4.7 snapshot `9adca4c1c72917bfe1b7be3108abed5ce26696a6`; all-source research ledgers are separate from these runtime results.
- Standard engine: `ROOT/artifacts/tooling/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe`, runtime reports `4.7.2.stable.official.ed1daf0bf`, full hash `ed1daf0bf001b61586d9930840f2f1394092c079`.
- .NET SDK `10.0.300`; official Godot .NET 4.7.2 downloaded only to `artifacts/extension-implementation/godot-mono`. Release API URL `https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.7.2-stable` supplied asset SHA256 `a2a48473a7414c5f19fab690518caebb738c09ef9601f6bd2388676a7f53b3c0`; downloaded zip matched before extraction. No global Godot/.NET/compiler installation performed. First SDK initialization did create its normal development certificate; no trust action was run.
- CMake `4.2.1`; MSYS2 UCRT GNU C++ `15.1.0`; Python binding generator `3.12.11`. Official godot-cpp 4.5 commit `27d9dd23c83871e0619fca5dc2cddfbfd69e926a` downloaded from codeload by immutable revision. Official remote heads did not contain 4.7; the small API deliberately targets compatible 4.5 interfaces rather than inventing a branch. Debug and release builds used single real_t precision and their corresponding template targets.
- Windows templates from `artifacts/tooling/templates`, version.txt `4.7.2.stable`, release x86_64 executable. Template acquisition/digest evidence belongs to prior tooling preparation; this subtask checked the selected version/path and actually used it.
- Context7 resolve succeeded; three separate editor/C#/native queries succeeded. Editor/native responses mixed some master excerpts, which were treated as leads. API/lifecycle/compatibility decisions were checked against pinned docs/source and actual calls. Context7 is not a packaged dependency.

## Implemented behavior and checks

| Skill | Actual current-run result | Evidence and limits |
|---|---|---|
| validation | Passed seven intended distinctions | Parse failure exit1; missing resource and logged error exit0; runtime out-of-bounds plus bounded timeout; silent timeout; absent report; unrelated fault rejected. Parent result passed, own logs under validation/. Negative success means detection. |
| multiplayer | Passed server + two clients + same-server late reconnect | Three distinct accepted peer IDs, nine bounds/ownership/budget rejections, three disconnects; later position99 observed after initial spawn42. Four child logs exit0/error-free. Constant fixture epoch is not production authentication. |
| export | Passed preset readback, import, Windows release export and artifact launch | Executable/PCK exist; launched export writes passed report and editor=false. Eleven assertions; no browser, pixels, signing or device delivery certified. |
| editor-tools | Passed actual normal-editor plugin test | Eleven assertions: readiness, one plugin/dock twice, transactional do/owner/undo/redo, uncached saved scene readback and complete cleanup twice. Headless normal editor log clean, exit0. Dock visual/focus UX untested. |
| csharp | Passed managed compilation and .NET engine execution | Build 0 warnings/errors, fourteen assertions including 64-bit binding and integer-overflow-safe clamp, generated signal values and uncached Resource reload. Intended invalid delegate fixture failed with GD0201 and missing generated signal identifier. SDK alone never counted as execution. |
| gdextension | Passed native debug/release builds and startup-bootstrap import/runtime; unseeded cold import fails | Thirteen behavior assertions. Final debug/release and moved clean copies require the documented version-specific bootstrap. Preserve first-scan crash separately; other OS/architecture/precision untested. |

Standard-engine C# and unbuilt native preflights emit status blocked with an unavailable check and engine exit2. This is correct dependency detection, not a C#/native behavior pass. No compiled DLLs/executables or bin/obj/.godot build trees were created inside the three new packaged Skill directories; all build projects and tools live under ignored artifacts.

## Commands actually executed

Working directory for these commands was the repository root. `ROOT` is a portable replacement for its resolved absolute workspace path in the actual commands. `STD` below denotes the standard executable above; `MONO` denotes `ROOT/artifacts/extension-implementation/godot-mono/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe`. Resolve these labels before reproduction; they are explanatory labels for already executed paths, not engine-generated values.

```text
STD --headless --path ROOT/skills/godot-validation/assets/examples/minimal --script ROOT/skills/godot-validation/assets/examples/minimal/example.gd --log-file ROOT/artifacts/extension-implementation/validation/engine.log -- --out ROOT/artifacts/extension-implementation/validation
STD --headless --path ROOT/skills/godot-multiplayer/assets/examples/minimal --script ROOT/skills/godot-multiplayer/assets/examples/minimal/example.gd --log-file ROOT/artifacts/extension-implementation/multiplayer/engine.log -- --out ROOT/artifacts/extension-implementation/multiplayer
STD --headless --path ROOT/skills/godot-export/assets/examples/minimal --script ROOT/skills/godot-export/assets/examples/minimal/example.gd --log-file ROOT/artifacts/extension-implementation/export/engine.log -- --out ROOT/artifacts/extension-implementation/export --templates ROOT/artifacts/tooling/templates
STD --headless --editor --path ROOT/artifacts/extension-implementation/editor-project --log-file ROOT/artifacts/extension-implementation/editor-out/final.log -- --self-test --out ROOT/artifacts/extension-implementation/editor-out
dotnet build artifacts/extension-implementation/csharp-project/Recipe.csproj --nologo
dotnet build artifacts/extension-implementation/csharp-project/Recipe.csproj --no-restore --nologo
MONO --headless --path ROOT/artifacts/extension-implementation/csharp-project --script ROOT/artifacts/extension-implementation/csharp-project/example.gd --log-file ROOT/artifacts/extension-implementation/csharp-out/retest.log -- --out ROOT/artifacts/extension-implementation/csharp-out
dotnet build artifacts/extension-implementation/csharp-bad/Recipe.csproj --nologo
```

For dotnet, DOTNET_CLI_HOME and NUGET_PACKAGES were set to task-local `artifacts/extension-implementation/dotnet-home` and `.../nuget`. The bad fixture copied only source example files and renamed ScoreChangedEventHandler to Broken. Build exit1 and exact GD0201 were checked; its NuGet vulnerability-data lookup also warned NU1900, which was recorded rather than treated as the intended compiler fault. The final healthy build used restored packages and returned 0 warnings/errors.

Native configuration/build commands:

```text
cmake -S artifacts/extension-implementation/native-project -B artifacts/extension-implementation/native-build -G "MinGW Makefiles" -DGODOT_CPP_DIR=ROOT/artifacts/extension-implementation/godot-cpp/godot-cpp-27d9dd23c83871e0619fca5dc2cddfbfd69e926a -DGODOTCPP_BUILD_PROFILE=ROOT/artifacts/extension-implementation/native-project/build-profile.json -DGODOTCPP_TARGET=template_debug -DGODOTCPP_PRECISION=single -DCMAKE_BUILD_TYPE=Debug
cmake --build artifacts/extension-implementation/native-build --parallel 4
cmake -S artifacts/extension-implementation/native-project -B artifacts/extension-implementation/native-release-build -G "MinGW Makefiles" -DGODOT_CPP_DIR=ROOT/artifacts/extension-implementation/godot-cpp/godot-cpp-27d9dd23c83871e0619fca5dc2cddfbfd69e926a -DGODOTCPP_BUILD_PROFILE=ROOT/artifacts/extension-implementation/native-project/build-profile.json -DGODOTCPP_TARGET=template_release -DGODOTCPP_PRECISION=single -DCMAKE_BUILD_TYPE=Release
cmake --build artifacts/extension-implementation/native-release-build --parallel 4
STD --headless --path ROOT/artifacts/extension-implementation/native-moved --import --log-file ROOT/artifacts/extension-implementation/native-release-out/import.log
STD --headless --path ROOT/artifacts/extension-implementation/native-moved --script ROOT/artifacts/extension-implementation/native-moved/example.gd --log-file ROOT/artifacts/extension-implementation/native-release-out/engine.log -- --out ROOT/artifacts/extension-implementation/native-release-out
```

Build PATH prepended the matching `D:/msys64/ucrt64/bin`. The first trimmed profile omitted OS and failed in print_string.cpp; adding OS fixed the actual dependency. The first DLL linked libwinpthread dynamically and produced Windows loader error126 even though the DLL existed. `D:/msys64/ucrt64/bin/objdump.exe -p .../native_recipe.dll` identified it. Static MinGW runtime options removed that dependency; subsequent loader/behavior checks passed. Debug run log is native-out/retest.log; release moved run logs are native-release-out/import.log and engine.log. These failures were real diagnosis inputs, not declared passes.

Editor tests initially used `--editor --script` with a custom SceneTree. Transactions and readback worked but disabled docks stayed queued and shutdown leaked editor resources. Source inspection and `DOCK_DIAGNOSTIC:false:true:0` established removal occurred while frees were not flushed. A plugin-driven Node on the normal editor MainLoop fixed cleanup and shutdown; final log contains no ERROR/SCRIPT ERROR records. Sandbox user:// access blocked one editor/import attempt; applicable runs were repeated with allowed normal user-data access, rather than ignoring those errors.

All six skills passed `python -X utf8 C:/Users/Lenovo/.codex/skills/.system/skill-creator/scripts/quick_validate.py skills/SKILL_NAME`. Python launcher warned about its installed real-location lookup but each validator returned “Skill is valid!” and exit0. `git diff --check` returned no whitespace findings (CRLF conversion notices are not failures). Repository-wide structure/link/package/routing checks remain root-agent integration work and are not claimed here.

## Recommended case and routing registration

- validation-example: ordinary headless script, 30-second outer timeout, passed report; expected-fault child logs are intentional and must not be confused with errors in the parent. Verify the parent checks and selected diagnostic artifacts.
- multiplayer-example: ordinary headless script, loopback permission, 30-second timeout; four child logs and server counts. Transport access rejection means blocked, not a scene-only substitute.
- export-example: ordinary headless script configuration only. Add a conditional Windows-template case with `--templates ABSOLUTE_PATH`, 90-second outer timeout to cover three bounded subprocesses. Actual runtime result is separate from default preset evidence.
- editor-tools-example: copy the project first, omit `--script`, add engine_args `["--editor"]` and user args `["--self-test", "--out", "{output}"]`, timeout30. It writes saved_recipe.tscn and editor state only in the copy. Headless test proves API/lifecycle/persistence, not visual UX.
- csharp-example: default standard engine expects blocked/2. Conditional compiled case runs dotnet build in copy and then MONO; positive execution cannot use STD. Record build and runtime separately.
- gdextension-example: unbuilt packaged source expects blocked/2. Conditional native case builds, activates the extension template, explicitly bootstraps the isolated 4.7.2 recipe, imports and runs; record target/precision/dependencies and moved-project behavior separately.

Develop/modify/diagnose prompt suggestions: editor dock with marker transaction / make an existing property edit undoable / diagnose disappearing saved nodes; managed Resource with signals / change movement struct safely / diagnose GD0201 or stale assemblies; native Resource binding / migrate registered property / diagnose existing-DLL error126; authoritative lobby / add reconnect epoch / diagnose spawn-path race; target export preset / add runtime-data inclusion / diagnose exit0 missing resource; behavior fixture / add saved readback / distinguish timeout from expected fault. These are proposed semantic cases, not actual installed-host routing results.

## Untested scope and self-review

Independent-review correction: the initial native/C# recipes used 32-bit method/property boundaries. Godot converts its 64-bit Variant integer before the setter/method's clamp, so values such as 4294967296 wrapped before validation. The corrected score/getter/setter/add/signal boundaries use int64_t or C# long, and Add compares with the remaining upper/lower capacity **before** addition to handle INT64_MIN/MAX without overflow. Tests now include Add from score50 for 2147483648, 4294967296, INT64_MAX, -2147483649 and INT64_MIN, plus four wide setters. Native has thirteen assertions and managed fourteen. Debug and release native builds were rerun; the release library was imported/run in a fresh `artifacts/extension-implementation/native-wide-moved` project. Managed build again returned zero warnings/errors, actual .NET runtime passed and the updated invalid-delegate fixture still failed with exact GD0201.

Current corrected logs are `native-out/wide-debug.log`, `native-wide-moved-out/import.log` and `engine.log`, `csharp-out/wide.log`, and `csharp-bad/wide-build.log`, all under `artifacts/extension-implementation`. Existing commands above were rerun with these log/project substitutions; source-only edits did not change CMake target/precision parameters. Output-path normalization was also added before serialization. Fresh runs with literal Windows backslash OUT arguments passed all fourteen/thirteen assertions in `wide-csharp-backslash/engine.log` and `wide-native-backslash/engine.log`. Historical initial five/four-assertion results do not establish wide-boundary correctness; only the corrected runs do.

Unmeasured: actual Codex explicit/implicit routing; dock visual layout/focus/drag/accessibility; managed debugger attach/GC profiling; C# Android/iOS/Web (Web unsupported); native foreign platforms/architectures/double precision/hot reload; game-specific export saves/permissions/signing/browser/device behavior; public Internet, authentication and packet-loss performance. No untested condition is counted as passed.

Self-review fixed the initial validation mismatch, C# int overflow risk, native profile/runtime dependencies, actual editor MainLoop cleanup and pre-opened-scene ambiguity. No assertions were removed to gain a pass. Additional global integration findings must be handled by the coordinating agent before final delivery.


## Final cold-import investigation and verified bootstrap

The independent evaluator's original cold import exit3221225477 (`0xC0000005`) is a real failure, despite no textual ERROR and later thirteen-assertion runtime success. Earlier clean-import statements above did not distinguish preexisting discovery state; the following final pipeline supersedes those claims. No engine fix is claimed.

Controlled fresh copies showed: active exposed blank Resource crashes; no registered class succeeds; unexposed Resource succeeds; normal editor `--quit-after 20` also crashes; direct GUI executable behaves the same as the console wrapper; static and dynamic pthread builds both crash. Temporary diagnostic constructors and `_create_instance_func` markers were never reached in exposed-class crashes. All instrumented bindings/projects stayed under ignored artifacts, not the shipped source.

Official current godot-cpp commit `b8530af7546a3fcae80cef2477526569fd42ffc2` was built with GODOTCPP_API_VERSION=4.7 and GODOTCPP_CUSTOM_API_FILE pointing to a real API dump from fixed 4.7.2. It reproduced cold import failure and passed runtime. Two fresh startup-preloaded modern copies imported successfully; `native-preload-b` also passed thirteen runtime checks. Older API bindings are therefore not an established cause. Final shipped recipe retains the earlier pinned 4.5 public interfaces and statically linked GCC/C++/pthread runtime. The diagnostic dynamic-pthread experiment was reverted.

Fixed-source explanation of the successful workaround: `GDExtensionManager::load_extensions` reads the line-based discovery file at startup; `ensure_extensions_loaded` discovers new extensions during editor scanning and emits extensions_reloaded. Independent review found a plausible race: EditorNode::_gdextensions_reloaded calls EditorHelp::generate_doc, starts a new worker after waiting the old one, while an old worker may already have deferred `_gen_extensions_docs`; that callback mutates doc->class_list without waiting the new worker. This is a source-based hypothesis, not a proven named crash instruction. GDB transcripts from the reviewer show engine/CRT heap activity without native frames; absent matching official symbols, the exact fault remains unconfirmed. See the independent implementation-review report.

The shipped `bootstrap.gd` is guarded by explicit --allow-recipe-bootstrap, exact 4.7.2 and the isolated recipe project name. It verifies the real library through public load_extension and confirms NativeRecipe registration before modifying the discovery file. It preserves existing entries, supports the configured hidden/nonhidden data directory, removes no cache, and creates no imported-asset metadata. Internal ensure_extensions_loaded/get_extension_list_config_file are NOT presented as scripting APIs. Bootstrap success alone never counts as import/runtime acceptance.

Final CMake Debug/template_debug and Release/template_release were rebuilt from shipped source with the original pinned bindings and single precision. `native-final-debug`, `native-final-release`, `native-final-moved-clean` and `native-final-bootstrap-verified` had no preexisting .godot before their pipelines. Each completed bootstrap0/import0/runtime0 with thirteen assertions. Final helper adds library preflight; the latter directory exercised that exact helper. Missing opt-in returned1, repeat bootstrap retained the discovery file's SHA256, and moved release objdump listed only Windows/UCRT system dependencies (no libwinpthread DLL). Raw unseeded imports remain failed evidence.

Actual final commands (ROOT/STD and compiler labels resolve as above):

```text
cmake -S ROOT/artifacts/extension-implementation/native-project -B ROOT/artifacts/extension-implementation/native-build
cmake --build ROOT/artifacts/extension-implementation/native-build -j 8
cmake -S ROOT/artifacts/extension-implementation/native-project -B ROOT/artifacts/extension-implementation/native-release-build
cmake --build ROOT/artifacts/extension-implementation/native-release-build -j 8
STD --headless --path ROOT/artifacts/extension-implementation/native-final-bootstrap-verified --script ROOT/artifacts/extension-implementation/native-final-bootstrap-verified/bootstrap.gd --log-file ROOT/artifacts/extension-implementation/native-final-bootstrap-verified/bootstrap.log -- --allow-recipe-bootstrap
STD --headless --path ROOT/artifacts/extension-implementation/native-final-bootstrap-verified --import --log-file ROOT/artifacts/extension-implementation/native-final-bootstrap-verified/import.log
STD --headless --path ROOT/artifacts/extension-implementation/native-final-bootstrap-verified --script ROOT/artifacts/extension-implementation/native-final-bootstrap-verified/example.gd --log-file ROOT/artifacts/extension-implementation/native-final-bootstrap-verified/runtime.log -- --out ROOT/artifacts/extension-implementation/native-final-bootstrap-verified/out
```

Copies contained only shipped source, activated manifest and the appropriate compiled relative bin/native_recipe.dll. Raw failure controls: native-import-audit-out/debug-import.log, native-dynamic-audit-out/import.log, native-modern-out/import.log; marker/control transcripts: native-base-markers-project/console.txt, native-no-class-project/console.txt, native-unexposed-project/console.txt. Final pipeline logs and result.json live inside the named final directories. Foreign engine versions/platforms and an actual engine race fix are untested. Normal GDScript cases gain no native bootstrap or compiler dependency.
Final helper review added flush/error handling and exact discovery-file readback after close. The final shipped helper was executed in a fresh debug copy `native-final-helper-readback`: bootstrap0/import0/runtime0 and thirteen assertions. Its commands match the preceding final-bootstrap-verified sequence with that project name substituted; logs are bootstrap.log/import.log/runtime.log and out/result.json. No compiled code changed after the final debug/release builds.
