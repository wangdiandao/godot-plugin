# Foundation implementation and evidence

Issue: #7. Scope: existing `godot-project`, `godot-gdscript`, `godot-scenes`, `godot-data`, `godot-workflow`, `godot-api`, and new `godot-architecture`. This batch does not change the global manifests, capability index, routing inventory, release version or PR state.

## Provenance and research boundary

Implementation began after the complete documentation gate passed. Documentation snapshot: `9adca4c1c72917bfe1b7be3108abed5ce26696a6`. Local runtime: Windows standard Godot `4.7.2.stable.official.ed1daf0bf`, reporting full source hash `ed1daf0bf001b61586d9930840f2f1394092c079`.

The source snapshot is not a complete Git checkout. Running `git -C artifacts/research/godot-4.7.2-stable rev-parse HEAD` traversed into the parent plugin repository and returned an unrelated plugin commit. That evidence was rejected. The snapshot's literal `.git/HEAD` and `version.py`, together with the executing engine's version/hash, establish the engine revision used in all owned reference links.

Context7 research used `/godotengine/godot-docs/__branch__4.7` after resolving Godot Engine, with separate queries for PackedScene ownership/persistent connections/lifecycle, Resource duplication/scene-local resources, and JSON save migration/flush/rename. Retrieval occasionally included master snippets and insufficient JSON numeric guidance; fixed version documentation, bindings and actual behavior took precedence. Context7 is not a packaged runtime dependency.

Binding checks included `Resource::duplicate_deep` in `core/io/resource.cpp`, `PackedScene::pack` in `scene/resources/packed_scene.cpp` and `Node::set_owner` in `scene/main/node.cpp`. The API fixture additionally checks public bindings and invokes pack/save/reload; it does not infer behavior from method existence alone.

GDQuest architecture conclusions and license-pinned project analysis remain in [architecture-research.md](architecture-research.md). No third-party art or code was copied into fixtures.

## Implemented task contracts

All seven entries use the six required sections, English instructions and task-specific acceptance. Each reference provides development, modification and diagnosis recipes with explicit choices and symptom → check → cause → fix → retest paths. UI metadata matches the boundaries and keeps implicit invocation enabled. Existing names and native execution remain available.

Project configuration now has a genuinely launched generated project with a Session Autoload and persistent InputEvent round trip. Scene tests prove unowned exclusion and actual persisted connection execution. GDScript tests include signal disconnect behavior. API tests distinguish bindings from owned/unowned scene behavior. Workflow's minimal checkpoint executes an interaction after reload; complete playable examples remain separately tested.

Architecture introduces a composition root, supplied RefCounted service and Node observer, with pre-ready configuration, command validation, intent/fact delivery, idempotent connection setup, dependency replacement, teardown and saved scene reload. The exported observer snapshot is verified before tree entry; the newly created service deliberately supplies fresh state on entry. This is not a save-game restoration claim.

Data now has strict ordered v1→v2 migration, separate load statuses, finite/integral numeric checks, staged write/readback, validated backup, conflict hash comparison, deliberate corruption and future-version preservation. Recovery returns validated backup data without overwriting the corrupt original. Hash checking is not a cross-process atomic lock; the recipe explicitly requires a single writer and does not promise power-loss atomicity. The additional Resource fixture proves internal/external duplication policy, repeated alias preservation, collection independence, uncached disk readback and scene-local mesh isolation.

## Actual native execution

Runs performed on 2026-10-13 from repository root. Each fixture was copied to a fresh isolated project under `artifacts/validation/`; output directories were separate and created first. The commands used the console engine above, not a shell-resolved unknown Godot.

```text
GODOT --headless --quit-after 240 --path COPY --script COPY/example.gd --log-file OUT/engine.log -- --out OUT
GODOT --headless --quit-after 600 --path GAME_COPY --log-file OUT/engine.log -- --self-test --out OUT
```

`GODOT`, `COPY`, `GAME_COPY` and `OUT` were concrete absolute paths. stdout/stderr were redirected to `OUT/console.log`; exits, result objects and engine error records were inspected together. The frame limit bounded failures independently of script exit.

