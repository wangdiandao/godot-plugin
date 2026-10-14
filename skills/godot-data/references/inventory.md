# Inventory definitions, commands and protected progress

## Develop or modify

Keep trusted authored item definitions (stable ID, icon, maximum stack, effects) separate from per-inventory counts, durability and cooldowns. Shared Resource definitions can be read by many actors; mutable inventory state must belong to each inventory. Never use get_instance_id as a persistent item ID. A saved resource path may identify an unchanged internal definition, but explicit IDs and a definition registry make asset moves/migrations deliberate.

Validate pickup/use/drop/transfer commands before mutating counts. Define capacity, overflows, unknown items and full-health consumable policy. Emit completed state after mutation and render initial HUD state when binding; disconnect an old inventory on replacement. Transfers need one transaction owner so a failed destination cannot lose source items. Cross-system interaction and reset acceptance belong to godot-workflow.

Serialize JSON-compatible IDs and runtime values, not Resource/Node debug strings. Validate every loaded item against the registry and finite integral bounds before committing any field; JSON numeric floats need validation then normalization to integers. Support ordered schema migrations with existing [save recipes](native.md). Preserve unsupported/corrupt bytes instead of writing defaults over them. If definitions change, decide how removed items or reduced capacities migrate, rather than silently dropping progress.

## Fixture and limits

Copy the complete example directory to a fresh workspace, create OUT, then run:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Use absolute paths. Inspect the exit code, full error log and named `GODOT_PLUGIN_RESULT:` assertions together. Outputs belong to OUT; do not run fixtures against a player's real saves.

The [inventory example](../assets/examples/inventory/project.godot) runs pickup/use with a Label HUD, shared read-only definition and separate inventories, rejected commands, staged JSON commit/readback, future-version commit protection, invalid snapshots with no partial mutation, publisher replacement and repeated reset/use. Its save method retains a previous valid backup and reports conflicts; the fixture is a single writer, not a process lock or power-loss atomicity proof. Backup conflicts require an explicit recovery/rotation policy; do not delete a user's backup to force success. It does not implement drag/drop, equipment or multi-inventory transfers.

Diagnose a bad restored item in order: save schema→stable definition ID→mutable state→validation/migration→UI binding. If every actor loses HP together, inspect shared Resource identity before changing signals. Loading externally supplied executable Resources is not a substitute for a primitive save schema.

Sources: [JSON](https://docs.godotengine.org/en/4.7/classes/class_json.html), [Resource](https://docs.godotengine.org/en/4.7/classes/class_resource.html), [FileAccess](https://docs.godotengine.org/en/4.7/classes/class_fileaccess.html). Community cases: [JSON Resource failure](https://forum.godotengine.org/t/retrieving-custom-resource-data-from-json-file/143524) (4.7, 2026-08), [three-layer inventory](https://uhiyama-lab.com/en/notes/godot/inventory-system/) (author's 4.7 note), [shared mutable Resource report](https://forum.godotengine.org/t/someone-please-explain-me-how-to-properly-use-multiple-istances-of-resources/113379) (4.4.1, 2025-06). Older duplication advice must be checked against the target Resource/Array contracts.

Version evidence: [Godot 4.7.2 source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). Recheck the actual target binary. Community discussions supply use cases; official contracts and runtime checks determine supported behavior.
