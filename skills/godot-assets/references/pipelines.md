# Import settings, source repair and authored overrides

## Develop a reproducible pipeline

1. Inventory source files and external dependencies before launching import. For multi-file glTF, include referenced buffers/images; prefer GLB when a self-contained asset fits. Record source hashes and licenses.
2. Import in an isolated project using the actual engine. Inspect logs and the native .import sidecar; do not fabricate importer UID/cache entries.
3. Change only verified `params` keys in the generated sidecar. For texture mipmaps, set mipmaps/generate and preserve remap identity/importer plus unrelated settings. Consumer filtering is a separate decision.
4. Import again and check in a fresh process. Inspect resource type, dimensions and actual image mipmaps, not only the text option.
5. For a model, save a wrapper containing the imported instance plus authored gameplay nodes. Save independently authored materials as external resources. Reimport modified source geometry and verify changed mesh dimensions with unchanged wrapper/material bytes.

Copy [import-repair](../assets/examples/import-repair/project.godot) and run example.gd with native.md's command; allow a 120-second outer timeout. Each import/readback child has its own bounded timeout/log. The fixture creates a PNG and original glTF triangle under OUT/fixture, changes mipmap policy and model width, then removes/restores its own source. Outputs include importer files, wrapper.tscn, authored.tres, child logs and result.json.

The material in this fixture belongs to a separate authored node, not an editable nested override on an imported mesh. For that latter task, configure extraction or explicit editable-instance/import-script policy and validate the actual consumer separately.

## Modify other source types

| Source/task | Concrete sequence | Failure/acceptance |
|---|---|---|
| Font/CJK | License → FontFile load → packaged fallback → required glyphs → shaping/layout → export | Missing glyph control; real rendered target-font evidence |
| Audio import | Preserve WAV/OGG source → verified channel/rate/loop options → native reimport → loaded stream properties → audition | Corrupt source, loop edge and target-device listening |
| Multi-file glTF | Resolve each buffer/image URI relative to source → verify existence → import → traverse surfaces/bones/tracks | Missing dependency detected before import; restore only that file |
| Runtime external model | Verify module and append_from_file return → generate_scene → owners/wrapper → save/load | Invalid input rejection; imported content and references |

Do not add system font fallback or fabricated model parts to disguise a missing source. Route hearing to godot-audio, rig motion to godot-animation and rendered material acceptance to godot-rendering.

## Diagnose and repair

1. **Missing resource:** inspect original source/dependencies first. A surviving cache is not authority to reconstruct the artist file. Stop the dependent operation, restore the known source and import only the affected project/assets.
2. **Option appears changed, result unchanged:** inspect correct sidecar section, import log and actual loaded resource in a new process. Fix the key and reimport; avoid validating an already cached resource.
3. **Gameplay disappears after model update:** classify generated subtree versus wrapper and editable extracted data. Move authored behavior to the intended boundary, then reimport twice.
4. **Unexpected quality:** inspect semantic color/data maps, compression/mipmap policy and consumer filtering. Compare actual pixels or audio; dimensions alone do not establish fidelity.
5. **Dependency/tool absent:** report exact missing URI or external importer prerequisite. Prefer an available supported source format; do not silently download or invent replacement assets.

Retain original source/settings hashes and failure logs. Repair only the verified task-created source copy; never clear the entire project cache. Retest changed content, saved identity and neighboring authoring files independently.

Sources: [import process](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html), [3D import settings](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/advanced_import_settings.html), [FontFile](https://docs.godotengine.org/en/4.7/classes/class_fontfile.html), [fixed texture importer](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/editor/import/resource_importer_texture.cpp).
