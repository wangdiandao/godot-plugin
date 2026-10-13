# Performance recipes (Godot 4.7)

For Web, first establish a functional browser baseline with the [native Web acceptance workflow](../../godot-export/references/web.md). Measure real transferred bytes, navigation-to-interactive time and repeatable frame tails separately from export success or script initialization timings. Retain cold/warm cache and before/after input, save and visual equivalence.

Use this reference for CPU radius-query changes, rendering costs, memory growth, loading spikes and frame pacing. API baseline is the [4.7 manual](https://docs.godotengine.org/en/4.7/tutorials/performance/index.html); implementation checks use [4.7.2 source](https://github.com/godotengine/godot/tree/4.7.2-stable). Context7 retrieval can return master snippets even under a versioned ID; verify those against this baseline and ClassDB before use.

## Run the isolated comparison

Copy `assets/examples/minimal/` to a clean task directory. Create OUT, then run:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

The script builds 512 Node3D actors with fixed deterministic positions, takes a position snapshot outside timing, warms both queries 12 times, then runs 31 paired samples of 40 queries each, alternating order. Baseline uses distance_to; candidate uses distance_squared_to with a squared radius. It verifies equal counts at multiple radii, modified data, finite input guards and equal per-sample checksums. `benchmark.json` preserves raw microseconds, p50/p95, CPU/engine/renderer/driver and static-memory readings. No speed threshold is asserted: timer noise and GDScript loop overhead can erase the expected arithmetic gain.

Pass means equivalent behavior and usable measurement, not a faster whole game. Timing excludes initialization, snapshot construction, rendering and frame scheduling. If an actor moves, rebuild/update the snapshot outside both measurements; stale data is a correctness bug. Negative radii must be rejected because squaring would otherwise change their meaning. Huge/nonfinite radii need application-specific bounds.

## Develop a measured feature

1. Define observable workload: actor count, AI update frequency, raycasts, draw calls, audio voices or UI content. Set a user-facing budget in milliseconds and memory bytes, not only FPS.
2. Implement the simplest behaviorally correct feature and minimal stress scene. Include correctness assertions and deterministic inputs. Use a release export for final representative timings while keeping a debug run for error diagnosis.
3. Measure only the intended region with Time.get_ticks_usec; batch enough work to exceed clock granularity and keep prints, construction and result serialization outside timing. Record baseline raw samples after warmup.
4. Use the script profiler to find hot functions. Reduce repeated queries/conversions, exploit squared distances, bound search scope or distribute noncritical work over frames only when the feature's latency budget permits. Caching needs an explicit invalidation condition; moving work to a worker still requires safe data ownership and joining on shutdown.
5. Retest identical workload, correctness and user-visible latency. Compare medians and tail cost; reject a change that improves mean cost while introducing unacceptable spikes. Save both code/configuration revisions and measurement parameters.

[CPU optimization](https://docs.godotengine.org/en/4.7/tutorials/performance/cpu_optimization.html) explains timer-based profiling. The [rendering CPU article](https://godotengine.org/article/rendering-cpu-optimizations/) illustrates measuring native allocation/mesh-update causes; its internal fixes and speedups are not public script APIs or promised application gains.

## Modify an existing slow scene

Start from the user's symptom and budget, preserving behavior and quality. Capture an export replay or fixed camera route. Record renderer, resolution, quality, VSync/max_fps, physics tick rate, debug overlays, editor remote inspector and power mode. Make one diagnostic intervention at a time:

- Lower only 3D resolution: improvement suggests pixel/post-processing cost; unchanged cost points toward geometry, submission, scripts or a cap. This is a hypothesis test, not conclusive GPU proof.
- Disable one expensive shadow/effect or substitute a simple material: retest pixels/quality and timing. A shader readback can itself stall the GPU; do not put capture calls inside steady-state timing.
- Replace per-instance updates with shared material/instance uniforms, static geometry or spatially partitioned MultiMesh when appropriate. One giant MultiMesh can destroy culling. Smaller partitions may trade extra calls for less invisible geometry.
- Bound AI/navigation requests and cache stable results; never replace connected-region navigation acceptance with merely receiving a path array.

Profile all drawn viewports and shadows. Where actual bindings support it:

```gdscript
var viewport_rid = get_viewport().get_viewport_rid()
RenderingServer.viewport_set_measure_render_time(viewport_rid, true)
# Read after rendering has warmed up; these are milliseconds, not microseconds.
var cpu_ms = RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid)
var gpu_ms = RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
```

Zero can mean unavailable or measurement disabled; it is not a zero-cost GPU. Render CPU timing excludes script/physics/audio work. Sum relevant viewport render CPU plus get_frame_setup_time_cpu for render submission; keep script/engine subsystem readings separate. GPU values can lag and change with GPU power state under caps. Query active renderer/driver and available device timestamp support; Compatibility/headless behavior does not imply RenderingDevice measurements are available. Use the built-in visual profiler or an appropriate native GPU profiler for target hardware. [RenderingServer](https://docs.godotengine.org/en/4.7/classes/class_renderingserver.html), [GPU optimization](https://docs.godotengine.org/en/4.7/tutorials/performance/gpu_optimization.html).

## Memory and loading recipe

Record static memory, object/resource/node counts before opening a level, after stabilization, after closing it and after repeated cycles. Performance monitors are observations, not complete process/GPU memory accounting. Distinguish retained useful caches from monotonically growing references. Track textures, meshes, audio decoded PCM and font glyph caches separately; a saved resource path is not evidence it unloaded.

Inspect reference cycles, signal/lambda captures, retained arrays, Autoload caches, orphan Nodes, worker futures and RID ownership. Nodes need queue_free/free according to context; RefCounted cycles need broken references; server-created RIDs need the owning server cleanup; engine-owned render buffers must not be manually freed. Apply one lifecycle fix, rerun repeated open/close cycles and verify gameplay still works. Do not demand exact memory return to baseline when the allocator legitimately retains capacity. [Performance](https://docs.godotengine.org/en/4.7/classes/class_performance.html), [thread safety](https://docs.godotengine.org/en/4.7/tutorials/performance/thread_safe_apis.html).

For startup/loading stalls, separate import, ResourceLoader load, instantiation, shader compilation and first rendered use. Threaded loading requires load_threaded_get_status polling and a successful result before load_threaded_get; calling get early blocks. Warmup can move stalls rather than eliminate them, so measure cold and warm launch separately and preserve representative target assets. Engine pipeline cache toggles do not disable GPU-driver caches. Do not clear unknown user caches.

## Diagnosis: symptom → check → cause → fix → retest

| Symptom | Check | Likely cause and fix | Retest |
|---|---|---|---|
| FPS fixed despite optimization | VSync, max_fps, monitor refresh, export overhead | Cap hides cost; measure subsystem time or temporarily uncapped isolated run | Same workload and power state, restore product cap |
| CPU spike while capture/profiling | GPU readbacks, print rate, remote scene tree | Measurement perturbs workload; move captures out and lower instrumentation | Instrumented versus uninstrumented trace |
| Slow transparent particles | Screen coverage, depth/blend mode, active particle count | Overdraw/sorting; limit covered pixels, choose scissor/hash where appearance permits | Same effect duration, pixel evidence and GPU tail time |
| Worse after MultiMesh/merging | Bounds, view count, visibility | Lost per-object culling; partition spatially | Full camera route, draw calls plus GPU time |
| Navigation grows CPU | Query rate, disconnected target, polygon caps | Repeated expensive search; fix graph and bound/reuse requests | Reachable/unreachable targets and actor motion |
| Memory grows after level exit | Orphans, strong cycles, RIDs, cache retention | Missing ownership cleanup; repair precise owner lifecycle | Repeated level cycles and object/resource counts |
| Jitter with good mean FPS | p95, physics/update alignment, allocations and streaming | Pacing/stalls; fix burst work and interpolation teleport reset | Tail frame time and movement, not only average FPS |

## Acceptance and honest reporting

Report configuration, raw samples, code revisions, equivalence assertions, p50/p95 and measurement scope. A faster loop is not a faster frame; a lower memory monitor is not proof of lower GPU allocation. Keep hardware-dependent visual/GPU/frame-pacing tests marked untested until measured. If no improvement is distinguishable from noise, retain or revert the candidate on maintainability grounds and say so. The example is a benchmark method demonstration, not a universal recommendation to rewrite every distance call.
