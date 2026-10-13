# Architecture research

Research date: 2026-10-12. This is research evidence, not runtime validation.

## Requested GDQuest article

Fully read [Modular Game Architecture](https://www.gdquest.com/library/modular_game_architecture/) (updated 2026-06-15), including the team-size caveats and prototype workflow. The article targets Godot 4.x, not a specific 4.7 API revision. Its page identifies code as MIT but article prose and game assets as all rights reserved. No article text, screenshots, or assets are copied here.

The study separates reusable libraries, game systems, presentation, and game-specific content. Dependencies flow from content and UI toward systems, then libraries; systems do not import content. Their libraries are independent of other libraries. Experimental projects live separately and are excluded from export. The authors explicitly temper these rules for small games and teams: start simple, separate mechanics from level-specific content, then invest in stronger conventions when collaboration and project longevity justify them.

Implementation interpretation for this plugin: ask what needs replacing or testing independently before prescribing folders. A small game need not create four directories or a service container. For a larger project, document permitted dependencies and demonstrate replacement of one content scene without changes to shared mechanics. UI widgets should emit player intentions to an application controller; that controller validates commands, modifies state, and feeds display data back. This command path is an adaptation for interactive UI, not a claim that the article provides an implementation.

## Version-specific documentation research

Context7 selected `/godotengine/godot-docs/__branch__4.7` from the official, high-reputation documentation repository. Separate queries covered scene dependencies and Resource/lifecycle interaction. Results occasionally included `master` sources; those are leads only, not 4.7 evidence.

Fully read [4.7 scene organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html). Scenes should own their internal dependencies; their composition context supplies external references or Callables and connects signals. Signals report completed events while methods initiate behavior. Select the parent relationship by lifetime: a persistent player should not need rescue whenever its temporary room is freed. Autoload suits isolated, global state, rather than every system that accesses another system. Configuration warnings can surface missing dependencies in the editor.

Context7 also inspected excerpts of [Resource](https://docs.godotengine.org/en/4.7/classes/class_resource.html) and [overridable functions](https://docs.godotengine.org/en/4.7/tutorials/scripting/overridable_functions.html); this is not a claim that either full page was read. Resource sharing, local-to-scene duplication, and lifecycle ordering must be checked against the pinned local snapshot before implementation. Do not assume `duplicate(true)` clones every external nested Resource: the returned 4.7 excerpt explicitly distinguishes local resource duplication.

## Official demo practice and licensing

Read the official [demo README](https://github.com/godotengine/godot-demo-projects/blob/b761b4cd5718a7118f2c95eb55f181d0a5f004f1/README.md), [MIT license](https://github.com/godotengine/godot-demo-projects/blob/b761b4cd5718a7118f2c95eb55f181d0a5f004f1/LICENSE.md), [RPG README](https://github.com/godotengine/godot-demo-projects/blob/b761b4cd5718a7118f2c95eb55f181d0a5f004f1/2d/role_playing_game/README.md), complete [RPG game controller](https://github.com/godotengine/godot-demo-projects/blob/b761b4cd5718a7118f2c95eb55f181d0a5f004f1/2d/role_playing_game/game.gd), and its combat controller. Initial web reads used mutable master links; the local snapshot was then reread at the pinned revision above. This is design inspection, not runtime validation. No demo files are redistributed or added as regression fixtures.

The RPG controller wires combat/dialogue signals, passes combat scenes to an initializer, coordinates fades, and detaches/re-attaches the exploration and combat branches. This demonstrates a composition root and explicit subsystem transitions. It also illustrates a lifecycle review point: `remove_child()` retains an instance, so tree-entry callbacks and processing state deserve separate tests from object destruction. Its hard paths are appropriate to its owned hierarchy, not a universal contract for reusable components.

## Candidate acceptance scenarios

- Instantiate a reusable gameplay scene in two differently named parents; inject the dependency and observe the same behavior.
- Submit a UI command through a controller, reject invalid state, then publish accepted state once; replacing the widget must leave rules intact.
- Instantiate two actors from one definition Resource, mutate one actor's runtime state, and assert the other actor and definition remain unchanged.
- Remove and re-add a retained subsystem; assert subscriptions are not duplicated and state/lifetime match the intended transition.
- Swap level-specific content while retaining persistent player/session state; assert no stale node references or unwanted Autoload state survives a new session.

These are proposed checks, not executed results. The full-document review gate remains open until the authoritative coverage ledger is complete.

## GDQuest public design-pattern project (pinned source inspection)

Inspected `gdquest-demos/godot-design-patterns` at commit `d783a51bb7150e924754dc6078faee9aa3787f88`, downloaded to the ignored research directory. Read README, license terms, and the source files linked below; no project execution, copied assets, or regression-suite integration.

- [README](https://github.com/gdquest-demos/godot-design-patterns/blob/d783a51bb7150e924754dc6078faee9aa3787f88/README.md) supplies both node-state and simpler single-script variants. Choose an enum/state setter for a few local states; choose separate state nodes when state-specific collaborators and lifecycle cleanup justify the indirection.
- [License](https://github.com/gdquest-demos/godot-design-patterns/blob/d783a51bb7150e924754dc6078faee9aa3787f88/LICENSE) separates MIT source code from CC-BY-NC-SA 4.0 art. Research conclusions below are original; no art is distributed.
- [State machine](https://github.com/gdquest-demos/godot-design-patterns/blob/d783a51bb7150e924754dc6078faee9aa3787f88/godot/finite_state_machine/node_version/state_machine.gd) delegates engine callbacks only to the active state and applies exit then enter then notification. Validate target state type as well as path existence, define initial-state failure handling, and avoid transitions continuing old-state work after synchronous emission.
- [Typed player state](https://github.com/gdquest-demos/godot-design-patterns/blob/d783a51bb7150e924754dc6078faee9aa3787f88/godot/finite_state_machine/node_version/states/player_state.gd) exposes a typed actor interface. Its owner-ready dependency is specific to packed-scene ownership: injected collaborators and an already-ready check are needed for dynamic reuse. Re-entry and already-ready actors must be tested before adapting this design.
- [Single-script variant](https://github.com/gdquest-demos/godot-design-patterns/blob/d783a51bb7150e924754dc6078faee9aa3787f88/godot/finite_state_machine/simple_version/player_single_script.gd) keeps transitions and per-state physics nearby. A copied implementation would need a symmetric horizontal glide-speed clamp and a rule for repeated transitions to the current state.
- [Power system](https://github.com/gdquest-demos/godot-design-patterns/blob/d783a51bb7150e924754dc6078faee9aa3787f88/godot/entity_component/power_system.gd) discovers narrow source/receiver components while a RefCounted object owns distribution logic. This demonstrates composition without requiring an ECS framework. Before production reuse, define reset/idempotence for setup, transform world coordinates into tile-map local space, and clamp available power so later receivers cannot receive negative values. The old TileMap and warning syntax require separate Godot 4.7 API checks.

These source observations support architecture choices and failure-case design. They are not evidence that these third-party demos pass under the pinned engine version.
