# Rendering/UI/audio/performance implementation evidence

Issue: #7. Branch: feat/7-skill-deepening. Implementation date: 2026-10-13. This report covers only godot-rendering, godot-ui, godot-audio and new godot-performance; the coordinating agent maintains global manifests, indexes, routing, packaging and PR delivery. The full reading gate was completed before these changes.

## Changes and task recipes

All four English entrypoints keep the six required sections and precise triggers, version/build prerequisites, implementation decisions, saving/recovery and observable acceptance. UI metadata follows those scopes with implicit invocation retained. Expanded native references provide develop/modify/diagnose flows, source-grounded API examples, task-specific decisions and symptom/check/cause/fix/retest tables.

- UI: new pause/HUD flow, inherited Theme/local variation edits, focus and pointer dispatch, logical scaling, licensed fonts/fallback, BiDi/IME/graphemes, rich-text shaping and assistive acceptance. The previous claim that the example created a Theme is now true: actual Theme font/size/color/StyleBox and PackedScene are saved, cache-ignored reloaded and effective inheritance/override removal asserted.
- Rendering: renderer/fallback decision, shader/material ownership and actual pixels, lighting/particle prerequisites, Viewport capture and advanced buffer boundary, full HDR prerequisites/calibration/SDR fallback. Window source behavior is accurately distinguished from the stored Viewport.use_hdr_2d getter.
- Audio: import/format choices, real player/bus mix lifecycle, persistent user volume, positional listeners, recording permissions and platform playback modes. Saved WAV/bus layout readback and completion replace start-only acceptance.
- Performance: fixed workload/timing scope, warmup/alternating before-after samples, equivalence guards, CPU/GPU/memory/stall diagnosis and actual project profiling procedure. Native engine allocator/mesh optimization article gains are not presented as game-script APIs or promised results.

## Environment and exact execution pattern

Local paths below substitute `PLUGIN` for the absolute workspace root used in the recorded commands. This keeps the shipped evidence portable; parameters and results are unchanged.

Executable: `PLUGIN/artifacts/tooling/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe`.
Actual version: `4.7.2.stable.official.ed1daf0bf`, full hash `ed1daf0bf001b61586d9930840f2f1394092c079`. Host Windows; CPU AMD Ryzen 9 8945HX. Rendering run: OpenGL 3.3 Compatibility, NVIDIA driver 616.92, RTX 5070 Laptop GPU. GPU execution used the permitted unrestricted tool run for normal driver-cache access; no cache deletion occurred.

