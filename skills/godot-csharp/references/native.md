# Managed implementation recipes

## Toolchain and platform decision

Use an official .NET-enabled Godot distribution matching the task version and a compatible SDK of matching host architecture. `dotnet --list-sdks`, engine `--version`, the csproj SDK and global.json are different facts. The 4.7 tutorial still names .NET 8+ (Android .NET 9+); honor a project's actual target and platform requirements rather than rewriting it to the newest installed SDK. A newer SDK can target an older framework after restore; actual build is the check.

Keep extra dependencies scoped to managed tasks. Standard Godot remains the plugin's default executable. Use installed tooling first; if necessary and authorized, download an official .NET editor to task storage, verify the release SHA256 and keep it out of packages. Do not silently install global SDKs or alter the user's NuGet sources. Task-local DOTNET_CLI_HOME/NUGET_PACKAGES keep restore/build output isolated; set DOTNET_SKIP_FIRST_TIME_EXPERIENCE and telemetry preferences according to environment policy before first invocation.

Desktop is the normal supported path. Android/iOS remain experimental in the documented baseline, requiring their native toolchains and compatible managed target. iOS build/export requires macOS; simulator architecture support is narrower than generic desktop support. Godot 4 C# Web export is unavailable: changing the preset cannot add it. A managed build is not evidence of successful Android/iOS publish or signing.

## Develop a Resource and use it from GDScript

Copy `assets/examples/minimal` to EXAMPLE. `Recipe.csproj` pins Godot.NET.Sdk/4.7.2 and net8.0 for this desktop example. ExampleResource.cs is partial, derives Resource, exports a clamped Score property and declares ScoreChangedEventHandler. Its setter emits Resource Changed and the custom signal only when the value changes. Public Add is callable through the script boundary.

```text
dotnet build EXAMPLE/Recipe.csproj --nologo
GODOT_DOTNET --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/run.log -- --out OUT
```

Create OUT before invocation. Require build exit 0 and no errors, then fourteen runtime assertions: method result, upper bound, generated signal values/lower bound, wide-integer Add/setter boundaries, save and independent uncached readback. Standard Godot returns blocked/2 with dotnet_engine_required; this is dependency detection, never a managed execution pass. Build artifacts belong to the copied project, not the packaged example. If the build succeeds but the engine cannot find the class, inspect assembly name/output, SDK and engine version before changing script names or clearing caches.

## Modify a gameplay Node

Inspect scene attachment, base type and existing exported values first. Keep the file/class name consistent for Godot attachment and all Godot-derived classes partial. Use `_Ready` only after children exist, `_PhysicsProcess(double delta)` for physics motion and generated property names from the actual binding. A property such as Position is a struct copy: use `var p = Position; p.X = value; Position = p;` rather than mutating a temporary component. GDScript integer and generated signal integer mappings can differ; inspect the generated declaration instead of choosing C# int from the RST label alone.

Use `MethodName`, `SignalName` and `PropertyName` generated identifiers for engine dynamic operations to avoid spelling/allocations where available. Cross-language method names require their actual script names: this example calls Add and connects ScoreChanged, while built-in method/property dynamic names usually follow engine snake_case. Do not automatically lowercase a C# script's exported property.

At Variant boundaries, use supported Godot collections/types and explicit conversion; ordinary generic managed collections are not interchangeable with every Variant container. Plain C# data is suitable behind a boundary but needs an explicit persistence schema if it must be saved. Avoid per-frame dynamic crossings without measurement. Object lifetime is native plus managed: an object reference can exist after native disposal, so check IsInstanceValid before delayed work.

## Signals, tools and debugging

Signal delegates end in EventHandler and accept Variant-compatible parameters. EmitSignal triggers the generated event; invoking an ordinary C# event is a different action. For capturing lambdas/custom-event subscriptions whose emitter can outlive the receiver, retain the delegate and unsubscribe on exit/disposal. Check repeated tree entry for duplicate subscription and exercise an emitter firing after receiver disposal. Connect with flags when cross-language or deferred semantics are needed.

Editor plugins use `[Tool]`, `#if TOOLS` for editor-only references as appropriate and a successful build before activation. Route editor transactions/lifecycle to godot-editor-tools. Rebuild after exported property or signal changes before evaluating Inspector results. Do not fix build diagnostics by suppressing source-generator errors.

For debugging, make an IDE build task execute dotnet build and a coreclr launch config point to the verified .NET Godot executable with project cwd. Attach/break on a real callback and inspect state/stack; successful compilation alone does not prove debugger attachment. Native Godot profiler timing and managed GC/allocations are separate observations; collect matching workload/warmup before changing language for performance.

## Diagnose and retest

| Symptom | Check | Cause | Fix | Retest |
|---|---|---|---|---|
| csproj restore/build fails | SDK, target framework, source URLs, generator diagnostic | Missing target pack, wrong Godot SDK or invalid declaration | Restore correct pinned dependencies; fix first diagnostic | Clean copied project build and runtime |
| Class missing despite build | .NET engine, assembly name/output and attachment | Standard engine or stale/different assembly | Select matching .NET engine, rebuild | Instantiate attached class and call method |
| Inspector misses export/signal | Partial keyword, Variant type, delegate suffix | Generator rejected member or stale assembly | Correct declaration/build | Actual Inspector and signal emission |
| Position change not applied | Value-type property access | Modified struct copy | Copy-modify-reassign | Assert actual transform over physics ticks |
| ObjectDisposedException after scene change | Captured subscriptions and queued tasks | Emitter/task outlives receiver | Disconnect/cancel on lifetime end | Destroy receiver then emit/complete task |
| Saved Resource aliases old instance | Loader cache and exported fields | Reused cache or unsaved ordinary fields | Check Saver result and CACHE_MODE_IGNORE | Reload in fresh process and compare values |

Sources: [C# basics](https://docs.godotengine.org/en/4.7/tutorials/scripting/c_sharp/c_sharp_basics.html), [API differences](https://docs.godotengine.org/en/4.7/tutorials/scripting/c_sharp/c_sharp_differences.html), [signals](https://docs.godotengine.org/en/4.7/tutorials/scripting/c_sharp/c_sharp_signals.html), [platform status](https://docs.godotengine.org/en/4.7/tutorials/scripting/c_sharp/index.html). Context7 snippets can contain stale or invalid mixed-language examples; compiler and pinned binding are acceptance evidence.



Engine binding/lifecycle reference: [fixed 4.7.2 source](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/modules/mono/csharp_script.cpp). Compare generated bindings and actual execution with this revision; internal implementation alone is not a callable scripting API.
