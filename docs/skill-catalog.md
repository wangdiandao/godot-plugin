# Skill catalog

**English** | [简体中文](skill-catalog.zh.md) · [Documentation](README.md)

Choose by the requested outcome. Cross-system game work belongs to `godot-workflow`; a bounded change belongs to its domain Skill. Follow each entry's prerequisites and adjacent-task exclusions.

| Area | Skill | Owns |
|---|---|---|
| Coordination | [godot-workflow](../skills/godot-workflow/SKILL.md) | Complete games, staged work across systems and delivery |
| Foundation | [godot-project](../skills/godot-project/SKILL.md) | Project creation, takeover, migration, input and Autoload |
| Foundation | [godot-api](../skills/godot-api/SKILL.md) | Version, CLI and public binding verification |
| Foundation | [godot-gdscript](../skills/godot-gdscript/SKILL.md) | Types, signals, async lifecycle and script organization |
| Foundation | [godot-scenes](../skills/godot-scenes/SKILL.md) | Scene ownership, instances, inheritance and persistence |
| Foundation | [godot-assets](../skills/godot-assets/SKILL.md) | Import, reimport and procedural resources |
| Content | [godot-2d](../skills/godot-2d/SKILL.md) | Tiles, maps, cameras and 2D content |
| Content | [godot-3d](../skills/godot-3d/SKILL.md) | Meshes, models, cameras and 3D content |
| Interaction | [godot-physics](../skills/godot-physics/SKILL.md) | Movement, collision, triggers and raycasts |
| Interaction | [godot-navigation](../skills/godot-navigation/SKILL.md) | Baking, connectivity, paths and moving agents |
| Interaction | [godot-ui](../skills/godot-ui/SKILL.md) | Layout, focus, themes, pointer input and localization |
| Presentation | [godot-animation](../skills/godot-animation/SKILL.md) | Libraries, tracks, blends and state transitions |
| Presentation | [godot-rendering](../skills/godot-rendering/SKILL.md) | Materials, shaders, lighting and visual checks |
| Presentation | [godot-audio](../skills/godot-audio/SKILL.md) | Playback, buses, effects and generated PCM |
| State/network | [godot-data](../skills/godot-data/SKILL.md) | Saves, migration, guarded writes and recovery |
| State/network | [godot-multiplayer](../skills/godot-multiplayer/SKILL.md) | RPC, authority, spawning and replication |
| Delivery | [godot-validation](../skills/godot-validation/SKILL.md) | Parsing, behavior, input, screenshots and failure diagnosis |
| Delivery | [godot-export](../skills/godot-export/SKILL.md) | Templates, presets, builds and exported-game acceptance |
| Engineering | [godot-architecture](../skills/godot-architecture/SKILL.md) | Module contracts, dependency injection and lifecycle |
| Engineering | [godot-performance](../skills/godot-performance/SKILL.md) | Measured CPU/GPU/memory diagnosis and comparisons |
| Engineering | [godot-editor-tools](../skills/godot-editor-tools/SKILL.md) | Tool scripts, editor transactions and plugin lifecycle |
| Conditional | [godot-csharp](../skills/godot-csharp/SKILL.md) | Godot.NET builds, bindings and managed debugging |
| Conditional | [godot-gdextension](../skills/godot-gdextension/SKILL.md) | Native builds, ABI, registration and loading diagnosis |

## From entry to executable example

Each entry links to a `references/native.md` contract and an `assets/examples/minimal/` project. Task-specific references extend those contracts. The [priority task report](priority-skills-validation.md) maps deeper recipes to named cases. Full 2D/3D games are under `godot-workflow/assets/examples/`.

The [capability index](capabilities.json) records sources, conditions, test IDs and tested/untested scope. The [Chinese coverage overview](coverage.zh.md) adds creation, modification and diagnosis prompts. Use [evidence](evidence.md) to distinguish a runnable example from an actually verified platform or host workflow.
