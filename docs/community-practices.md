# Community gameplay practices (Issue #25)

[Documentation](README.md) · [简体中文文档](README.zh.md) · [Current validation](community-validation.json)

## Scope / 本次范围

2026-10-14: retain the existing 23 skill names and add godot-ai. Community articles and posts provide concrete use cases and tradeoffs; source code, versioned official documentation and runtime acceptance define capabilities. The new sample code/shaders are original; third-party artwork and tutorial code are not redistributed. Context7 remains a research tool, not an installed runtime dependency.

| Absorbed use case | Owner and runnable contract |
|---|---|
| Nested wait termination, cancelled Tween, all-event ownership | [godot-gdscript terminal waits](../skills/godot-gdscript/references/terminal-waits.md); animation links to this contract |
| Tile rules, negative/transformed cells, dynamic blockers | [navigation grid bridge](../skills/godot-navigation/references/grid.md); 2d owns authored content |
| Shared definitions, isolated counts, JSON IDs and guarded progress | [data inventory](../skills/godot-data/references/inventory.md); workflow owns whole-game acceptance |
| Branch graph, reveal/skip, keyboard choice and repeated close | [UI dialogue](../skills/godot-ui/references/dialogue.md); data owns persistent quest facts |
| Staged shader pixels and embedded popup postprocessing | [rendering portal/popup](../skills/godot-rendering/references/portal-popup.md); UI owns actual input |
| Legal enemy decisions, stable local ties, bounded candidate planning | [new godot-ai](../skills/godot-ai/SKILL.md); navigation owns paths, physics owns sensors/motion |

The native references attribute each community source near the resulting recommendation, including dates/version qualifications. Performance adds game-specific monitor ownership, large-crowd tradeoffs and mouse polling diagnosis. Architecture adds state-machine/module choices; editor-tools adds undo reference lifetime; multiplayer documents an optional same-tree diagnostic. These supplemental recipes do not gain invented runtime evidence.

## Research checks / 研究核对

Context7 resolved Godot Engine and queried 4.7 Tween termination, TileMapLayer/AStarGrid2D point data, and embedded-window/screen-reading layering separately. Results were checked against the existing fixed documentation snapshot and current 4.7.2 binary. Context7's paraphrase that higher CanvasLayers execute sooner is not used: increasing numeric layers draw above lower layers. SceneMultiplayer is RefCounted, not a Node as a forum post calls it. Array deep copy does not universally clone Resource elements. Reports about UID crashes whose authors retract the root cause are not converted into cache-deletion repairs.

## Verification boundaries / 验收边界

Seven independently copied projects and one headless rendering negative case are registered in tests/cases.json. Inventory covers rule/HUD/JSON operations; dialogue covers action-dispatched keyboard choice, not pointer/CJK layout. AI uses supplied visibility; its operation budget is not a millisecond performance guarantee. Popup GPU checks apply to embedded Windows in Compatibility, not native windows/all renderers. Real editor preview breakpoint interaction, public multiplayer, team AI and installed-host automatic routing are not claimed. Current executed commands and outcomes are recorded in community-validation.json after validation; prior reports remain historical.


## Current results / 本次实测

Godot 4.7.2 on Windows: the full 61-case suite matched every expected outcome, including eight new cases (seven normal examples and the headless GPU rejection). The combined story/inventory fixture adds rule-owned once-only rewards and reloaded quest facts across three conversation restarts. GPU captures were inspected as well as checked numerically. Self-review corrected JSON numeric normalization, stale dialogue choices, deleting AI targets, state-boundary hysteresis and staged hash readback. Original 23-skill host-routing evidence remains historical; godot-ai has only author-reviewed routing and native execution evidence in this batch.


[Full current native/GPU/package/relocation logs](https://gist.github.com/wangdiandao/55cebaeea4b1ee5eeb5354a12da4f9b9) are published with repository path prefixes normalized. Original local log hashes remain in the validation record. Final archive hashes and relocation checks are recorded independently in the PR.
