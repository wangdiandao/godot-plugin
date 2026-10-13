---
name: godot-editor-tools
description: Develop, modify, and diagnose Godot @tool scripts, EditorPlugin docks, inspectors and import/export tools with editor undo, persistence and lifecycle checks.
---

# Godot Editor Tools

## Purpose and Scope

Build tools used while authoring a game: scene previews, transactional scene edits, docks, inspectors and import/export integrations. Runtime menus belong to godot-ui; rebuilding the engine/editor itself is outside this workflow.

## Prerequisite Checks

Confirm an editor distribution, current edited scene, ownership/inherited-scene boundaries and the exact editor API. Check every executing helper has @tool or [Tool]; inherited GDScript tool annotation is not automatic. Read [native.md](references/native.md) and [execution](../../shared/references/execution.md). Use an isolated copy before enabling untrusted tool code.

## Workflow and Key Decisions

1. Choose @tool for local preview, EditorScript for a one-shot authoring operation, EditorPlugin for persistent UI/registrations. Keep runtime logic behind editor-hint decisions.
2. Register owned UI in _enter_tree and remove/free it in _exit_tree. Use EditorDock/add_dock for 4.7; project autoload registrations belong to enable/disable callbacks.
3. Make user edits an EditorUndoRedoManager transaction with the intended scene context. Persist added children with edited-root ownership; avoid changing imported/inherited internals accidentally.
4. Exercise do/undo/redo, save and uncached reload, then disable/re-enable repeatedly. Check callbacks and resources are disconnected/released, and inspect actual editor UX separately.

## File Changes, Saving, and Recovery

Edit only task-owned addon and target scene files. Preserve layout preferences and existing plugin activation state. A preview should not silently persist generated state; scene mutations need ownership and unsaved marking or undo integration. Undo before restoring a file snapshot; do not overwrite concurrent edits. Stop a tool loop by disabling that addon in the isolated project.

## Acceptance and Delivery

Require actual editor-process plugin activation, cleanup, undo/redo and saved scene readback. The example enables/disables its dock twice and verifies a transaction; headless execution can check these API/lifecycle contracts but cannot certify dock layout, focus, drag or accessibility. Use a real editor window for those and report untested UX explicitly. C# plugins also need a successful managed build.

## On-Demand References and Examples

- [Tool, dock, Inspector/importer recipes and diagnostics](references/native.md).
- [Editor integration example](assets/examples/minimal/project.godot), addon/plugin.gd and example.gd.
- [Persistence](../../shared/references/persistence.md), [evidence](../../shared/references/evidence.md).
