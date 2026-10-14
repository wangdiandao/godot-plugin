# Research baseline and technical choices

**English** | [简体中文](research.zh.md)

[Documentation](README.md) · [Architecture](architecture.md) · [Research and validation evidence](evidence.md)

Checked on 2026-10-11. The baseline is **4.7.2-stable**, official build commit `ed1daf0bf001b61586d9930840f2f1394092c079`. Release information comes from the [official release](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) and [official API](https://api.github.com/repos/godotengine/godot/releases/tags/4.7.2-stable), rather than a version inferred from model memory.

The local environment uses the matching standard Windows editor binary, official export templates and official source archive. Download digests were checked against official release metadata:

| Asset | SHA256 |
|---|---|
| Godot_v4.7.2-stable_win64.exe.zip | `731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953` |
| Godot_v4.7.2-stable_export_templates.tpz | `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` |

Human-readable documentation is pinned to en/4.7. That branch can still change, so exact patch-level interface decisions also use source from the same tag, its class XML and local `--dump-extension-api-with-docs`. The capability index links each domain's official class documentation and fixed-commit XML.

Context7 became available later in the session. Godot Engine was resolved to `/godotengine/godot-docs/__branch__4.7`, with separate queries for CLI/export, PackedScene saving and navigation synchronization. Mixed-in master sources were not treated as 4.7.2 evidence; fixed source and runtime tests confirmed key conclusions. Context7 is neither declared nor installed with the plugin.

## Key decisions

| Conclusion | Official basis and verification |
|---|---|
| CLI scripts use SceneTree/MainLoop | [CLI documentation](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html); all helper scripts actually ran |
| Native import and export work without an interactive editor | Same source; clean-copy import, Windows/Web builds and execution of Windows outputs |
| Scene owner and persistent signals must not be omitted | [PackedScene](https://docs.godotengine.org/en/4.7/classes/class_packedscene.html), [Object](https://docs.godotengine.org/en/4.7/classes/class_object.html); reload after saving and trigger the signal |
| Navigation supports CPU geometry baking | [Source geometry API](https://docs.godotengine.org/en/4.7/classes/class_navigationmeshsourcegeometrydata3d.html); bake a nonempty mesh and find paths across regions |
| map/region updates require waiting | [NavigationServer3D](https://docs.godotengine.org/en/4.7/classes/class_navigationserver3d.html); paths pass after waiting for valid iteration and regions |
| LightmapGI.bake is not exposed to GDScript | [Binding source](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/lightmap_gi.cpp#L2122); local ClassDB returns false |
| action_press alone cannot replace GUI input | [Input](https://docs.godotengine.org/en/4.7/classes/class_input.html); parse_input_event drives focused buttons and the game |
| headless does not prove actual rendering | [CLI](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html); real GPU Shader pixel checks and game screenshots |
| Export presets must include include_filter | [Preset reader source](https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export.cpp#L378); omission logs errors, corrected presets pass |
| Import errors may exit with code 0 | [Import process](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html); observed with the corrupt PNG fault case, recognized as failure by the parent runner |

## Boundaries without external tools

Standard capabilities handle native resources, procedural geometry, UI, GDScript, physics, navigation, animation, sound effects and serialization. Reuse the engine's existing import/export workflows directly. Check public APIs, GPU requirements and context individually for advanced rendering/editor features; do not claim every visual button has a script equivalent.

The `--editor --script` probe could access EditorInterface/EditorFileSystem, but local exit produced resource-leak logs. This path was not recorded as a passing production-helper capability. Routine operations use native `--import` and ordinary SceneTree resource APIs. Platform SDKs, signing, baking without public bindings and external DCC formats retain their stated boundaries.
