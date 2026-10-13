# Editor authoring recipes

Baseline: official 4.7 documentation, verified interfaces on 4.7.2. Execute tools in an isolated copy first. The bundled project contains an addon and a test Node, not a runtime SceneTree --script launcher.

## Develop a scene tool

Choose a preview script when a property should update only its own editor representation. Add `@tool`, check `Engine.is_editor_hint()` before preview work, and retain runtime behavior deliberately. Every helper whose instance methods run in the editor also needs tool support; GDScript subclasses do not inherit the annotation. In C#, use `[Tool]`, partial classes, and rebuild before enabling.

For a Resource-backed preview, emit `changed` when a meaningful setter change occurs. Disconnect the old Resource before replacing it, connect the new one once, and rebuild preview state. Mutating an array element does not invoke the property's assignment setter: provide an explicit mutation method or issue the change notification yourself. Avoid adding an editor process loop to regenerate an unchanged preview every frame.

For persistent creation, select the intended edited scene root and verify the target parent belongs to that scene. Add a new node, then assign its owner to the edited root. An unowned child may appear while the editor runs but disappear from the saved scene. Do not use an imported subscene's internal child as a writable composition root. Set `EditorInterface.mark_scene_as_unsaved()` for deliberate direct edits, or integrate undo as below. Preview-only generated nodes should remain intentionally unowned and be rebuilt without persisting unintended children.

## Develop a dock with transactional edits

Use the bundled `addons/recipe/plugin.gd` as a complete small implementation. It creates EditorDock, stable layout_key and child content on tree entry; removes the dock before queue_free on exit. Close/hide is not destruction. Borrowed editor controls must not be freed. Register importers, inspectors, menu callbacks and gizmos with corresponding removal methods. Plugin project activation callbacks are distinct from tree lifetime: autoload configuration belongs to `_enable_plugin`/`_disable_plugin`.

The `add_marker(scene)` recipe uses the real manager API: object + method name, not UndoRedo Callable overloads. It creates a scene-context action, adds child then owner as do operations, retains a do-reference for lifetime, and removes child on undo. For deleting a node, invert those operations and retain an undo-reference. For property edits, capture old values and add do/undo properties. Batch one user command into one action; use merge only when repeated gestures intentionally form one undo step. External Resources generally select global history unless a suitable explicit context is supplied.

Acceptance command after copying the whole project to EXAMPLE:

```text
GODOT --headless --editor --path EXAMPLE --log-file OUT/editor.log -- --self-test --out OUT
```

The plugin creates the test Node under the normal editor MainLoop. Do not launch this Node with `--script`. The test waits for scanning/edited-scene readiness, checks one plugin/dock, do/undo/redo and ownership, saves `res://saved_recipe.tscn`, reloads uncached, and disables/re-enables twice. This file and editor state changes are why EXAMPLE must be a disposable copy. In 4.7.2, an alternative custom `--editor --script` SceneTree left queued dock frees and editor shutdown resources unflushed; that failed mode is not this acceptance path.

For visual acceptance, run without headless, inspect the dock in its intended slot and floating layout, resize, Tab focus, keyboard activation and disabled state. Activate a transaction through the UI, undo/redo through editor shortcuts and reopen the saved scene. This needs a real editor window; programmatic headless checks do not prove layout or accessibility.

## Modify an Inspector or importer

Before changing an addon, list its registrations and user-visible state. EditorInspectorPlugin should accept only intended object types, insert controls through the correct parse callback and use EditorProperty emission/undo integration instead of writing properties on every redraw. Keep controls' value display separate from command execution and disconnect object/Resource signals when editing a different target.

For an EditorImportPlugin, define unique importer name, recognized extensions, options and output resource extension. Return the actual Error from loading/saving and populate platform variants/generated files when used. Change import options in a disposable fixture, reimport and inspect generated Resource contents plus references; resource file existence alone cannot prove content. Never overwrite an artist source file with imported output. For export plugins, pair registration, make cache invalidation depend on options/version when necessary, and test the final exported pack rather than only editor callbacks.

## Diagnose and retest

| Symptom | Check | Likely cause | Fix | Retest |
|---|---|---|---|---|
| Script does nothing in editor | Annotation, inherited helper, mode and compiler | Non-tool helper or stale managed assembly | Annotate executing helper/build; guard runtime path | Change exported input and observe one preview update |
| Node disappears on reopen | owner, scene path, save error | Transient unowned child or wrong scene root | Assign intended owner via transaction, save | Uncached reload and reopen scene |
| Undo edits another scene | First operation/context/history | Wrong inferred undo context | Supply actual edited root; capture old values | Two open scenes, undo independently |
| Duplicate UI after activation | Registrations and exit callbacks | Missing removal/disconnection | Pair each registration and free owned controls | Two full enable/disable cycles |
| Infinite tool updates | Setter/changed recursion and process loop | Regeneration changes its own source | Guard equality/re-entry, regenerate from source | Unchanged frame stays stable; changed source updates once |
| Dock queued but never deleted in automation | Actual MainLoop and shutdown log | Custom editor --script harness | Use normal editor + addon-driven test | Assert object invalid after flush; inspect full log |

Sources: [EditorPlugin](https://docs.godotengine.org/en/4.7/classes/class_editorplugin.html), [EditorDock](https://docs.godotengine.org/en/4.7/classes/class_editordock.html), [editor undo manager](https://docs.godotengine.org/en/4.7/classes/class_editorundoredomanager.html), [tool scripts](https://docs.godotengine.org/en/4.7/tutorials/plugins/running_code_in_the_editor.html), [import plugins](https://docs.godotengine.org/en/4.7/tutorials/plugins/editor/import_plugins.html). These workflows use public bindings; engine editor internals remain diagnostic source evidence.


Engine binding/lifecycle reference: [fixed 4.7.2 source](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/editor/plugins/editor_plugin.cpp). Compare generated bindings and actual execution with this revision; internal implementation alone is not a callable scripting API.
