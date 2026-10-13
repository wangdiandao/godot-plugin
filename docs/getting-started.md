# Getting started

**English** | [简体中文](getting-started.zh.md) · [Documentation](README.md)

## Install the complete plugin

Follow the [host installation instructions](../README.md#installation) for Codex Desktop/CLI, Claude Code, Cursor or Gemini CLI. Keep the complete plugin root, hidden manifests, `skills/`, `shared/` and `docs/` together. Start a new host session after installation.

Ordinary GDScript tasks use the standard Godot editor distribution and OS tools. C# tasks additionally require Godot.NET and a .NET SDK; GDExtension tasks need matching bindings and a native build toolchain. The recorded engine baseline is Godot 4.7.2 on Windows; see [evidence](evidence.md) for actual scope.

## First task

Open your game project in the chosen agent and ask:

> Use godot-workflow to inspect this project. Report the plugin location, Godot binary and version, project state and missing prerequisites before making changes.

For explicit invocation, Codex uses `$godot-workflow`; Claude Code uses `/godot-plugin:godot-workflow`. Other hosts use their Skill discovery/invocation mechanism described in the installation guide. Natural-language selection is available where supported, but packaging checks alone do not prove installed-host implicit routing.

Confirm that the agent can read the complete plugin root and execute the discovered engine. Gemini sessions also need the loaded extension root in their allowed directories, as described in the installation guide. An engine outside discoverable/readable locations must be reported as missing.

## Choose a bounded request

| Request | Entry |
|---|---|
| Build a small playable 2D game, save progress and verify an export | [godot-workflow](../skills/godot-workflow/SKILL.md) |
| Diagnose a character passing through the floor | [godot-physics](../skills/godot-physics/SKILL.md) |
| Fix a menu overlay intercepting button input | [godot-ui](../skills/godot-ui/SKILL.md) |
| Check a suspected public API on the installed version | [godot-api](../skills/godot-api/SKILL.md) |

For other tasks, use the [Skill catalog](skill-catalog.md). Each Skill has a `references/native.md` contract and a standalone `assets/examples/minimal/` project; full game examples belong to `godot-workflow`.

## What delivery should contain

Ask for changed files, actual commands, logs, assertions and artifacts, together with unmet conditions. Verify persisted resources through independent readback. A headless pass does not establish rendered appearance, listening quality or target-platform behavior. See [testing](testing.md) for result interpretation and [shared tools](shared-tools.md) for execution and recovery contracts.
