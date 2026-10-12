# Asset Import: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [Image](https://docs.godotengine.org/en/4.7/classes/class_image.html)
- [ResourceLoader](https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html)
- [EditorFileSystem](https://docs.godotengine.org/en/4.7/classes/class_editorfilesystem.html)
- [GLTFDocument](https://docs.godotengine.org/en/4.7/classes/class_gltfdocument.html)
- [AudioStreamWAV](https://docs.godotengine.org/en/4.7/classes/class_audiostreamwav.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Place source assets in the project directory and run native --import to create real .import configuration before changing verified params fields.
2. Invoke native reimport; do not edit .godot/imported directly. Respect editor lifecycle requirements when EditorFileSystem is needed.
3. Generate task-appropriate basic assets with Image, GradientTexture, ArrayMesh, or AudioStreamWAV; do not require image or DCC tools unnecessarily.
4. Load imported resources with ResourceLoader.load using source paths, then check resource types, dimensions, or audio parameters.

## Saving and Validation

Commit source files, .import settings, and .uid files, not .godot caches. Keep stable external resource paths and avoid unintended recompression or source file overwrites.
The example generates a PNG and verifies image reload; integration tests invoke actual import and check texture loading, reimport after parameter changes, and missing source files.

## Common Pitfalls and Recovery

- Importing .blend files requires Blender and is not part of the Godot-only guaranteed workflow.
- Use ResourceLoader for imported project resources; raw FileAccess paths may not exist after export.

Distinguish corrupt source files, unsupported formats, and missing requirements when imports fail. Reimport affected resources first, at most twice; do not delete the entire project cache.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Native Import Pipeline

Place source files in an importable project directory. Run `--headless --path PROJECT --import`, wait for completion, inspect logs, then load with ResourceLoader in a fresh process. Read existing `.import` files with ConfigFile and change only target keys. For textures, inspect `compress/mode` and `mipmaps/generate` under `params`; use keys defined in the matching-version [texture importer source](https://github.com/godotengine/godot/blob/4.7.2-stable/editor/import/resource_importer_texture.cpp). Invoke native import again rather than inventing `.godot/imported` files or hashes.

Generate PNGs natively with Image.create/fill/save_png. RGBA8 quantizes colors: compare encoded pixel values on readback or allow one color-level tolerance. Use FontFile and project font resources, checking target character coverage. Save PCM audio with AudioStreamWAV. Prefer standard resource import for glTF/GLB; when runtime import is needed, verify GLTFDocument.append_from_file and generate_scene.

Automatic `.blend` import requires external Blender, outside the default Godot-only dependencies; do not pretend conversion is available when Blender is not installed. Prefer user-provided GLB/glTF or replaceable content made with Godot's native meshes. Report missing source files rather than fabricating source assets from caches. Successful texture loading does not prove correct materials, skeletons, or appearance; those require validation in their respective domains.

References: [Import process](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html), [Importing 3D scenes](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/index.html).
