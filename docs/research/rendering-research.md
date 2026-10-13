# Rendering and performance research

Research dates: 2026-10-12 through 2026-10-13. Associated with issue #7. This document records research, not runtime validation. The rendering assignment is fully read; the repository-wide reading gate requires the main agent's combined inventory audit before Skill implementation.

## Source boundaries

The official English 4.7 documentation snapshot is `godotengine/godot-docs@9adca4c1c72917bfe1b7be3108abed5ce26696a6`. Per-page findings and hashes live in `page-reviews/render.json`. Context7 resolved `/godotengine/godot-docs/__branch__4.7`; one performance query returned a master RenderingServer excerpt, so its API claims require verification against the pinned class page and engine binding before implementation.

The [CPU rendering article](https://godotengine.org/article/rendering-cpu-optimizations/) was read in full. Its reusable lesson is a measured loop: reproduce a bottleneck, locate it, explain it, change one relevant cause, and measure again. Its Polygon2D mesh update and shader compiler allocator changes are engine implementation case studies, not instructions to call internal C++ functions from game scripts. Their speedups are not expected results for this repository. A benchmark must record hardware, driver, engine revision, workload, warmup, sampling and before/after frame times.

The [HDR announcement](https://godotengine.org/article/hdr-output-arrives-in-godot-4-7/) was read in full. It establishes platform, rendering-method and driver prerequisites. The article describes D3D12 as the default from 4.5, while the pinned 4.7 HDR tutorial says 4.6. Inspect actual project settings and active driver rather than inferring them from project age.

## Decisions for future recipes

Renderer selection is a capability and target-hardware decision. Forward+ supports advanced desktop effects; Mobile reduces base costs for simpler 3D and XR; Compatibility is the web/older-hardware route. Automatic fallback can change appearance, so acceptance must identify the active renderer and test the degraded appearance. Material sharing, automatic instancing and MultiMesh address draw submission; spatial partitioning preserves culling. Geometry merging or one world-sized MultiMesh can reduce CPU calls while increasing unnecessary GPU work.

Classify slow steady frames, intermittent stalls and loading delays separately. Lowering resolution is a controlled fill-rate hypothesis test, not proof that every graphics problem is GPU-bound. Profile scripts and engine rendering separately; server readbacks can introduce synchronization. Validate optimization behavior as well as timings. A worker must not mutate the active scene tree; transfer data, defer scene changes, coordinate shutdown and join it. NavigationServer queries and AStar objects have different thread guarantees.

HDR output differs from internal HDR scene buffers. The pinned [HDR tutorial](https://github.com/godotengine/godot-docs/blob/9adca4c1c72917bfe1b7be3108abed5ce26696a6/tutorials/rendering/hdr_output.rst) requires supported OS/display/driver plus Forward+ or Mobile; inspect all relevant Viewports and Windows, SDR-only Environment features and HDR 2D settings. Preserve scene lighting values and use appropriate tonemapping for lit content. Only direct unshaded presentation should scale highlights with display headroom. Re-read headroom on its change signal; a value of 1.0 alone does not establish SDR mode. The reference example needs a black-color guard before division and must preserve alpha.

Expose requested HDR, actual enabled state and support independently. Provide reset-to-system luminance defaults and persist settings with checked ConfigFile errors. Calibration requires a real HDR chain: supported OS, correct driver, HDR enabled, capable display, and visual inspection of clipping, ordinary UI, bright highlights, SDR fallback and monitor changes. Headless assertions and ordinary screenshots cannot certify HDR quality.

## Official demonstration research

Pinned `godotengine/godot-demo-projects@b761b4cd5718a7118f2c95eb55f181d0a5f004f1` (master; no 4.7 branch was returned). Local source is research-only under ignored `artifacts/research/deepening-demos`. The root MIT license was read; substantial copied code would require its notice. This work derives original procedures and does not package third-party assets.

Read `misc/hdr_output/max_color.gd` and `in_game_hdr_settings/in_game_hdr_settings.gd` in full. Useful practices are signal-driven display-headroom changes, linear color arithmetic with alpha restoration, system-default reset, user preference persistence, platform-specific calibration controls and separate effective-state queries. The demo is illustrative rather than a checked persistence implementation: load/save errors and malformed settings still need explicit treatment in our own recipe. Its black normalization division also needs guarding. Demo source compatibility and local HDR output have not been run.

## Current limitations

All 335 pages in `artifacts/research/deepening-render-assignment.json` were read in full and mapped in `page-reviews/render.json`, including low-frequency class references and their scope boundaries. Large references were read in complete sequential chunks with prose, API declarations and examples preserved; downloaded files and retrieval hits were not counted as reading. The final local audit found 335 read entries, zero missing assigned pages, zero cross-ledger duplicate paths and zero assignment-hash mismatches.

The audit ran in PowerShell by comparing the assignment paths and hashes against the rendering ledger and grouping paths across all `docs/research/page-reviews/*.json` ledgers. This is inventory validation, not a Godot runtime test. Exact script APIs, engine bindings, GPU behavior, device calibration and benchmark results remain unvalidated. HDR, native-window behavior, audio hardware, iOS signing/device delivery and OpenXR equipment were not tested by this research task.

Pinned prose is not uniformly correct. Findings identify contradictory HDR/renderer conditions, shader built-in and overload descriptions, window initial-position values, 2D physics notes referring to 3D backends, and broken mixed-language samples. For implementation, verify the specific conflicting claim against the pinned engine binding and a minimal actual call before reusing it. `PhysicsServer3DExtension` supplies signatures but no method descriptions; it is mapped as a custom native-backend boundary, without claiming an executable backend workflow.

## Additional main-assignment transfer

Completed all 25 fixed pages in `artifacts/research/main-transferred-render.json` after finishing the original 335-page rendering assignment. The render ledger now contains 360 full-page reviews. The final local audit found zero missing transfer pages, zero duplicate paths across all review ledgers, and zero render source-hash mismatches. This is a reading/mapping result, not runtime validation.

The transfer adds implementation-critical contracts for Object lifetime and deferred delivery, SceneTree scene changes and multiplayer setup order, Theme persistence and fallback lookup, font cache ownership, navigation path/avoidance separation, export-plugin cache invalidation and custom platform validation. Native physics backend and language-runtime extension surfaces remain source-backed research boundaries rather than promised execution recipes.

The OpenXR spatial entity tutorial was read completely, including both illustrations. Its examples contain invalid identifiers/types/signatures, reversed marker capability conditions, shared asynchronous future races and cleanup after a failed query. These findings require original corrected examples and hardware-specific validation before claiming a usable XR implementation. Anchor persistence, XR passthrough, native dialogs on other systems, platform signing and display/HDR quality remain untested in this research phase.

## Foundation transfer and source correction

Completed all 10 fixed foundation pages in `artifacts/research/foundation-transferred-render.json`. The render ledger now has 370 full-page reviews (335 original, 25 main transfers and 10 foundation transfers). The completed local audit found zero missing foundation transfers, zero duplicate paths across the ledgers and zero render source-hash mismatches. RichTextLabel and LineEdit reveal important draw/IME/focus and codepoint-versus-grapheme contracts; TileSet migration must preserve source/atlas/alternative identifiers and layer schema. Accessibility requires actual assistive-technology acceptance beyond backend support.

Reviewed `scene/main/window.cpp` from the local Godot 4.7.2 source around `Window::set_hdr_output_requested` and `_update_viewport_for_hdr_output`. The latter directly changes the RenderingServer buffer when stored HDR 2D is false; it does not call the Viewport property setter. Consequently the stored `use_hdr_2d` getter need not become true after an HDR output request, and neither getter value certifies successful HDR presentation. The ProjectSettings review was corrected accordingly; requested, supported and effective output remain separate acceptance checks.

The final foundation transfer of seven additional references is also fully read and mapped (`artifacts/research/foundation-final-transferred-render.json`), bringing this reviewer ledger to 377 pages. The local audit found all 7 transferred pages, no global duplicate paths and no render source-hash mismatches. Source-backed runtime boundaries are explicit for custom XR/physics providers and engine-owned RenderSceneBuffersRD. Spatial discovery matches any requested component while snapshot queries match all requested components; optional component handling must not accidentally remove entities. No Skill changes or runtime/device validation were performed by this research task.
