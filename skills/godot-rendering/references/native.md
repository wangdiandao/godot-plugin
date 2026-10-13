# Rendering recipes and diagnostics (Godot 4.7)

Choose renderer/material, shader modification, lighting, particles, Viewport capture or HDR. Versioned [rendering manual](https://docs.godotengine.org/en/4.7/tutorials/rendering/index.html) and [4.7.2 source](https://github.com/godotengine/godot/tree/4.7.2-stable) are the baseline. Use ClassDB/native minimal calls when a binding differs; internal engine optimizations are not script API recipes.

## Isolated shader acceptance

Copy `assets/examples/minimal/` to a clean directory; create OUT and run with a real display/GPU:

```text
GODOT --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

The Compatibility example saves a ShaderMaterial, cache-ignored reloads a tint parameter, renders and asserts the center pixel, duplicates the material for a local recolor, asserts the original did not change, then captures changed pixels. Outputs are material, two PNGs and result.json. Headless exits unsupported; initialization or a saved shader file is not proof of pixels. Real GPU cache access may require the execution environment's normal permissions; do not erase user caches to bypass failures.

## Develop a renderer-compatible scene

1. Confirm minimum platforms/devices and required features. Choose Forward+ for advanced desktop 3D, Mobile for a lower base-cost RenderingDevice path, or Compatibility for Web/older hardware. Do not assume a preset implies the active method: log RenderingServer.get_current_rendering_method/get_current_rendering_driver_name and DisplayServer.get_name after startup/fallback.
2. Create a small Node3D scene with Camera3D, one mesh, DirectionalLight3D and WorldEnvironment. Set Camera current and mesh normals/tangents before diagnosing material appearance. Use saved StandardMaterial3D or ORMMaterial3D; BaseMaterial3D is abstract. Establish exposure/sky/environment before adding effect complexity.
3. Assign one material and imported texture at a time. Separate linear data maps from albedo color encoding. ORMMaterial3D uses occlusion R, roughness G and metallic B directly. StandardMaterial3D's separate roughness and metallic textures multiply the corresponding scalar values; changing those scalars is not an ORM-channel repair. Normal maps need tangents, use the expected positive-Y convention and regenerate normals/tangents for procedural surfaces.
4. Add intended lights/shadows and quality settings, then test target renderer fallback in a clean copy. Unsupported effects need a deliberate visual alternative, not an invisible successful property assignment.
5. Save resources and scene with correct owners, reload CACHE_MODE_IGNORE and inspect material references. Capture after frame_post_draw at target resolution. Compare reference appearance, depth, shadow behavior and error logs before adopting the scene.

[Standard/ORM material](https://docs.godotengine.org/en/4.7/tutorials/3d/standard_material_3d.html), [BaseMaterial3D](https://docs.godotengine.org/en/4.7/classes/class_basematerial3d.html), [renderers](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html).

## Modify materials and shaders

Inspect MeshInstance3D material_override, surface overrides, imported embedded materials and material_overlay/next_pass. Shared material mutation changes every user. For an instance exception duplicate the intended resource; shader code may remain shared while ShaderMaterial parameter storage is independent. Use set_instance_shader_parameter only for declared supported instance uniforms; names are case-sensitive. Do not duplicate an entire scene merely to change one uniform.

Canvas shader example:

```glsl
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
void fragment() { COLOR *= tint; }
```

Retaining texture/vertex color is different from replacing COLOR with a constant, as the isolated pixel test deliberately does. Spatial shaders use ALBEDO, ROUGHNESS, METALLIC and optional ALPHA; writing ALPHA can move the material to transparent rendering even when its value is one. Choose render_mode and shader type from the actual rendering stage. Shader resource.code is source, while material uniforms are values; save/read back both. ClassDB cannot validate GLSL compilation, so render the shader on each relevant backend.

Prefer opaque where possible. Alpha blend sorts and costs overdraw and may disable shadow casting. Scissor/hash or alpha depth prepass support different depth/shadow tradeoffs and suit cutouts/hair. depth_draw_always does not automatically add transparent objects to the depth prepass. Refraction samples opaque screen content, so transparent objects cannot refract one another through that path. [Shader language](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html), [Canvas shaders](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/canvas_item_shader.html), [spatial shaders](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html).

For outlines, growth/next-pass requires sensible normals and can gap at sharp corners. Stencil presets own next_pass and replace manual changes on reload; material_overlay is the safer extra material when using a stencil preset. Parallax is disabled with UV1 triplanar; deep parallax and three-way triplanar reads must be justified by visible benefit. set_flag takes one enum at a time, not OR combinations.

## Lighting and particles recipe

For lighting, isolate missing illumination from missing shadows. Check light cull masks, material unshaded/receive-shadow flags, world environment, range and camera. Emission makes a surface bright but does not automatically light the whole scene; appropriate GI baking/participation is required. Shadow atlas resolution/subdivision trades per-light precision against count; a zero positional atlas disables omni/spot shadows. Compare bias/acne with actual mesh scale and normals before blindly increasing resolution. Physical light units and camera exposure need a consistent pipeline. [Lights and shadows](https://docs.godotengine.org/en/4.7/tutorials/3d/lights_and_shadows.html).

For particles, choose GPUParticles for supported GPU simulation or CPUParticles for the target capability and count. Assign a draw mesh/material separately from ParticleProcessMaterial. Enable vertex-color albedo or consume COLOR in a custom shader; alpha fading also requires ALPHA and the chosen transparency mode. Configure lifetime, amount, direction, emission shape and curves, then generate bounds across a full effect cycle. A one-frame capture_aabb misses later particles. Small visibility AABBs cause disappearing effects and limit collisions; 2D GPU particles use LightOccluder2D SDF, not normal physics body collision shapes.

One-shot effects use restart for retriggering and finished for lifecycle cleanup; continuously emitting particles do not finish. Flipbooks require particle billboard mode, frame grid and positive animation speed. GPU trails require a skinned RibbonTrailMesh/TubeTrailMesh and trail material flag; the flag breaks ordinary mesh rendering. Fixed seeds improve reproducible testing but do not guarantee CPU/GPU parity across platforms. Local coordinates follow the emitter; world coordinates leave old particles behind. [Particles](https://docs.godotengine.org/en/4.7/tutorials/3d/particles/index.html), [ParticleProcessMaterial](https://docs.godotengine.org/en/4.7/classes/class_particleprocessmaterial.html).

## Viewport/capture and resolution modification

Use Window or SubViewport, never abstract Viewport. Select shared/own worlds, active cameras/listeners and actual texture presentation. A SubViewportContainer handles input mapping; TextureRect or 3D textured UI needs explicit local coordinate conversion and notify_mouse_entered/exited. Do not mix GUI visibility with physics-picking order; picking has a nondeterministic 64-candidate limit even before sorting.

Await RenderingServer.frame_post_draw before get_texture().get_image, check save_png Error and inspect pixels. HDR 2D textures are linear RGBA16; convert encoding appropriately for ordinary SDR PNG output. Capture is a GPU readback and should remain outside performance sampling. Transparent backgrounds disable SSR, subsurface scattering and depth of field. Scale only the 3D buffer when keeping UI crisp; FSR2 at native resolution still performs temporal AA. MetalFX needs actual Metal driver support and temporal scale limits. [Viewport](https://docs.godotengine.org/en/4.7/classes/class_viewport.html).

## Implement HDR with an SDR fallback

The [HDR article](https://godotengine.org/article/hdr-output-arrives-in-godot-4-7/) establishes output support and artistic workflow. The [4.7 HDR tutorial](https://docs.godotengine.org/en/4.7/tutorials/rendering/hdr_output.html) is the version-matched procedure. HDR scene buffers and HDR display presentation are different.

1. Establish engine/build, HDR-capable display, enabled OS HDR and current window display. Godot 4.7 supports Windows with D3D12, Apple supported systems with appropriate Metal/Vulkan path, and Linux Wayland with Vulkan; Compatibility, Android, Web and Linux X11 do not support HDR output. iOS requires Metal. The pinned tutorial flags older GNOME Wayland HDR behavior; verify the actual compositor/version. Use the actual DisplayServer after fallback, not a requested driver string. CLI uses --display-driver, despite a conflicting Wayland tutorial flag.
2. Use Forward+ or Mobile. Review every Environment: Filmic/ACES tonemapping, Soft Light glow blend and color correction adjustments are SDR-only. Choose a supported tonemapping path; retain authored scene intensities rather than multiplying lit materials by display headroom.
3. Enable rendering/viewport/hdr_2d for the main configuration, use_hdr_2d on HDR content SubViewports and hdr_output_requested on each Window. Source precision: Window::_update_viewport_for_hdr_output directly sets the RS buffer when stored HDR2D is false; it need not make the Viewport getter true. That getter is not evidence of display HDR success. [Window source](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/main/window.cpp).
4. Expose requested, supported and effective enabled state separately using Window/DisplayServer. Preserve SDR usability if unsupported, monitor changes or system settings disable HDR. Query headroom on output_max_linear_value_changed; a value of one alone does not prove SDR.
5. Provide optional reference-white and maximum-luminance calibration using DisplayServer.window_set_hdr_output_reference_luminance/window_set_hdr_output_max_luminance in nits. Use negative values to restore system defaults. Distinguish configured from current luminance getters. Validate finite positive user overrides, save checked ConfigFile preferences and avoid applying a display-specific calibration blindly to another display.
6. Show neutral UI, black/gray ramps and bright highlights on the physical display. Tune clipping/reference white relative to OS calibration and viewing environment, then test window movement between SDR/HDR screens, toggle HDR off, restart and restore defaults. Preserve normal UI contrast and alpha compositing.

For direct unshaded HDR swatches only, map maximum RGB in linear space without destroying alpha:

```gdscript
func highlight_color(srgb: Color, headroom: float) -> Color:
    var linear := srgb.srgb_to_linear()
    var peak := maxf(linear.r, maxf(linear.g, linear.b))
    if peak > 0.0:
        var factor := maxf(1.0, headroom) / peak
        linear.r *= factor
        linear.g *= factor
        linear.b *= factor
    return linear.linear_to_srgb() # Alpha remains unchanged.
```

This helper is not an exposure rule for lit objects. Use only valid current headroom and a presentation path whose color contract expects the returned encoding. The full recipe is currently not physically HDR-validated; headless checks and PNG captures cannot certify luminance or calibration. [DisplayServer HDR methods](https://docs.godotengine.org/en/4.7/classes/class_displayserver.html).

## Diagnosis: symptom → check → cause → fix → retest

| Symptom | Check | Cause and fix | Retest |
|---|---|---|---|
| Black viewport | Camera/current, size/update mode, world, first draw | Undrawn buffer or wrong world; activate correct path and await post-draw | Saved PNG pixel/content assertion |
| Normal map darkens surface | Tangents/normals, import Y convention | Missing basis or encoding; regenerate/reimport correct data | Rotating light and camera on target renderer |
| Material recolor affects neighbors | Resource sharing and override scopes | Shared mutation; duplicate parameter resource or instance uniform | Original and modified instances plus save/readback |
| Transparent surfaces pop/order wrong | ALPHA use, blend, depth mode, bounds | Transparent sorting/overdraw; choose cutout/prepass or redesign layers | Multiple camera angles and shadows |
| Particle color/fade ignored | Draw material COLOR and ALPHA, transparency | Process colors not consumed; enable draw-material path | Entire cycle and one-shot restart |
| Particle vanishes offscreen | Full-cycle AABB, SDF oversize | Bounds/collision coverage too small; regenerate valid bounds | Moving camera/emitter and collision edges |
| HDR toggle yields SDR | Effective backend/display, support/enabled, OS HDR | Unsupported path or fallback; preserve SDR and select supported backend | Physical HDR chain and monitor switch |
| HDR UI washed out | Encoding, exposure, headroom use | Double conversion or global multiplier; fix only intended presentation stage | SDR/HDR UI comparison and alpha |

## Acceptance boundaries and low-frequency APIs

Record effective renderer/driver, resource readback, real pixels, error logs and quality constraints. GPU pixel checks prove the selected shader path only; lights, trails, HDR and stereo require specific scenes/environment. CompositorEffect/RenderSceneBuffersRD is an advanced on-demand route: buffers are engine-owned, valid during rendering, named custom contexts are cached and can survive mismatched creation definitions. Never instantiate internal render buffers or clear the default render_buffers context. [CompositorEffect](https://docs.godotengine.org/en/4.7/classes/class_compositoreffect.html), [RenderSceneBuffersRD](https://docs.godotengine.org/en/4.7/classes/class_renderscenebuffersrd.html).

## Additional material/scene persistence example

For a headless resource contract check, copy `assets/examples/materials/` and run the same command with --headless. It saves a Camera3D/DirectionalLight3D/BoxMesh/StandardMaterial3D/CPUParticles3D scene, reloads uncached, checks light/material/particle settings, duplicates a local material change and saves/reloads the modified scene. Its draw-color prerequisite check inspects material state; it does not prove actual particle color or light/shadow appearance. Use the separate real-GPU minimal example for shader pixel validation, and render the 3D scene to accept lighting and particles.
