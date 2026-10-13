# Resource behavior probe

中文概览：2026-10-13 在 Windows、Godot 4.7.2 原生无头模式实测资源复制、引用关系、保存读回及场景局部资源隔离。最终断言通过；初次失败和修正保留。此证据只核验这些行为，不是 Skill、C#、GPU、视觉或 HDR 验收。

## Actual environment and command

Godot `4.7.2.stable.official.ed1daf0bf`, engine revision `ed1daf0bf001b61586d9930840f2f1394092c079`. The original probe project and logs are task-created, ignored artifacts under `artifacts/research/resource-behavior-probe`; they are not packaged examples or a portable acceptance fixture yet.

```powershell
& artifacts/tooling/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path artifacts/research/resource-behavior-probe --script res://probe.gd --log-file probe-verified.log
```

Final process exit: `0`; result: `passed=true`, `failures=[]`. The script explicitly quits with `1` when an assertion fails. A preliminary script error was interrupted rather than counted as success.

## Verified behavior

- A shallow Resource duplicate shares its internal and external subresources.
- `duplicate(true)` copies the internal child and nested data array while retaining the external resource loaded from its path.
- Repeated references to the same internal child remain repeated references to one new child, rather than separate copies.
- `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` copies external data but retains the attached Script definition.
- Saving and loading with `ResourceLoader.CACHE_MODE_IGNORE` reproduces marker values in another object; mutating the source afterwards leaves that loaded state unchanged.
- Two instances of a packed scene receive independent `BoxMesh` resources when `resource_local_to_scene` is set before instantiation. Mutating one mesh leaves the other's default size intact; `get_local_scene()` points to the instance root.

These observations agree with [Resource documentation](https://docs.godotengine.org/en/4.7/classes/class_resource.html) and the fixed [duplication implementation](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/io/resource.cpp).

## Failures corrected in the probe

The first run assigned an untyped array to a typed exported array through a variable inferred as Resource; Godot rejected the assignment. The probe now uses `assign()` for explicit conversion. This is a recipe typing issue, not a reason to remove the typed property.

The next run failed the external-sharing assertion: saving a newly created resource did not assign its top-level `resource_path`, even with `FLAG_CHANGE_PATH`. Both children therefore still qualified as internal. The probe now reloads the saved external resource before testing external-sharing semantics. Inspection showed `external_path=res://external.tres`, `deep_child_same=false`, and `deep_external_same=true` in the passing run. The failed assumption and its diagnostic logs remain separate from the final result.

## Unverified scope

No C# build, native extension, editor UI, resource-change signal timing, visual mesh rendering, GPU memory result or HDR output was tested. These headless observations do not satisfy those acceptance conditions. Resource constructors, usage flags, cyclic data and malformed saves still need dedicated cases when incorporated into the corresponding Skill recipes.
