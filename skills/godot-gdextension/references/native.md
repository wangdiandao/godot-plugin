# Native extension recipes

## Compatibility and toolchain

Record engine version/hash, godot-cpp commit/API version, architecture, precision, compiler/runtime and build target. Earlier minor extension APIs generally work in later engines; later APIs cannot run on earlier engines. 4.0 to 4.1 is an exception. Precision must match and custom builds need their own engine-generated API JSON. Do not substitute a mutable master binding when a target branch is absent without reviewing which API it targets.

The tested resource recipe uses official godot-cpp 4.5 commit `27d9dd23c83871e0619fca5dc2cddfbfd69e926a` with Godot 4.7.2: every API it needs exists in 4.5. At implementation time the official repository did not expose a 4.7 branch; cloning that invented branch would fail. For new 4.7-only APIs, select a verified compatible binding revision and dump/verify the target engine API rather than promising this small profile covers them.

Prefer SCons when its features are required. CMake is an officially supported secondary route and works for this recipe. Need C++ compiler, CMake generator/build program and Python3 for generated bindings. CMake Debug controls symbols; GODOTCPP_TARGET=template_debug controls Godot debug features. Both belong in recorded parameters. Native tools are conditional; ordinary GDScript recipes need neither.

## Build and load a native Resource

Copy the example to EXAMPLE. Fetch official bindings into CPP outside the packaged Skill and pin the commit. `native.cpp` supplies a Resource class, getters/setter/add method, clamped state and score_changed signal. Entry symbol uses extern C and exported calling convention; registration runs at scene initialization. No internal engine calls or borrowed RID frees are used.

For the tested Windows MinGW route, use the UCRT compiler's matching bin directory and build tool, not an MSVC generator combined with g++. Resolve all paths absolutely:

```text
cmake -S EXAMPLE -B BUILD -G "MinGW Makefiles" -DGODOT_CPP_DIR=CPP -DGODOTCPP_BUILD_PROFILE=EXAMPLE/build-profile.json -DGODOTCPP_TARGET=template_debug -DGODOTCPP_PRECISION=single -DCMAKE_BUILD_TYPE=Debug
cmake --build BUILD --parallel 4
```

The profile includes Resource plus OS because godot-cpp print_string.cpp uses OS even though user code does not. Profiles can remove apparently unused dependencies needed by binding support code; diagnose the concrete missing header before broadening. Copy `recipe.gdextension.in` to `recipe.gdextension` only after the library exists. Keeping the source template inactive lets an unbuilt project report unavailable without startup loader faults.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/bootstrap.gd --log-file OUT/bootstrap.log -- --allow-recipe-bootstrap
GODOT --headless --path EXAMPLE --import --log-file OUT/import.log
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/run.log -- --out OUT
```

Require import logs free of loader errors and runtime method, signal/bounds and uncached save/readback assertions. This example's library path is relative and survives copying EXAMPLE with its bin folder. Without registration, the script returns blocked/2. Copying only .gdextension cannot make the extension available. Build release separately in a fresh build directory with template_release/Release; do not relabel debug DLL as a validated release.

### Tested 4.7.2 cold-import boundary

On the tested Windows 4.7.2 editor, discovering an exposed extension class during the first filesystem scan crashes with `0xC0000005`; a later cached startup succeeds. This is an actual failed import, even when its log contains no textual error. Empty registered Resource classes reproduce it; a library registering no class and an unexposed class do not. Official godot-cpp 4.5 bindings and pinned current bindings targeting the exact 4.7.2 API both reproduce it, so changing binding versions is not an established fix. The exact failing engine instruction remains unverified.

For this task-created recipe copy, run `bootstrap.gd` before the **first** editor import. It explicitly requires the recipe project name, Godot 4.7.2 and the opt-in argument. It validates the compiled library through public `GDExtensionManager.load_extension()` and class registration before writing anything. It adds `res://recipe.gdextension` to the generated discovery list while preserving every existing entry; it neither fabricates imported assets nor removes caches. The fixed engine's `GDExtensionManager::load_extensions()` reads this line-based file at startup, so registration precedes editor discovery. Require a new import process with exit zero and all thirteen runtime assertions afterward. Bootstrap alone is not an import or behavior pass.

