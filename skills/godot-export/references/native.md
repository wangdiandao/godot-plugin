# Builds and Exports: Native Operations Reference

For actual Web serving, browser input/storage acceptance and startup diagnosis, read [web.md](web.md); it uses a temporary native Godot HTTP helper without adding a runtime dependency.

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [EditorExportPlatform](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatform.html)
- [EditorExportPlatformWindows](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformwindows.html)
- [EditorExportPlatformWeb](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformweb.html)
- [ZIPReader](https://docs.godotengine.org/en/4.7/classes/class_zipreader.html)
- [HTTPRequest](https://docs.godotengine.org/en/4.7/classes/class_httprequest.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Use prepare_templates.gd to download official release templates or accept a verified local TPZ, then extract the required templates into the specified directory.
2. Create or update existing export presets; point custom template paths to matching-version files and verify options against the current platform API.
3. Run native import first, then --headless --export-debug or --export-release; create the output directory beforehand and match the preset name exactly.
4. Inspect export logs, executables, and data packs, and launch the native target. Record Web packaging success separately from browser runtime validation.

## Saving and Validation

Modify only the target preset and preserve others; do not write credentials into public examples or validation logs. Package template caches, test reports, and source code separately.
Select acceptance for the requested target. Preset serialization alone is configuration evidence. With --templates the minimal example performs actual Windows import, export and artifact launch. The desktop integration covers both game examples and Web packaging; browser/device/signing checks remain separate. Reject failed template verification before extraction.

## Develop and modify an export pipeline

Inspect project.godot, target language, renderer, plugins and export_presets.cfg before creating a preset. Preserve unrelated presets and per-developer credentials. Pick exact platform/architecture and matching engine build templates; managed projects require .NET-capable templates, standard templates cannot execute C#. GDExtension packages need every target library and permitted dependencies. Debug and release artifacts must be built independently.

For a new desktop preset, populate name/platform, runnable, export_filter, include_filter and exclude_filter explicitly; inspect valid option keys with the editor export platform and a saved preset rather than guessing a key. Start with all_resources for a prototype, then selected-resource exports plus explicit include filters for non-resource runtime data. Exclude toolchain downloads, test outputs and secrets. Runtime dynamically assembled paths can evade dependency discovery; list and test them in the exported pack.

Import first, then export to a new directory with the exact preset name. Require exit/log/actual output checks together. The minimal optional build command is:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT --templates TEMPLATES
```

It creates an isolated export_project inside OUT, checks version.txt=4.7.2.stable and the release template, serializes a preset, imports, exports Windows executable plus PCK, and launches the artifact headless. The exported Node writes its engine/version and editor=false report. It does not inspect pixels or certify branding/signing. Without --templates, only the three configuration assertions run. Do not describe those as a binary build pass.

When modifying a release preset, compare the original configuration/hash and output dependency list, change only intended keys, rebuild in a new directory and launch with fresh user data. `res://` inside an exported pack is generally read-only; saves belong under `user://` or a user-approved external path, with checked file errors. An exported application should create its output directory before writing and handle permission/full-disk failures. Test save/reload in the exported executable, not only the editor. Do not assume the editor's user:// directory is the shipped game's directory.

## Platform and signing conditions

| Target | Required decision/condition | Acceptance |
|---|---|---|
| Windows | Matching x86_64/arm64 templates, native dependency ABI, icon/resource editor and signing if requested | Launch final executable/pack; inspect logs, resources, save/readback and optional signature |
| Web | Compatibility renderer, WebGL2/browser support; thread preset and cross-origin headers; C# unavailable | Serve over HTTP/HTTPS, open actual browser, inspect console/loading/input/audio; packaging alone is not runtime |
| Android | Actual JDK/SDK, signing keystore, permissions/architecture; managed platform requirements | Install signed build on device, suspend/resume and save; do not publish credentials |
| iOS | macOS/Xcode, signing/provisioning, device/simulator constraints | Build/install on intended device and test lifecycle; cannot infer from Windows export |
| macOS/Linux | Host/cross-build limits, architectures, dependencies, signing/notarization where applicable | Actual target launch after moving package away from build machine paths |

Never write signing keys, passwords or absolute private paths into public examples/logs. An executable hash verifies the observed artifact, not trust or store approval. Publication is outside a local-build request unless explicitly authorized.

## Diagnose and retest

| Symptom | Check | Cause | Fix | Retest |
|---|---|---|---|---|
| Export exits0 but errors printed | Full export log and output size/files | Godot error path returns0 | Resolve exact config/template error | Fresh export with clean log and artifact launch |
| Works in editor but missing in build | Export filter, dynamic path, case and included files | Dependency omitted or platform case sensitivity | Explicit include/resource reference and correct case | Final pack loads resource through actual path |
| Game cannot save | res:// versus user://, directory/error code | Packed resource write or restricted location | Writable user path and error handling | Exported save/readback plus permission negative case |
| C# or extension fails on target | Template type, assemblies/DLL tags/dependencies | Wrong build/runtime or omitted library | Matching language template/target dependency | Actual exported target startup and method call |
| Web pack built but blank | Browser console, HTTP headers and renderer | Unsupported API or incorrect thread isolation | Compatible preset/server headers | Real browser loading/input and console |
| Signing missing/invalid | Signing tool, certificate/provisioning and artifact | Toolchain/account prerequisite absent | Configure authorized credential path locally | Verify resulting signature/device install |

## Common Pitfalls and Recovery

- --export-pack exports data only, not a standalone executable game.
- Godot templates do not replace required Android/iOS SDKs and signing.

Prepare missing templates automatically; report blocked for missing SDKs, signing, or host platform requirements. Running the project in the editor is not a substitute for a failed executable export.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Official Template Preparation and Complete Builds

`prepare_templates.gd` uses native HTTPRequest, ZIPReader, and SHA256. It retrieves release assets and digests from the same official GitHub tag, or accepts a verified local TPZ; it extracts only explicitly listed template files and version.txt. Report blocked if the network or official digest is unavailable, and refuse to overwrite existing differing content. Templates go into the task directory and are referenced through custom_template/debug and custom_template/release in export_presets.cfg; manual editor configuration is not required.

```text
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/shared/scripts/prepare_templates.gd --log-file OUT/templates.log -- --download --dest OUT/templates --files windows_debug_x86_64.exe,windows_release_x86_64.exe --report OUT/templates.json
GODOT --headless --path PROJECT --import --log-file OUT/import.log
GODOT --headless --path PROJECT --export-release "Windows Desktop" OUT/game.exe --log-file OUT/export.log
```

Presets must at least set name, platform, export_filter, include_filter, and exclude_filter, and select architecture and actual templates. Write `include_filter=""` even when no include filter is needed; otherwise 4.7.2 emits a ConfigFile error but may return 0. Source: [Export preset loading](https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export.cpp#L378). For Windows examples without branding customization requirements, set application/modify_resources=false to avoid requiring rcedit; this does not complete signing or custom icon setup.

Create export directories first; relative export paths resolve against the project directory. `--export-pack` produces only PCK/ZIP data, not a standalone game. Run the artifact's own self-test in a separate process afterward, check its version, logs, and screenshots, and ensure helper directories are excluded from the PCK.

A successful Web build does not establish browser compatibility; verify with an HTTP server and an actual browser, checking threads, WebGL2, and cross-origin isolation against the preset. Android still requires the officially specified JDK/SDK; iOS requires macOS/Xcode and signing. The plugin can discover and configure installed components, but cannot promise these platform prerequisites come with the standard Godot package. References: [Android export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html), [iOS export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html), [Web export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html).
