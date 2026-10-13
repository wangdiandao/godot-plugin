# Validation and Diagnostics: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [Logger](https://docs.godotengine.org/en/4.7/classes/class_logger.html)
- [OS](https://docs.godotengine.org/en/4.7/classes/class_os.html)
- [Input](https://docs.godotengine.org/en/4.7/classes/class_input.html)
- [Performance](https://docs.godotengine.org/en/4.7/classes/class_performance.html)
- [SceneTree](https://docs.godotengine.org/en/4.7/classes/class_scenetree.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Select the necessary parsing, import, resource loading, behavior, and rendering checks in order; --check-only covers only the specified script's parsing.
2. Run cases.json with run_checks.gd; child processes emit explicit results, while the parent also checks logs and exit codes.
3. Verify events with Input.parse_input_event and polled input through action state; assert observable state instead of passing after a fixed delay.
4. Failure cases must match the expected cause; rendering checks must inspect actual screenshots, and performance results must record the measurement environment.

## Saving and Validation

Keep tests and reports in .godot-plugin or the specified output directory, outside release packages. Terminate only processes started by the current test.
The example verifies that real failures are detected; the test runner itself must cover errors printed with exit code 0, missing results, and timeouts.

## Common Pitfalls and Recovery

- Parent process logs cover errors before Logger registration and during shutdown; child reports do not cover the entire process lifecycle.
- The official distribution's --test option is not a test framework for user games.

Timeouts, missing results, and error logs are failures. Rerun affected cases after recovery and preserve the original failure evidence.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Evidence Levels

## Develop a repeatable check

Write an observable contract first: input, setup/lifecycle, state/side effect, persistence and failure condition. A health bar task should prove damage changes health, updates display and handles zero health; instantiating a scene alone is insufficient. For modifying an existing module, snapshot the relevant saved file/hash, reproduce current behavior, change one cause, run affected behavior and uncached readback. Do not delete assertions or broaden an expected error to obtain a pass.

A positive child needs a structured passed report, zero exit, no startup/runtime/shutdown errors and expected artifacts. A report cannot cover errors before logger initialization. ResourceSaver success followed by cached ResourceLoader reuse does not verify serialization; use CACHE_MODE_IGNORE or a fresh process and compare required stored fields. For input, synthesize an event through Input.parse_input_event and verify actual dispatch state; polled actions need action_press/action_release and separate tests. Device UX still requires the real device.

The minimal example generates intentionally broken scripts only inside OUT/fixtures, launches the current executable, bounds each child to 2.5 seconds and kills only that child on timeout. Cases are parse error, missing Resource path with exit0, runtime array bounds error that remains running, push_error with exit0, silent timeout, missing report and unrelated error. Expected text is matched independently of generic failure; an arbitrary failure cannot pass a negative test. Each observation records log, exit and timeout. Runtime fault detection can legitimately require killing a child after its matched error, but timeout alone is insufficient for that case.

## Diagnose from symptoms

| Symptom | Check | Cause | Fix | Retest |
|---|---|---|---|---|
| Parser fails before any report | Complete log, actual specified script and dependencies | Syntax/type/constant path error | Fix first diagnostic in intended source | --check-only followed by actual behavior |
| Import succeeds by exit but asset absent | Import logs, artifact/UID and source path | Invalid source/unsupported importer | Correct source/options, reimport affected resource | Load artifact and assert its content |
| Resource reload unchanged | Cache mode and stored properties | Same cached object or transient field | Save correct storage field, uncached reload | Independent instance/readback comparison |
| Assertion never reaches result | Wall-clock, await lifecycle and fatal log | Dead await/runtime error/early return | Bound readiness and emit explicit failure | Intended error matched; healthy case completes |
| Test reports passed but engine errors | Outer log including startup/shutdown | Child report does not cover lifecycle | Fix cause and rerun complete process | Clean log plus structured report |
| Failure test passes for wrong reason | Expected diagnostic and setup artifacts | Broad any-error acceptance | Anchor cause and prove preconditions | Unrelated fault must fail expected matcher |

## Performance, visual and host evidence

Fix workload, scene, renderer, hardware/driver, resolution, warmup, sample interval and duration before comparing results. Preserve baseline and changed samples, use CPU/GPU/retained-memory metrics for their actual meanings and avoid frame timing while synchronous readback or debug overhead differs. Report distributions and scene correctness, not just best FPS. A faster incorrect simulation is not an accepted optimization.

GPU screenshots after frame_post_draw can verify pixels for a known scene, but screenshots alone cannot certify HDR chain, audio quality or device input. Actual HDR enabled/support/headroom, calibration and monitor changes need a real display; audio mix/state needs a listening/device check when sound quality matters. Record such conditions as untested rather than substituting headless success.

Skill routing test cases must include develop, modify and diagnose prompts and adjacent/non-target prompts. Structure/manual routing review is not actual model selection. Record host/model/version and explicit versus natural-language invocation outcomes separately, including resulting files and runtime evidence.

Choose checks in increasing cost order: files/references → specified script parsing → native import → scene reload → actual behavior → input and real rendering → exported artifact launch. Each level proves only what it observes. Some Godot runtime and even import errors exit with code 0, so inspect logs, explicit results, timeouts, and output files together.

`run_checks.gd` reads cases.json; each case runs in a separate child process with a fresh output directory. Positive cases require a passed result. `require_report=false` is reserved for native import/export CLI operations; logs and exit codes are still checked, and extra assertions verify artifacts. Negative cases must anchor the failure reason with error_contains; arbitrary failure does not count as a passing negative test.

For performance investigations, first record the device, renderer, resolution, scene, warmup, and sampling duration. Sample current-version metrics such as TIME_PROCESS/TIME_PHYSICS_PROCESS, OBJECT_COUNT, and RENDER_TOTAL_DRAW_CALLS_IN_FRAME through Performance.get_monitor, comparing baseline and peak values under matching conditions. CPU timing is not GPU time, and an empty scene passing does not establish game frame rates. Check public interfaces when editor profiler data is required; do not promise CLI export of all editor panel data.

The source file tests/routing/prompts.json is a manual trigger review set; automated structure checks do not establish host model selection accuracy. Test semantic triggering separately after installation and record client and model versions.
