# Staged effects and dynamic popup rendering

## Develop and debug a shader

Break a visual goal into observable stages: coordinates/distance→mask/edge→combined shapes→color/texture→animation. Expose a debug stage and fixed phase so screenshots are repeatable; change one parameter and check affected pixels. Shader preview breakpoints in the target editor can inspect intermediate fragment values, but a preview is not a final-game renderer/platform test. Do not claim an editor UI operation is a public scripting API without checking its binding.

Separate authored materials from per-instance mutations; save parameters and reload uncached. Use source_color for color uniforms where required by the actual color pipeline. Record renderer, display mode, capture resolution and comparison tolerances. Capture after frame_post_draw, outside steady-state performance measurements.

## Dynamic UI and postprocessing

Embedded Windows render at layer 1024; an overlay at 1025 can draw above them. This applies to embedded windows in that Viewport. A separate native Window has its own Viewport and cannot be processed by merely raising the main Viewport's layer. For multiple Viewports, configure an effect/copy per intended Viewport. Preserve the user's chosen window mode.

Use hint_screen_texture and an explicit BackBufferCopy when earlier screen-reading effects would otherwise leave a stale copy. Decide whether HUD/popups should be affected; ensure a visual overlay uses IGNORE when it should not intercept input. Test opening, closing and reopening the actual OptionButton/Popup/ConfirmationDialog, keyboard and pointer input as well as pixels. A successful postprocess screenshot does not prove controls remain usable.

## Run the GPU fixture

Copy the [portal-popup project](../assets/examples/portal-popup/project.godot), create OUT and run with absolute paths:

```text
GODOT --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

It checks distance/mask/combined portal stages, fixed-phase parameter change, saved material readback, a dynamic embedded PopupPanel's red content excluded at layer100 and inverted to cyan at layer1025, and restored content after closing. PNGs include both the failed low-layer control and working high-layer result. Headless returns unsupported/2 with real_rendering_required. This tests Compatibility GPU pixels and embedded popup content; native windows, other renderers, real preview-breakpoint interaction and popup input are untested by this fixture.

Sources: [CanvasLayer](https://docs.godotengine.org/en/4.7/classes/class_canvaslayer.html), [screen-reading shaders](https://docs.godotengine.org/en/4.7/tutorials/shaders/screen-reading_shaders.html), [Viewport](https://docs.godotengine.org/en/4.7/classes/class_viewport.html). Community design: [GDQuest portal shader](https://www.gdquest.com/library/first_shader_godot4_portal/) and [preview debugging](https://www.gdquest.com/library/shader_preview_breakpoints/) (2026-09); [Shaggy Dev popup layering](https://shaggydev.com/2025/04/09/godot-ui-postprocessing-shaders/) (2025-04). Original simplified shaders avoid redistribution of tutorial assets/code.

Version evidence: [Godot 4.7.2 source](https://github.com/godotengine/godot/tree/ed1daf0bf001b61586d9930840f2f1394092c079). Recheck the actual target binary. Community discussions supply use cases; official contracts and runtime checks determine supported behavior.
