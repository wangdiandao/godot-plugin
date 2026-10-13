# Import, reimport and asset diagnosis

Use this guide for source-format or import-setting changes; [native.md](native.md) gives the executable invocation. Record source hashes, importer options, target renderer and output resource type before changing content. Imported caches are derived data, while `.import` files contain author intent.

## Develop: texture and model pipeline

1. Put licensed source files below `res://`, outside hidden directories. Choose PNG for lossless raster content, SVG for scalable illustrations, WAV/OGG for suitable sound sources and GLB for a self-contained model. Record external glTF image/buffer dependencies if using `.gltf` instead.
2. Run `GODOT --headless --path PROJECT --import` in an isolated project; wait for exit and read the import log. Run resource checks in a fresh process, so a previously loaded cache cannot hide stale import data.
3. For a UI texture, choose compression appropriate to fidelity and filter through the consumer; for 3D, assess VRAM compression, mipmaps and the actual platform formats. Lossy source compression and GPU compression solve different storage problems. Use normal-map import hints for normal maps; retain linear data for masks rather than treating them as display colors.
4. For a model, load the imported PackedScene and traverse MeshInstance3D, Skeleton3D and AnimationPlayer nodes. Record dimensions, material surfaces, bone names and animation paths. Create a wrapper scene with gameplay components outside the generated subtree. Keep mesh/material overrides in editable resources when repeated reimport is expected.
5. Save the wrapper, load it with CACHE_MODE_IGNORE and assert node paths, geometry dimensions and resource references. Render representative textures/materials on the intended renderer; successful loading alone proves neither appearance nor performance.

The minimal fixture checks PNG encoding, decoding, dimensions and pixel values. The asset integration test adds an actual importer roundtrip and source restoration. Neither is a font, audio listening or complex rig test.

## Modify: a texture or imported model without losing overrides

Copy only the source and associated settings into a task fixture first. Preserve `.import` sections other than the option being changed:

```gdscript
var settings := ConfigFile.new()
var error := settings.load(source_path + ".import")
if error == OK:
    settings.set_value("params", "mipmaps/generate", true)
    error = settings.save(source_path + ".import")
# Stop on any error; rerun native --import, then check in a new process.
```

For models, use the Advanced Import Settings resource extraction options deliberately. An extracted material remains independent of future source edits; verify that this is desired. Keep gameplay edits in a wrapper or inherited scene. Check each consumer after renaming a source node or bone, as NodePath animation targets and attachment sockets can break even when reimport exits successfully. Imported source data and authored overrides should each have a clear owner.

Reimport a changed source at the same path, verify its dimensions/animations changed, and verify the unrelated wrapper nodes and extracted resources did not. Do not clear the whole `.godot` directory as a repair. UID migration and moves require moving source and import metadata together through the editor or a verified reference update.

## Diagnose and retest

| Symptom | Check | Likely cause | Repair | Retest |
|---|---|---|---|---|
| Missing imported texture | Source exists, import log, resource type in fresh process | Source absent or importer failed | Restore this source/dependency and rerun import | Expected dimensions and unchanged neighboring files |
| Model loses script after reimport | Script placement and generated subtree ownership | Authored edit was inside generated content | Move behavior to wrapper/explicit import script | Reimport twice and reload wrapper |
| Black/incorrect normal map | Texture semantic, material normal input, tangent data | Color/data interpretation or missing tangents | Correct semantic and regenerate valid tangents | Render same light/view before and after |
| Pixel edges blur | Consumer filtering, mipmaps, viewport scale | Sampling configuration | Set relevant consumer/project policy | Native-size and scaled screenshots |
| `.blend` cannot import | Blender executable and supported version | External tool missing | Configure available Blender or accept GLB source | Import and verify actual mesh, not only file existence |

Sources: [Import process](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html), [3D import options](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/advanced_import_settings.html), [texture importer binding/options](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/editor/import/resource_importer_texture.cpp).
