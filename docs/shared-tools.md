# Shared tools and contracts

**English** | [简体中文](shared-tools.zh.md) · [Documentation](README.md)

## Native helpers

| Source | Purpose and boundary |
|---|---|
| [inspect_environment.gd](../shared/scripts/inspect_environment.gd) | Reports engine/environment and public bindings; `--class` selects an additional class to inspect |
| [inspect_project.gd](../shared/scripts/inspect_project.gd) | Loads project resources and records dependencies, scene structure and errors; engine execution can run project code |
| [run_checks.gd](../shared/scripts/run_checks.gd) | Runs manifest cases in isolated processes with wall-clock limits, log checks and reports; `--case` selects IDs |
| [capture_scene.gd](../shared/scripts/capture_scene.gd) | Loads a scene, renders and reads back a PNG; requires a real display/rendering process |
| [prepare_templates.gd](../shared/scripts/prepare_templates.gd) | Obtains selected official export templates with version/hash checks and overwrite protection |
| [common.gd](../shared/scripts/common.gd) | Internal argument, process, result and file utilities used by helpers and examples |
| [shared/host/project.godot](../shared/host/project.godot) | Neutral project for helper work that should not start target-project Autoloads |

These helpers do not create a persistent bridge/service. Godot-native execution remains the default path. Detailed commands belong to [execution conventions](../shared/references/execution.md) and the relevant Skill's native reference; consult the source for accepted helper arguments.

## Shared contracts

| Contract | When to read |
|---|---|
| [Execution](../shared/references/execution.md) | First execution, engine discovery or a change of execution mode |
| [Persistence](../shared/references/persistence.md) | Resource/scene changes, save operations and independent readback |
| [Recovery](../shared/references/recovery.md) | Failures, retries, rollback and task-owned cleanup |
| [Evidence](../shared/references/evidence.md) | Verification, result interpretation and capability updates |

Resolve engine, plugin, project and output paths explicitly, and create log/output parents before running commands. Keep generated output outside business assets and exports. Preserve existing files and saves; cleanup only verified task-created paths. A zero exit code or child success marker is insufficient without outer logs, assertions and expected artifacts. See [testing](testing.md).
