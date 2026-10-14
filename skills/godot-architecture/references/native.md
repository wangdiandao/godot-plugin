# Architecture: Native Recipes

Copy the complete `assets/examples/minimal/` directory into an isolated workspace. Create a fresh OUT directory, then run:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

GODOT, EXAMPLE and OUT are absolute task-resolved paths. Inspect exit code, engine errors and `GODOT_PLUGIN_RESULT:` together. The fixture generates a saved scene under OUT; it does not edit an existing project. No Python or MCP is required at runtime.

## Develop a module with a composition root

Start with a concrete loop, such as an interaction that spends a charge and opens a gate. Draw the dependency graph before splitting files: charge rules/data → gate system → scene content and HUD. Keep a required command such as `try_open()` as a direct call with a result. Emit `opened` only after validation and state mutation; UI subscribes to the fact and sends intent through the command. A global event bus is useful only when publishers and listeners have genuinely independent lifetimes and the event contract remains discoverable.

Use a scene root to wire child components and supplied dependencies. Parent `_enter_tree()` runs before children; children `_ready()` run before the parent. A component that needs a sibling configured in parent `_ready()` must have an explicit `configure()` phase rather than guessing readiness. Set external dependencies before `add_child()` when callbacks require them. `_ready()` normally runs once, so reattachment needs an explicit reset or deliberately `request_ready()`; neither automatically restores gameplay state.

Choose Node components for processing, spatial interaction or tree-owned lifetime; choose Resource for authored definitions; use RefCounted for detached algorithms. Shared Resource data should not hold per-actor mutable cooldowns. Use a small enum state machine for a few local states; separate state modules when distinct dependencies and reusable behaviors justify the indirection. An Autoload is appropriate for persistent session/service lifetime, not as a place to put every gameplay object.

Acceptance: instantiate the module with a fake or deterministic service, prove invalid commands leave state unchanged, prove a valid command changes state once and emits once, and remove it while pending work exists. Run the bundled fixture for configuration, ready ordering, persistent signal reload, missing dependency rejection and disconnect on teardown.

## Modify an existing coupled system

Inventory the public callers and saved properties first. Keep existing node names and exported fields while moving one responsibility behind a contract. For example, move charge validation into a service without renaming the HUD's node paths. Supply the service from the composition root, connect HUD updates after initialization and render the initial state explicitly: signals do not replay old facts to late subscribers. Migrate saved properties deliberately if a field moves to a Resource; compare old/new saved scene state and reload both.

Keep a prototype scene or test gym for the isolated module. Do not introduce repository-wide folders, interfaces or dependency injection frameworks solely to imitate a large team. Verify the original gameplay path and isolated path produce the same observable outcome before removing old wiring.

When replacing a supplied service, disconnect the old publisher before attaching the new one; idempotent connection checks alone do not remove the old dependency. The fixture tests both replacement and teardown.

## Diagnose coupling and lifecycle failures

| Symptom | Check → cause → fix → retest |
|---|---|
| Sibling is null in ready | Inspect parent/child ready order → wiring happens too late → configure before tree entry or add explicit initialize → instantiate both standalone and under original parent. |
| Event runs twice | Inspect existing and runtime connections → duplicate setup on reentry → guard `is_connected()` or pair connect/disconnect → remove/readd and count effects. |
| HUD misses initial state | Inspect subscription timing → event occurred before connection → query current state on binding → load save before opening HUD. |
| One actor changes another | Inspect Resource identity → shared mutable runtime data → choose per-instance state or explicit duplication → mutate one of two instances. |
| Module only works in main level | Search absolute paths/Autoload dependencies → hidden dependency → supply a required contract and return an explicit missing-dependency result → run its isolated scene. |

## Sources and boundaries

The public implementation reference is [GDQuest godot-design-patterns at d783a51](https://github.com/GDQuest/godot-design-patterns/tree/d783a51bb7150e924754dc6078faee9aa3787f88), whose code and asset license boundaries were checked separately. Its scene composition and test-gym practice inform the recipes; these fixtures contain original code and no borrowed assets.

Architecture decisions derive from [GDQuest modular game architecture](https://www.gdquest.com/library/modular_game_architecture/) and the license-pinned project analysis in the research report, not copied project code. The layers and test gyms are options scaled to project needs. See [Node lifecycle](https://docs.godotengine.org/en/4.7/classes/class_node.html), [scene organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html) and [Autoload](https://docs.godotengine.org/en/4.7/tutorials/scripting/singletons_autoload.html). Engine internals and third-party architecture frameworks are not promised execution capabilities.

Version evidence: [fixed documentation snapshot](https://github.com/godotengine/godot-docs/tree/9adca4c1c72917bfe1b7be3108abed5ce26696a6) and [tested engine source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). API links use the 4.7 version branch; recheck the actual target engine.

## Community architecture decisions

[GDQuest's modular project case](https://www.gdquest.com/library/modular_game_architecture/) (2026-06 update) supports dependency boundaries and small experiment scenes; adapt its scale rather than prescribing its folders for every game. [Its state-machine comparison](https://www.gdquest.com/library/pattern_finite_state_machine/) (2026-04 update) supports choosing simple local enum state before splitting many state nodes. Enemy choices/utility scoring now belong to [godot-ai](../../godot-ai/SKILL.md); module dependencies remain here and animation playback stays in godot-animation.
