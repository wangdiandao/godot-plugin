---
name: godot-ui
description: "Develop, modify, and diagnose Godot menus and HUDs, inherited Themes, keyboard/gamepad focus, resolution adaptation, text shaping, and localization."
---

# UI, Themes, Input, and Localization

## Purpose and Scope

Deliver usable screen interfaces and localized interaction. World gameplay geometry belongs to 2D/3D skills; this skill can handle Viewport-based UI when input mapping is part of the task.

## Prerequisite Checks

Inspect existing Control/Container hierarchy, Theme scopes, local overrides, input actions, pause modes, target window sizes and locale/font requirements. Distinguish focus from LineEdit editing and translate-message lookup from actual glyph rendering.

Baseline: Godot 4.7 documentation and locally verified Godot 4.7.2. Read [execution conventions](../../shared/references/execution.md) before the first engine launch; confirm the actual project version.

## Workflow and Key Decisions

For branching dialogue, reveal/skip and choice input, read the [task recipe](references/dialogue.md).

1. Choose Container flow versus anchored overlays; set logical base size, aspect policy and minimum window size before laying out children.
2. Follow the relevant native.md recipe for new menus, existing-theme modifications or input/text failures. Use project/parent Themes for shared styling and local overrides for exceptions.
3. Define initial focus, focus neighbors, mouse filtering and pause processing. Exercise press and release through real input dispatch rather than emitting widget signals.
4. For language/catalog tasks, read localization.md: persist registrations, audit keys/context/formatting, and retest existing UI on repeated locale changes. Use licensed font fallback stacks and appropriate BiDi/line-breaking language. Handle IME composition and grapheme boundaries for text entry.
5. Save the scene, Theme and localization preferences separately; reload without cache and test layout, focus and translated text at representative aspect ratios.

## File Changes, Saving, and Recovery

Set scene owners for generated children. Duplicate shared StyleBoxes before local edits. Theme fallback getters can hide missing definitions; verify explicit items and effective child lookup after readback. Remove an override to test inheritance recovery. Preserve the prior locale and scene references when recovering. Use [recovery conventions](../../shared/references/recovery.md) when a failure needs restoration.

## Acceptance and Delivery

For pointer interception, reproduce actual press/release, repair only the unintended blocker, repeat activation and retain an intentional modal-blocking control. Read the pointer diagnosis in native.md; preserve styling and geometry.

The minimal example saves and reloads Theme and PackedScene, checks inherited font/style/color, persisted local overrides and removal, then verifies layout, focused button input and translation lookup. This does not prove CJK glyph coverage, screen-reader behavior or layout at every resolution; collect actual rendered/input evidence for those conditions. Deliver changed files, exact commands/version/mode, assertions, artifacts, failures and explicit untested scope. Logs and exit codes must agree with reports.

## On-Demand References and Examples

Read [native localization workflow](references/localization.md) for translation catalogs, language changes, missing keys or plural/context failures; run its standalone example for those contracts. Font shaping/layout quality still requires rendered acceptance.

Read [UI recipes and failure paths](references/native.md) before implementing the selected task; run the [menu example](assets/examples/minimal/project.godot) in a clean copy. Load [persistence conventions](../../shared/references/persistence.md) when editing existing scenes/resources.
