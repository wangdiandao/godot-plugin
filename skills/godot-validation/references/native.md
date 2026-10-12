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

Choose checks in increasing cost order: files/references → specified script parsing → native import → scene reload → actual behavior → input and real rendering → exported artifact launch. Each level proves only what it observes. Some Godot runtime and even import errors exit with code 0, so inspect logs, explicit results, timeouts, and output files together.

`run_checks.gd` reads cases.json; each case runs in a separate child process with a fresh output directory. Positive cases require a passed result. `require_report=false` is reserved for native import/export CLI operations; logs and exit codes are still checked, and extra assertions verify artifacts. Negative cases must anchor the failure reason with error_contains; arbitrary failure does not count as a passing negative test.

For performance investigations, first record the device, renderer, resolution, scene, warmup, and sampling duration. Sample current-version metrics such as TIME_PROCESS/TIME_PHYSICS_PROCESS, OBJECT_COUNT, and RENDER_TOTAL_DRAW_CALLS_IN_FRAME through Performance.get_monitor, comparing baseline and peak values under matching conditions. CPU timing is not GPU time, and an empty scene passing does not establish game frame rates. Check public interfaces when editor profiler data is required; do not promise CLI export of all editor panel data.

The source file tests/routing/prompts.json is a manual trigger review set; automated structure checks do not establish host model selection accuracy. Test semantic triggering separately after installation and record client and model versions.