Do not distribute `.godot`, silently patch other projects, or copy this workaround to another version without revalidation. For an existing project, first preserve its discovery list and determine the configured project data directory; adapt only known manifest paths with an explicit reviewed operation. Keep the unseeded crash in evidence and retest it when upgrading the engine. The normal GDScript execution path has no bootstrap dependency.

## Runtime dependencies and packaging

The MinGW recipe statically links its GCC/C++/pthread runtime to avoid requiring an unlisted libwinpthread-1.dll on the target. Initial loading actually failed with Windows error126 until that dependency was identified via objdump and removed by static linking. An alternative dynamic build must bundle its permitted dependency with a matching `.gdextension` dependencies entry and validate clean-machine loading. Do not copy system DLLs indiscriminately. Review static/dynamic dependency licenses before distribution.

The example template maps debug and release feature tags to the same recipe filename for convenience; install only the build being tested. Production packages should separate target outputs so debug/release cannot overwrite each other. More specific feature-key matches must precede generic ones, all tags must match and compatibility_minimum is a bound rather than a substitute for ABI testing. macOS dependencies need their specified Frameworks placement/codesigning; foreign architectures need their own builds and device checks.

## Modify a binding or native worker

Add script-callable methods through ClassDB bindings, register property getter/setter names and Variant-compatible signals before use. Treat custom class names/method signatures as serialized interfaces: changing them can break saved resources and scenes. For a type change, migrate copies of existing data, preserve old field reads and assert a fresh reload. Keep required constructors/defaults compatible with Resource instantiation.

Use RefCounted/Resource lifetime for referenced data and Node for scene lifetime. Do not expose raw native pointers as supposedly safe script objects. Avoid holding Object pointers after disposal; use appropriate IDs/weak references and explicit ownership. Native workers may process immutable/copy data off-thread but scene mutation belongs to its permitted thread; defer transfer, cancel work and join on shutdown. A DLL can stay locked while an editor loads it; close only task-owned processes before replacement. Reloadable extensions have additional registration/unregistration requirements; this recipe sets reloadable=false deliberately.

## Diagnose and retest

| Symptom | Check | Cause | Fix | Retest |
|---|---|---|---|---|
| Compiler missing generated header | Build profile/API generation/Python | Support-code dependency trimmed | Add required profile class or use full profile | Reconfigure/build and actual load |
| Error126 although DLL exists | Binary dependencies and architecture | Missing dependent DLL or wrong architecture | Package permitted dependency or rebuild runtime choice | Fresh process without development PATH |
| Entry symbol missing | Export table, unmangled name | No extern C/export macro or wrong config | Correct exact entry symbol | Import log and ClassDB class presence |
| Class loads but method unavailable | Binding names/init level | Missing registration or mismatched name | Bind at scene initialization | Call actual public method/signal |
| Saved property lost | Storage usage, registered getter/setter | Unregistered/transient field | Register storage interface and migration | Saver result + uncached reload |
| Works only on developer machine | Precision/runtime/tag selection | ABI/dependency or hardcoded path | Match target and relative paths | Moved clean fixture with runtime assertions |
| First import exits 0xC0000005 with no textual error | Cold versus startup-preloaded extension; exposed versus unexposed class | Verified 4.7.2 late discovery boundary; exact engine cause unconfirmed | In the isolated recipe only, run the explicit discovery bootstrap | Two fresh copies: bootstrap + zero-exit import + thirteen runtime assertions; preserve failing control |

Sources: [C++ example](https://docs.godotengine.org/en/4.7/tutorials/scripting/cpp/gdextension_cpp_example.html), [CMake](https://docs.godotengine.org/en/4.7/tutorials/scripting/cpp/build_system/cmake.html), [compatibility](https://docs.godotengine.org/en/4.7/tutorials/scripting/cpp/about_godot_cpp.html), [.gdextension file](https://docs.godotengine.org/en/4.7/engine_details/engine_api/gdextension/gdextension_file.html). Custom backend and engine-source references are analysis boundaries, not promised executable support.


Engine binding/lifecycle reference: [fixed 4.7.2 source](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/extension/gdextension.cpp). Compare generated bindings and actual execution with this revision; internal implementation alone is not a callable scripting API.
