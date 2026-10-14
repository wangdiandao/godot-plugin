# Validation report

**English** | [简体中文](validation.zh.md)

[Documentation](README.md) · [Testing](testing.md) · [Versioned evidence index](evidence.md)

The segmented 0.2.1 evidence added on 2026-10-13 is in [native-workflows-validation.json](native-workflows-validation.json): fault diagnosis/repair loops, localization catalogs and language refresh, native HTTP protocol/exit, and actual Chrome input with save restoration after reload. The 2026-10-11 results below remain historical records, not reruns for this batch. Other browsers, threaded/PWA builds, actual audio listening and installed-host implicit activation remain unverified.

For the host packaging added in 0.1.1 and development/release checks on 2026-10-12, see [compatibility.md](compatibility.md). The engine behavior evidence below is from 2026-10-11 and does not represent revalidation in every Agent.

Date: 2026-10-11. Engine: Godot **4.7.2.stable.official.ed1daf0bf**, standard Windows x86_64 release. GPU: NVIDIA GeForce RTX 5070 Laptop GPU, OpenGL Compatibility, driver 616.92. Logic uses headless; image tests use actual windows and rendering. Every pass combines logs, exit codes, explicit assertions and actual outputs.

## Completed behavior validation

| Group | Result and proven scope |
|---|---|
| Minimal examples for 18 Skills | All passed; precise scope recorded individually in the capability index |
| Core regression | All 31 cases passed after final source-package relocation, including two complete games, instancing/inheritance, actual screenshots and failure criteria |
| Complete desktop workflow | 21 checks passed: clean Chinese/space path → native import → scene checks → Windows release export → exported-output self-test |
| Native resource pipeline | 12 checks passed: PNG generation, import, reimport after resizing, source restoration and preservation of unrelated files |
| Template/build faults | 15 checks passed: wrong SHA256, repeated installation, overwrite conflicts, path traversal, missing templates and corrupt PNG |
| Native network download | HTTPRequest actually downloaded the complete official tpz; digest/version matched and ZIPReader extracted selected templates successfully |
| Multiplayer communication | Separate 1 server + 2 clients; loopback port, spawning, property replication, RPC acknowledgement and disconnect passed; final implementation passed six consecutive rounds |
| Installation relocation | 22 bundled example/game/rendering cases passed after extraction into a new directory |
| Structure and sources | 672 structure checks, official quick_validate checks for 18 Skills and 173 official-link checks passed |
| Web | HTML/JS/WASM/PCK build outputs exist; browser execution was not verified |

Machine-readable results are in [validation-results.json](validation-results.json), with capability mappings in [capabilities.json](capabilities.json). Summaries record only executed checks. Relative raw log/screenshot locations are in raw_report fields; originals live in the source workspace's artifacts directory. Installation packages exclude large engines and raw test outputs.

Complete-example tests start through GUI input. Arrow keys drive the physics character to collect the first item; test teleports trigger collisions for the remaining two. Checks cover victory, save readback, restart and a 960×540 screenshot. Audio checks inspect playback data/state rather than human listening.

## How failures are recognized

- A child that exits 0 and prints passed after injected `push_error` is classified as failed by the parent runner.
- Missing explicit results, parse errors, missing resources and save errors cannot pass normal cases.
- An infinite wait reaches a wall-clock deadline; only the PID launched by that case is terminated.
- headless capture returns unsupported; it cannot produce a fake screenshot or count as a visual pass.
- The save-failure case confirms the expected error and unchanged unrelated file content.
- Different existing template content is not overwritten; repeating the same installation preserves files; out-of-bounds paths are not written.
- Native import of a corrupt PNG exits **0** with error logs and is still correctly classified as failed.
- JSON reports quoting `ERROR:` text from handled negative cases contain data; log parsing matches real error records only, with regression tests to prevent missed actual errors.

A passing negative case means that the expected failure was correctly recognized, not that the failed operation succeeded. Unresolved issues are not hidden by removing assertions, clearing project caches or lowering acceptance requirements.

## Limits discovered and retained during research

1. `--editor --script` probes can access editor singletons but produce resource-leak logs on exit. This mode is not a reliable default capability; routine scripts use SceneTree and imports use native `--import`.
2. One corrupt SVG probe crashed the official Windows engine. Records remain in artifacts/failures-1; the release fault suite uses corrupt PNG to verify stable error criteria. This observation does not imply all SVGs are faulty or that the engine was repaired.
3. The sandbox initially blocked Godot from creating its user:// data directory, causing startup errors. Formal behavior tests ran in an authorized environment permitting normal engine user-data writes; those startup errors were not ignored and counted as passes.
4. LightmapGI.bake lacks a public binding and is unsupported under default constraints. Alternative lighting can be adopted only if it meets the user's visual requirements.

## Scope not recorded as passing runtime validation

Linux/macOS, Android/iOS, signing, Web browsers, public networking/NAT, multiple physics backends, AnimationTree skeletal blending, advanced GPU effects and performance optimization gains are not recorded as tested capabilities. Each Skill includes the corresponding official workflows and boundaries; actual tasks require further verification.

Each of the 18 Skills has positive, non-goal and adjacent requests. The responsibility boundaries of 54 requests were manually reviewed; this is not a host model selection accuracy test. The global plugin was not yet installed. Actual host automatic activation requires client/model conditions recorded after installation.

Both ZIPs passed per-file SHA256 readback. The final package updates validation summaries only after candidate-package testing. Maintenance tools check structure and packaging: manifest consistency, YAML frontmatter, default prompts, shared links, example entry points, fixed-version references, placeholders and ZIP readback. Final structure/relocation records are also machine-readable. Reproduction commands are in [authoring.md](authoring.md).
