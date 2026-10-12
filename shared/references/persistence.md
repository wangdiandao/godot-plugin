# File and Resource Persistence

## Choose the Smallest Operation

Read files and callers first. Use minimal text diffs for small property changes in existing scenes and official APIs for complex new resources. Do not regenerate everything to hide a lack of understanding of inheritance, instances, UIDs, or custom resources.

Record affected file contents or hashes before making changes. Validate complex changes on copies. Restore only this operation's changes, and stop overwriting if the current file no longer matches what this operation wrote. Do not use a repository-wide reset, directory wipe, or project recreation to recover from one failure.

## Scenes and Connections

After add_child, assign the correct owner to nodes that must be saved. Ownership expresses scene membership; do not point every internal instance node's owner at the outer root. Persistent connections need named methods, valid targets, and CONNECT_PERSIST. Check pack's Error before saving, then ResourceSaver's Error, and reload afterward.

Reload checks must cover at least key node types, properties, persistent connections, and resource dependencies. File existence or crash-free instantiation alone does not prove integrity. Check existing instances and inheritance using both SceneState and file diffs.

## UIDs and Importing

Preserve .gd.uid files, UIDs in .tscn/.tres, and .import settings beside source files. When renaming resources, check references and related metadata together. ResourceSaver UID generation differs between runtime and editor; do not invent uid:// strings. Establish caches through native import/editor maintenance.

Do not edit .godot/imported or uid_cache manually. Import new source assets first and reimport affected files after changing import settings. Continue loading imported images by source path through ResourceLoader.load after changing their content.

## Player Data and Artifacts

Write game saves to user://, not the read-only exported res://. Validation examples explicitly use isolated paths and do not touch real player saves. Put test resources, screenshots, and logs in .godot-plugin or the specified artifact directory; do not use an all-files export include_filter that bundles them into the game.

Sources: [PackedScene](https://docs.godotengine.org/en/4.7/classes/class_packedscene.html), [ResourceSaver](https://docs.godotengine.org/en/4.7/classes/class_resourcesaver.html), [ResourceUID](https://docs.godotengine.org/en/4.7/classes/class_resourceuid.html), [Importing](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html), [Scene serialization source](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/resources/packed_scene.cpp).
