---
name: godot-ui
description: "Create or modify Godot menus, HUDs, and interactive interfaces, including Control layout, themes, focus, screen adaptation, and localization."
---

# UI and Localization

## Purpose and Scope

UI structure, interaction, themes, and localization. Use the corresponding 2D/3D skill for layouts in game world coordinates.

## Prerequisite Checks

Confirm target resolutions, aspect ratios, input devices, languages, and font coverage; inspect existing Themes and UI scenes.
Read the [execution conventions](../../shared/references/execution.md) before first launching the engine or changing execution modes. The research baseline is Godot 4.7.2; actual capabilities depend on the corresponding version, build, and runtime verification.

## Workflow and Key Decisions

1. Use Containers for flow layouts and Control anchors for edge positioning; do not combine Container layout with manually positioned children.
2. Put shared styles in a Theme and use theme overrides for local exceptions; configure minimum sizes, focus paths, mouse_filter, and processing while paused.
3. Use Translation/TranslationServer and tr for translation; provide fonts with actual glyph coverage for languages such as Chinese and check redistribution licenses.
4. Verify event paths through Input.parse_input_event or Viewport input; actually check keyboard focus, button clicks, and different resolutions.

## File Changes, Saving, and Recovery

Save UI scenes, Themes, translation resources, and required project settings; runtime language switching does not imply persistent settings.
For unresponsive clicks, check occlusion, mouse_filter, and paused processing first. For overflowing text, check container constraints and font coverage rather than simply reducing font size.
Read the [persistence strategy](../../shared/references/persistence.md) when persisting existing resources; follow the [recovery conventions](../../shared/references/recovery.md) on failure.

## Acceptance and Delivery

The example creates containers, buttons, a theme, and a translation, verifying layout and language lookup; game tests start gameplay through input events.
Report the actual engine and execution mode, changed files, verified behaviors, artifacts, and unmet conditions. Child script reports prove only the checks they executed; inspect logs and exit codes for the complete process as well.

## On-Demand References and Examples

- Read [native interfaces, commands, and pitfalls](references/native.md) before implementing specific operations.
- Run the [minimal executable example](assets/examples/minimal/project.godot); see the domain reference for its entry point and outputs. Examples write to a specified output directory and can run from a clean copy.
- Read the [evidence standards](../../shared/references/evidence.md) when maintaining evidence. The capability index is [capabilities.json](../../docs/capabilities.json).