Each run created a fresh directory and copied the example before execution. Actual PowerShell pattern (OUT below is the table's exact run directory):

```powershell
New-Item -ItemType Directory -Force -Path $out | Out-Null
Copy-Item -Path SOURCE/* -Destination $out
& artifacts/tooling/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path $out --script ($out+'/example.gd') --log-file ($out+'/engine.log') -- --out ($out+'/output')
```

The real GPU shader run omitted `--headless`. The final unsupported-condition run added `exit $LASTEXITCODE` to preserve native exit 2 through PowerShell. SOURCE and OUT values for the accepted current runs are:

| Case | SOURCE | OUT | Mode/result |
|---|---|---|---|
| UI example | skills/godot-ui/assets/examples/minimal | artifacts/deepening-render-implementation/ui-05 | Headless, exit 0, 15 checks passed, no engine error/warning |
| Audio example | skills/godot-audio/assets/examples/minimal | artifacts/deepening-render-implementation/audio-01 | Headless, exit 0, 12 checks passed |
| Shader example | skills/godot-rendering/assets/examples/minimal | artifacts/deepening-render-implementation/rendering-01 | Real GPU, exit 0, 7 checks passed |
| Shader unsupported condition | skills/godot-rendering/assets/examples/minimal | artifacts/deepening-render-implementation/rendering-headless-02 | Headless, native exit 2, unsupported real_rendering_required |
| 3D resource example | skills/godot-rendering/assets/examples/materials | artifacts/deepening-render-implementation/materials-01 | Headless, exit 0, 10 checks passed |
| Performance example | skills/godot-performance/assets/examples/minimal | artifacts/deepening-render-implementation/performance-02 | Headless, exit 0, 39 checks passed |

All relative paths in this table resolve under `PLUGIN`. Output logs and result.json are in the listed run/output directory except performance, which emits benchmark.json. Shader PNGs were opened and visually inspected as the expected uniform blue and red images, in addition to the center-pixel assertions. These captures certify only this simple shader path.

## Current assertion scope

UI checks persisted Theme, SystemFont identity and font size, effective inherited color/style, PackedScene creation, persisted local override and override-removal recovery. Keyboard action and pointer events use real dispatch. A STOP overlay blocks activation; IGNORE repairs it. Translation lookup and basic Container placement pass, independently of actual Chinese glyph rendering.

Audio checks WAV save and rate/channel/0.1-second duration readback; bus send/volume/effect readback, mute/unmute, absent bus lookup, start and nonlooping finished lifecycle. It restores the prior layout. Headless audio remains a state/resource test, not listening/DSP acceptance.

3D resource checks pack/save/reload, roughness and shadow flags, particle draw-color prerequisite, independent local material edit, modified scene save/reload. The deliberately changed prerequisite is a state check, not actual particle-color rendering; lighting/particle visuals remain untested.

Shader checks saved tint parameter, GPU pixel readback before and after independent duplicate modification, preserved original parameter and saved PNGs. It explicitly refuses headless rather than marking absence of GPU rendering successful.

Performance checks scene actor count, invalid-query guard, equivalent radii, updated position data and 31 paired checksums. The fixed static position snapshot is constructed outside timing. Snapshot stale-data policy is explained in the recipe.

## Initial performance result (before final query guards)

512 actors; 12 warmup pairs; 31 alternating sample pairs; 40 radius queries per sample; radius 30. CPU-only GDScript query over a fixed position snapshot, distance_to versus distance_squared_to. Scene initialization, snapshot creation, rendering and frame scheduling are excluded.

| Measurement | Baseline | Candidate |
|---|---:|---:|
| p50 microseconds/query | 12.100 | 12.125 |
| p95 microseconds/query | 13.225 | 13.775 |

No distinguishable speedup was demonstrated on this run; the candidate has a slightly worse observed tail. This result does not justify a whole-game optimization claim. Static-memory observations were 25,879,199 then 25,903,311 bytes while collecting sample/result data; this is neither a leak test nor GPU/process memory accounting. Raw samples remain in benchmark.json. Speedup is deliberately not the example pass criterion; equivalence and measurement integrity are.

## Failure investigation and self-review

The first UI Theme/input implementation passed 13 checks (`ui-01`). Adding the pointer diagnosis produced a failed repair assertion in `ui-02` and `ui-03`. An isolated trace (`ui-trace-01`) showed the root was only 64×64 with the button center at x=160, outside its area. Explicitly setting the root to 320×180 fixed pointer dispatch (`ui-04`), whose duplicate notify_mouse_entered warning was then removed by notifying headless entry once; `ui-05` passes all 15 with clean logs. Failed outputs were retained; assertions were not dropped.

The first shell unsupported run did not preserve native exit status through PowerShell; `rendering-headless-02` explicitly exits $LASTEXITCODE and confirmed native 2. This is expected unsupported detection, not a successful rendering operation.

Self-review corrections: removed a nonexistent accessibility tutorial link; separated low-level AccessibilityServer from actual active screen-reader acceptance; retained headless/GPU/audio boundaries; documented the 3D prerequisite test as state-only; removed universal improvement implications; preserved accurate per-Window HDR buffer versus stored getter behavior; checked all 4.7 documentation links against the pinned local page inventory.

Checks actually executed:

```text
git diff --check -- skills/godot-rendering skills/godot-ui skills/godot-audio
C:/Users/Lenovo/AppData/Local/Programs/Python/Python313/python.exe -X utf8 C:/Users/Lenovo/.codex/skills/.system/skill-creator/scripts/quick_validate.py skills/NAME
```

NAME was each of godot-rendering, godot-ui, godot-audio, godot-performance. All four returned `Skill is valid!`. Python emitted its known real-location warning but exited 0 and executed the validator. Owned Markdown relative links were checked with Test-Path: 0 failures. Versioned official URLs mapped to existing pinned .rst sources: 0 missing targets. Git diff check returned 0; LF/CRLF notices describe working-copy conversion, not whitespace errors.

This self-review does not replace the coordinating agent's final structural/integration/package and routing checks. No commits, PRs, merge or publication were performed by this subtask.

## Suggested central case and routing metadata

Keep existing ui-example/audio-example/rendering-example IDs and update their acceptance to the assertions above. Add:

- `rendering-materials-example`: godot-rendering, project/script under assets/examples/materials, headless true, --out {output}, timeout 30, expected passed. Condition: Godot 4.7.2 resource readback; explicitly exclude lighting/particle visuals.
- `performance-example`: godot-performance, project/script under assets/examples/minimal, headless true, --out {output}, timeout 30, expected passed. Condition: CPU equivalence and raw timing; no speedup assertion.
- Optional `rendering-headless-unsupported`: same minimal shader project, headless true, expected unsupported and reported_status unsupported. It verifies capability rejection, not pixel output.

Forward tasks for explicit invocation and natural-language routing, to be executed by the central harness rather than marked passed here:

| Skill | Develop | Modify | Diagnose |
|---|---|---|---|
| godot-rendering | Create a material scene compatible with the target renderer | Recolor one shared-shader instance and save/read back | Particle tint/fade is ignored; inspect process versus draw material |
| godot-ui | Build a keyboard-operated pause menu with inherited Theme | Add one Button style exception and prove inheritance recovery | An overlay blocks clicks or an IME edit does not update the model |
| godot-audio | Add validated Music/SFX buses and nonlooping playback | Persist volume/mute and preserve existing routes | Player is playing but silent on the requested platform |
| godot-performance | Establish a fixed-scene performance budget and baseline | Compare equivalent optimization and record no gain if appropriate | Determine whether steady cost, stalls or growing memory dominate |

Adjacent routes: new visual effect → rendering; measured renderer bottleneck → performance plus rendering implementation; missing localized glyphs → UI; missing import asset → assets; Web audio effect parity → audio plus export conditions. Explicit model invocation and implicit routing are not claimed tested by these native runs.

## Untested scope

Physical HDR calibration/luminance and SDR/HDR monitor switching; Forward+/Mobile shader parity; 3D lighting/particle appearance, stereo and advanced compositor effects; responsive screenshots across resolutions; packaged CJK/Arabic glyph shaping, screen readers, IME/native mobile keyboards; real listening, output latency, microphone/permission denial, headphones/surround and Web audio behavior; GPU/frame-pacing/whole-project optimization and external profilers; other OS/device exports. These require the documented environment-specific procedures and may not be counted as passed from headless assertions.

## Repository runner integration (current work)

The six isolated cases were subsequently executed through shared/scripts/run_checks.gd using the ignored manifest `artifacts/deepening-render-implementation/cases.json`. An initial launcher used a relative --script path under the host project and failed to find res://shared/scripts/run_checks.gd (`runner-01/suite.log`); no case executed in that attempt. Correcting to absolute paths produced a passing suite with all five positive cases plus expected headless unsupported detection, no child engine errors and native exits 0/2 as appropriate:

```powershell
& artifacts/tooling/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path PLUGIN/shared/host --script PLUGIN/shared/scripts/run_checks.gd --log-file PLUGIN/artifacts/deepening-render-implementation/runner-02/suite.log -- --manifest PLUGIN/artifacts/deepening-render-implementation/cases.json --out PLUGIN/artifacts/deepening-render-implementation/runner-02/cases
```

Report: `artifacts/deepening-render-implementation/runner-02/cases/1791878967-868-48296/report.json`. This confirms integration with the repository runner, rather than only standalone script execution. The real-GPU child ran with normal permitted shader-cache access. The first runner failure is retained separately from the successful rerun.

The runner's repeat performance sample has baseline/candidate p50 12.025/11.775 microseconds and p95 12.925/13.625 microseconds. Median direction changed relative to the first standalone run while the candidate tail stayed worse; these samples do not support a stable universal speedup claim. Both raw reports are retained and equivalence still passes.


## Final guard correction and current performance evidence

Self-review tightened the benchmark's failure condition: both query implementations now call valid_query and return -1 for invalid inputs, rather than merely testing a separate validation helper. Actual negative-radius/nonfinite calls are asserted as rejected. `performance-02` is the current script version with 39 passing checks. Its standalone baseline/candidate p50 is 12.950/12.675 microseconds and p95 is 15.400/14.575 microseconds.

Only the changed performance case needed a further runner execution; other case scripts were unchanged after runner-02. The exact runner-02 command was repeated with output/log under runner-03 and `--case performance-final`, using the manifest updated to performance-02. Report `artifacts/deepening-render-implementation/runner-03/cases/1791879091-622-45112/report.json` passes with no errors and exit 0; all 39 child assertions pass. Baseline/candidate p50 is 12.050/11.800 microseconds and p95 is 12.925/12.825 microseconds on this repeat. These modest observed differences apply to this CPU loop only; the earlier unguarded reports and final guarded reports are separate versions and not directly interchangeable evidence. No whole-frame/GPU or universal speedup is claimed.

Coordinator review corrected ORM wording: ORMMaterial3D channels are direct, while StandardMaterial3D's separate textures use scalar multipliers. Independent Windows backslash-path execution exposed broken external Theme serialization; example outputs now normalize slashes, and a fresh backslash OUT rerun passes all15 UI assertions with no errors. Final staged batch passes918 structure/schema/local-link checks and all six selected runner cases (five positive plus expected headless unsupported). Report: artifacts/render-pr-runtime/cases/1791880209-186-31672/report.json. Two missing fixed-source reference links and trailing config whitespace were corrected before these final checks.