| Committed fixture | Last relevant run | Assertions | Result |
|---|---|---:|---|
| `skills/godot-project/assets/examples/minimal` | `foundation-deepening-r3/project` | 7 | Passed; exit 0; errors 0 |
| `skills/godot-gdscript/assets/examples/minimal` | `foundation-deepening-r3/gdscript` | 5 | Passed; exit 0; errors 0 |
| `skills/godot-scenes/assets/examples/minimal` | `foundation-deepening-r3/scenes` | 6 | Passed; exit 0; errors 0 |
| `skills/godot-workflow/assets/examples/minimal` | `foundation-deepening-r3/workflow` | 4 | Passed; exit 0; errors 0 |
| `skills/godot-api/assets/examples/minimal` | `foundation-deepening-r3/api` | 8 | Passed; exit 0; errors 0 |
| `skills/godot-architecture/assets/examples/minimal` | `foundation-deepening-r4/architecture` | 16 | Passed; exit 0; errors 0 |
| `skills/godot-data/assets/examples/minimal` | `foundation-deepening-r4/data` | 29 | Passed; exit 0; errors 0 |
| `skills/godot-data/assets/examples/resources` | `foundation-deepening-r3/data-resources` | 13 | Passed; exit 0; errors 0 |
| `skills/godot-workflow/assets/examples/game-2d` | `foundation-deepening-games-r7/2d` | 9 | Passed; exit 0; errors/warnings 0 |
| `skills/godot-workflow/assets/examples/game-3d` | `foundation-deepening-games-r7/3d` | 9 | Passed; exit 0; errors/warnings 0 |

Total: 106 passing behavioral assertions across ten fixtures. Negative checks pass because the operation rejected invalid input or preserved files as required; failed operations are not described as successful writes.

Failures were retained and repaired before the passing runs:

- Generated main script inferred a bool from dynamic Autoload state and failed parsing. An explicit bool declaration fixed it; child execution now includes its own frame limit.
- Resource external references saved with Windows backslashes failed readback. Normalizing OUT to forward slashes fixed text-resource path serialization; null load now produces a failed structured assertion rather than an uncontrolled access.
- Self-review found that configuring a replacement service could leave the old signal connected. Disconnecting before replacement and adding three assertions fixed the lifetime contract.
- Self-review found future-version detection had an unnecessarily small upper limit. It now covers exactly representable integral JSON versions, with two additional preservation assertions.
- Complete game restart checks ran before synthetic input finished processing. Several subsequent frames now precede the assertion, and global restart uses `_input()` so focused UI does not consume it. Both complete loops pass.
- Verbose shutdown identified AudioStreamWAV/AudioStreamPlaybackWAV leaks while exiting during playback. Tests stop playback, clear the stream and allow cleanup before exiting; final game runs contain no error or warning records.

## Author checks and integration handoff

Ran the system skill-creator `quick_validate.py` using `C:/Users/Lenovo/.codex/tools/blender-mcp/.venv/Scripts/python.exe -X utf8` against each of the seven skill directories: all seven valid. The MSYS Python used for authoring lacks PyYAML, so it was not used to claim validator success. Trailing blank lines were normalized after the initial diff check reported them.

Final owned-scope checks: `git diff --check -- skills/godot-project skills/godot-gdscript skills/godot-scenes skills/godot-data skills/godot-workflow skills/godot-api skills/godot-architecture docs/research/foundation-implementation.md` returned no findings. A Python local-link, required-six-section and YAML default-prompt check found zero errors; quick validation was repeated after final newline normalization and all seven passed. These checks cover owned files and do not substitute for the coordinator's complete package/manifest validation.

Suggested global case additions for the coordinating agent:

- `architecture-example`: minimal architecture project/script, `skill` and `capability_id` `godot-architecture`, headless, `--out {output}`, timeout 30; require passed report, exit 0, zero engine errors and sixteen behavior assertions.
- `data-resource-example`: `godot-data/assets/examples/resources`, same native script contract, headless, timeout 30; require duplication, reload and scene-local assertions. Capability belongs to `godot-data`.
- Existing foundation minimal case IDs continue to point to their original directories; update their descriptions/counts to actual evidence above. Complete workflow games need their own invocation without `--script`, including `--self-test`.

The root agent coordinates global structure/link/package checks and actual explicit/natural-language routing evaluation. This batch's native runs do not establish host routing. Visual appearance, screenshot capture, audible playback, other operating systems, exports, power loss and cross-process save contention remain untested here. No historical validation result was substituted for these runs.


## Coordinator staged-snapshot verification

The exact staged foundation batch, with the original neighboring domains and a 19-Skill registry, was materialized with `git checkout-index --all --prefix=.../artifacts/foundation-pr-review/`. Structure/schema/local-link validation passed 834 checks. Native `run_checks.gd` ran that snapshot with normal GPU/localhost access; report `artifacts/foundation-pr-runtime/cases/1791879319-432-17188/report.json` has status passed, no failed parent checks, and exit 0. No other domain's uncommitted implementation was included in that snapshot. The full run includes existing visual/loopback cases plus architecture and Resource cases. Raw logs remain ignored.
