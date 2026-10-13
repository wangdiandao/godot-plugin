# Content and interaction implementation

中文概览：资源、2D/3D、物理、导航和动画六个入口增加完整开发/修改/诊断配方；本轮通过地形、场景资源隔离、接触/触发/查询、跨区域路径、动画读回与 root motion 的原生断言。复杂骨骼、避障运动及视觉外观保持对应目标环境验收，不能从这些测试计为通过。

Issue #7; implementation started after1596source+2generated reading gate. Fixed docs9adca4c1c72917bfe1b7be3108abed5ce26696a6, engine4.7.2official ed1daf0bf001b61586d9930840f2f1394092c079, Windows.

## Actual changes and results

- Six English recipe references contain explicit develop/modify/diagnose flows, implementation choices, source links and symptom/check/cause/fix/retest tables; entry routing and UI prompts point at these task boundaries.
- Animation now uncached reloads duration/path/key data and evaluates the loaded clip at0.75s. Nine assertions pass in `artifacts/deepening-content-initial/cases/1791877770-159-54924/animation-example/result.json`.
- Navigation adds two exact-edge polygons. Actual endpoint arrival succeeds across both; layer exclusion and region disabling fail arrival. Seven checks pass after synchronization correction in `artifacts/deepening-content-initial/cases/1791877824-39-50956/navigation-example/result.json`.
- Terrain fixture builds all16four-side variants, proves neighbor and empty-boundary peering metadata, saves/readbacks mode/cells, and converts transformed world/local coordinates. Ten checks pass under `artifacts/deepening-content-terrain`.
- Root motion advances a2m/s position clip by0.25s: extracted0.5m, target initially unchanged, one controller application, inactive-tree preservation. Four checks pass under `artifacts/deepening-content-rootmotion`.
- Physics fixture actually simulates contact and60px/s movement, casts expected floor/wrong-mask rays and receives one enter/exit trigger pair. Seven checks pass. 3D fixture verifies independent mesh sizes, camera and light readback; seven checks pass. Reports in `artifacts/deepening-content-initial/cases/1791878041-238-18800`.
- Asset integration creates source PNG32→64 and glTF mesh1→2width, imports each version in an editor process and checks dimensions in a new process, restores a missing source and preserves unrelated bytes. Seventeen parent checks pass under `artifacts/deepening-assets-check/unrestricted-fixture`.

## Commands and corrected failures

Commands used the task binary `artifacts/tooling/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe`. In the actual calls PLUGIN/OUT below were resolved absolute paths; these placeholders keep packaged evidence portable.

```text
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/shared/scripts/run_checks.gd --log-file OUT/suite.log -- --manifest PLUGIN/tests/cases.json --out OUT/cases --case animation-example,navigation-example
GODOT --headless --path PLUGIN/skills/godot-2d/assets/examples/terrain --script res://example.gd --log-file OUT/engine.log -- --out OUT
GODOT --headless --path PLUGIN/skills/godot-animation/assets/examples/root-motion --script res://example.gd --log-file OUT/engine.log -- --out OUT
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/integration/assets.gd --log-file OUT/engine.log -- --plugin PLUGIN --out OUT/fixture
```

The first parent launcher used a relative --script path under the host project and failed before cases ran; corrected absolute paths fixed that invocation. First two-region assertions exposed region/map readiness timing. Waiting for both expected closest owners fixed arrival, then guarding first map iteration removed an early-query error; the final exit0/error-free run is separate. Initial importer suite had user-directory permission errors in the sandbox; a fresh unrestricted run passed all17checks. Neither earlier failure counts as success. After independent UI discovery of backslash serialized-resource paths, all relevant fixture output arguments were normalized to forward slashes; final staged validation retests the current scripts.

## Untested scope

Artistic terrain seams and Camera2D adaptation captures; complex imported rigs/retargeting/modifier order; collision backends/devices other than this 2D fixture; moving-agent avoidance/links and dynamic-world bakes; skeleton root rotation/loops/blending and collision-aware root-motion integration; model/material visual parity and external Blender. Recipes provide complete target-specific checks, but these fixtures do not certify that scope.

Final staged content snapshot: 883 structure/schema/local-link checks passed; all eight selected native cases passed with clean logs and exit 0. Exact result: artifacts/content-pr-runtime/cases/1791879957-366-5404/report.json. The asset integration report has 17 actual parent checks, and the 3D fixture has 7; earlier draft counting was corrected against JSON evidence.
