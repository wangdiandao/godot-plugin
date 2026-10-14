# Cross-system modifications and protected progress

## Choose the checkpoint

| User goal | Entry example | Acceptance |
|---|---|---|
| Build a playable loop | game-2d or game-3d | Real input, rules, win, save, restart |
| Add a limited gameplay resource | bounded-resource | Command validation, HUD state and repeated reset |
| Inspect scene persistence only | minimal | Saved hierarchy/connection; not full gameplay |

## Develop or modify one coherent slice

1. Write a table of player action, authoritative state transition, presentation response and reset/persistence policy. Capture existing behavior before touching the domain implementations.
2. For a limited resource, define initial amount, cost, rejection and reset. Validate in the rule/service before mutating, then publish the completed value. Presentation sends intent, not a client-authored final value.
3. Render initial HUD state explicitly after binding; signals do not replay past facts. Replacing a service must disconnect the old publisher before connecting the new one.
4. Keep transient charges separate from persistent best score. Reset only the requested transient state; schema changes to permanent progress require godot-data migration and preserved unknown/future saves.
5. Run valid command, exhausted command and three restarts. Count accepted effects and verify the old publisher cannot update the new HUD. Re-run the original gameplay scene, including real input; a module fixture proves only its own integration contract.

The [bounded-resource fixture](../assets/examples/bounded-resource/project.godot) includes a rule service, button intent and HUD binding. It consumes two charges, rejects a third, repeats reset/use three times and tests an old event after publisher replacement. Its emitted button signal establishes command wiring; the playable games separately exercise keyboard dispatch. Copy the entire example and run example.gd with native.md's command.

## Protected game-example saves

Both playable examples include their own save_store.gd, so copying either project preserves its complete runtime. The store distinguishes missing, parse corruption, invalid schema, unsupported future version and I/O failure. Only missing/valid state may commit. Numeric fields must be finite integral values within the supported bounds; clamping malformed input is not validation.

On invalid/unsupported data, gameplay may continue with temporary defaults while a visible HUD message reports protected progress. Completing the game must not replace those bytes. An explicit user-chosen reset/recovery flow would be a separate operation; this example does not silently select it.

The single writer captures a fingerprint, writes/flushes/closes a unique staged file, validates it, checks the fingerprint again, preserves a backup, commits and verifies readback. Backup conflicts and failed writes abort. A failed rename restores the backup only if the target is absent; otherwise evidence is preserved. A remaining unexpected backup is not deleted to force success. Fingerprints are not cross-process atomic locks and flush is not a power-loss guarantee.

The games' self-tests additionally attempt to save over corrupt JSON, future version, fractional/negative score and wrong root type, compare original hashes, inject an external change and test an unwritable missing-parent path. Each normal playthrough still checks best-score readback. Failed commits expose their status rather than printing a misleading successful save.

## Diagnose a cross-system failure

| Symptom | Trace in order | Repair and acceptance |
|---|---|---|
| Input observed, resource unchanged | Intent → command result → rule mutation | Fix missing/rejected command; normal and exhausted input |
| HUD starts wrong | Current state → binding → initial render | Query state at binding; load before HUD creation |
| Restart doubles effects | Old nodes → publisher lifetime → subscriptions → command count | Detach/reset owners; three restarts with exact counts |
| Old completion changes new level | Request generation → target lifetime → publisher replacement | Cancel/detach old work; deliberately late completion |
| Progress resets unexpectedly | Save status → schema/version → commit permission → file hash | Preserve blocked target; valid save and protected negative controls |

After a failure, return to the last coherent runnable checkpoint and restore only task-owned changes. Keep the original failure/log and rerun caller paths after each specialist fix. Report visual, audible, device, exported-artifact and host-routing evidence separately.

Sources: [Node lifecycle](https://docs.godotengine.org/en/4.7/classes/class_node.html), [saving games](https://docs.godotengine.org/en/4.7/tutorials/io/saving_games.html), [JSON](https://docs.godotengine.org/en/4.7/classes/class_json.html), [FileAccess](https://docs.godotengine.org/en/4.7/classes/class_fileaccess.html).

## Inventory and conversation slices

For pickup→stack→use→HUD→save/reload, combine [inventory rules and snapshots](../../godot-data/references/inventory.md) with an actual world pickup/input in the target game. For NPC interaction→reveal→reply→quest command→close/reopen, combine [dialogue UI](../../godot-ui/references/dialogue.md) with a rule-owned completion ID and protected progress. Do not grant rewards from UI close events alone. Each domain example proves its contract, not the whole player loop; repeat the target loop after restart and run its exported build. The inventory fixture tests repeat reset/use and guarded writes; the dialogue fixture tests keyboard choice and close/reopen, but no persistent reward integration.

[Err Friday's Web failure postmortem](https://blazowacho.itch.io/err-friday/devlog/1003353/gmtk-game-jam-2025-post-mortem-when-everything-breaks-and-how-to-fix-it) (2025-08) motivates early target-build checks for death/revival, AI and cursor behavior. Its claimed failure has no proven engine root cause; do not infer one. Use the existing [Web acceptance](../../godot-export/references/web.md) for real browser input/save reload.


Run the self-contained [story-inventory slice](../assets/examples/story-inventory/project.godot) with the ordinary absolute-path example command. It copies its original rule/view modules locally, dispatches keyboard choice, validates a once-only reward, renders the inventory HUD, writes a fresh OUT progress envelope, reloads both inventory/claimed facts and repeats the conversation three times without another reward. Malformed quest state cannot partially mutate inventory. Its direct progress write is only a fresh-output fixture operation, not a production replacement-save protocol; production uses godot-data's protected staged commit policy. World NPC movement, pointer interaction and exported target-game acceptance remain separate.
