# Rendering and Effects: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [Shader](https://docs.godotengine.org/en/4.7/classes/class_shader.html)
- [ShaderMaterial](https://docs.godotengine.org/en/4.7/classes/class_shadermaterial.html)
- [WorldEnvironment](https://docs.godotengine.org/en/4.7/classes/class_worldenvironment.html)
- [RenderingServer](https://docs.godotengine.org/en/4.7/classes/class_renderingserver.html)
- [Viewport](https://docs.godotengine.org/en/4.7/classes/class_viewport.html)
- [GPUParticles3D](https://docs.godotengine.org/en/4.7/classes/class_gpuparticles3d.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Choose native materials or ShaderMaterial; do not reimplement a complete shading model when built-in materials suffice.
2. Configure lights, environment, and particle resources; identify support requirements for Compatibility/Mobile/Forward+.
3. Render an object using the shader in a real rendering mode, capturing logs and frame images; inspect the visual result even when compilation reports no errors.
4. Before optimizing, record comparable scenes, resolutions, and metrics; do not draw GPU performance conclusions from headless FPS.

## Saving and Validation

Save materials, shaders, and environment resources separately; inspect usage before changing shared materials. Write screenshots and measurements to a hidden validation directory.
The example shader renders in a real window, reads back the image, and verifies known colors; headless execution must return unsupported.

## Common Pitfalls and Recovery

- LightmapGI.bake has no public binding in 4.7.2; do not bypass this with internal editor buttons.
- Wait for frame_post_draw before taking screenshots; do not capture immediately in _ready.

Locate shader errors in compilation logs and retest; report GPU limitations instead of silently removing requested effects.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Rendering Modes and Visual Acceptance

Record Compatibility/Mobile/Forward+ and the actual GPU driver first. After assigning ShaderMaterial.shader = Shader, set code with the matching shader_type; `set_shader_parameter(name, value)` names must match uniforms. CanvasItem shaders, spatial shaders, and compute use different pipelines; compute requires RenderingDevice, and Compatibility does not provide equivalent capabilities.

Wait at least several process_frame events and RenderingServer.frame_post_draw before calling Viewport.get_texture().get_image(). Check compilation logs, pixels/image dimensions, and key regions; a headless pass is not GPU acceptance. Allow sufficient time for particles to advance. Fix seeds for random effects and compare reasonable ranges rather than demanding pixel-perfect equality.

Choose scene lighting, WorldEnvironment, shadows, and post-processing using the selected renderer's official feature matrix. LightmapGI's internal bake is not exposed to scripts; this plugin does not implement it through hidden editor buttons, private methods, or invented APIs. Assess official alternatives such as dynamic lighting while preserving the user's visual goals.

References: [Renderer differences](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html), [Shading language](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html).
