# Plugin architecture

**English** | [简体中文](architecture.zh.md) · [Documentation](README.md)

## Package responsibilities

| Path | Responsibility |
|---|---|
| `plugin.json`, host manifests and marketplace entry | Host discovery, identity and presentation; see [compatibility](compatibility.md) |
| `skills/<name>/SKILL.md` | Task trigger, prerequisites, decisions, persistence/recovery and acceptance |
| `skills/<name>/references/` | Detailed native API/CLI contracts and task-specific recipes |
| `skills/<name>/assets/examples/` | Independently runnable projects owned by the Skill |
| `shared/references/` | Common execution, persistence, recovery and evidence contracts |
| `shared/scripts/`, `shared/host/` | Native helpers and a neutral host project |
| `tests/` | Case manifests, fixtures, integration checks, routing prompts and author-only structure validation |
| `docs/` | Reader navigation, authoring policy, capability records and dated validation/research evidence |

The host loads a Skill and supplies the agent's file and process tools. The plugin's default runtime path uses native Godot CLI/GDScript. Context7 supports author research; it is not a plugin runtime dependency. Conditional language/tooling tasks declare their own prerequisites.

## Task flow

1. Match the user's intent to a domain Skill, or `godot-workflow` for work across systems.
2. Discover the engine, record its version and inspect the project/environment.
3. Load the relevant native recipe and shared contracts on demand.
4. Make a bounded change, preserve unrelated files and save through the task's persistence contract.
5. Run suitable checks, inspect outer-process logs and independently read back saved outputs.
6. Deliver evidence and state any blocked, unsupported or untested scope.

See the [Skill catalog](skill-catalog.md) for ownership and [shared tools](shared-tools.md) for reusable operations. There is no requirement to load all Skills for a single task.

## Execution boundaries

The neutral [shared host](../shared/host/project.godot) avoids starting the target project's Autoloads for helper-only work. Running a check in a target project may execute its initialization and tool scripts. Editor-only operations and real rendering use their required contexts, rather than treating every check as an ordinary headless script.

The installation package contains the runtime Skills, shared resources and documentation. The source package also includes tests and contribution material. Generated outputs, research downloads and engine caches stay outside distribution. Keeping the package together preserves relative references between Skills, shared files and docs.

## Sources of truth

Skill entrypoints own routing and task acceptance; their native references own detailed procedures. [Authoring](authoring.md) owns the technical contribution contract. [Capabilities](capabilities.json) maps Skills to sources, examples and tests. [Evidence](evidence.md) indexes observed outcomes by date and scope. Topic pages should link to those contracts rather than duplicate long recipes or reinterpret historical runs as current validation.
