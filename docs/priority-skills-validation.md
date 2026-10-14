# Priority skill implementation and validation

**English** | [简体中文](priority-skills-validation.zh.md)

[Documentation](README.md) · [Skill catalog](skill-catalog.md) · [Evidence index](evidence.md)

Issue: [#21](https://github.com/wangdiandao/godot-plugin/issues/21). Source version: 0.2.2. This change preserves all 23 skill names and Godot-native runtime execution.

## Implemented task contracts

| Skill | Recipe | Standalone case |
|---|---|---|
| godot-gdscript | [Async cancellation, replacement and signal reentry](../skills/godot-gdscript/references/tasks.md) | gdscript-async-lifecycle |
| godot-navigation | [Actual agent movement, patrol and avoidance callbacks](../skills/godot-navigation/references/movement.md) | navigation-moving-agent |
| godot-animation | [State transitions, blends and interrupted actions](../skills/godot-animation/references/locomotion.md) | animation-state-machine |
| godot-physics | [3D motion, slopes, rigid wake/impulse and fast point sweeps](../skills/godot-physics/references/controllers.md) | physics-body-3d |
| godot-3d | [Procedural normals/tangents and persisted bone sockets](../skills/godot-3d/references/models.md) | 3d-mesh-socket |
| godot-assets | [Native import settings and preserved authored wrappers](../skills/godot-assets/references/pipelines.md) | assets-import-repair |
| godot-scenes | [Rename exported/animation paths without flattening instances](../skills/godot-scenes/references/refactoring.md) | scenes-refactor |
| godot-workflow | [Cross-system resource commands, HUD and repeated restart](../skills/godot-workflow/references/vertical-slice.md) | workflow-bounded-resource |

Animation also includes event-rig, and navigation includes directional links. Both playable examples test byte preservation for invalid/future saves and conflicting writes. The examples are original code; no Unity source or artist assets were copied.

## Evidence boundary

The [machine-readable current report](priority-skills-validation.json) records exact command templates, engine/platform, full-process classification and named assertions. Initial failed attempts are distinguished from final corrected runs. Historical reports remain historical. Runtime execution does not establish installed host model routing.

Foreign platforms/backends, arbitrary artist rigs, crowd-avoidance quality, physical audio/HDR, gamepad/accessibility, power-loss durability and cross-process save locking are not certified. Point sweeps do not establish finite-width or moving-target CCD. Imported wrapper/material preservation does not establish nested editable material overrides. Link graph checks do not establish physical jumping.

## Reproduction

Resolve GODOT, PLUGIN and fresh OUT to absolute paths. Use the standard 4.7.2 Windows console editor and create OUT before invocation:

```text
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/shared/scripts/run_checks.gd --log-file OUT/suite.log -- --manifest PLUGIN/tests/cases.json --out OUT/cases
python -X utf8 PLUGIN/tests/validate_structure.py --root PLUGIN --schema PLUGIN/artifacts/research/plugin.schema.json --report OUT/structure.json
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/package.gd --log-file OUT/package.log -- --root PLUGIN --out OUT/package
```

Schema validation uses the existing ignored research schema; it is not a clean-checkout dependency. The report records whether it was actually available. Source and installation archives are read back, their SHA256 values recorded, and the installation copy runs new task fixtures after relocation.

## Current result

53 manifest cases matched their expected outcomes: 42 normal passes, six intended failures, one intended timeout, two unsupported and two missing-toolchain controls. These eleven controls certify diagnosis/preflight, not the failed operation. Ten new fixtures and both games passed after package relocation. Structure/schema/link checks passed 1,456 checks. The final self-review found no remaining actionable findings after the recorded corrections.
