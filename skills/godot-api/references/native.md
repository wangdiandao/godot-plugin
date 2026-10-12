# Official API Verification: Native Operations Reference

Baseline: Godot 4.7.2 standard editor distribution. Refer to the capability index and reports for the examples' actual validation status.

## Invocation Example

Copy this skill's `assets/examples/minimal/` into the task's temporary working directory. `GODOT`, `EXAMPLE`, and `OUT` denote absolute paths resolved by Codex before execution, not engine-provided variables. `OUT` should be a new isolated directory.

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

Create OUT first. In PowerShell, use `& $godot @args`; in POSIX shells, quote each path argument separately. Remove `--headless` for rendering examples. Include multiplayer child processes in test process management. Processes emit `GODOT_PLUGIN_RESULT:` JSON and exit explicitly. Errors or missing results must not count as success.

Inputs: scripts and native resources in the example. Outputs: generated resources and check reports in OUT; the engine may also generate the example's .godot cache and .uid metadata. Read the script before applying it to your own project; examples do not directly modify existing projects.

## Related APIs

- [ClassDB](https://docs.godotengine.org/en/4.7/classes/class_classdb.html)
- [Engine](https://docs.godotengine.org/en/4.7/classes/class_engine.html)
- [Object](https://docs.godotengine.org/en/4.7/classes/class_object.html)

Do not invent methods from class names. For specific signatures, run the shared `inspect_environment.gd -- --class CLASS --report OUT/api.json` or read the matching-version documentation above. Generate the complete API with `--dump-extension-api-with-docs` and write it to an isolated directory.

## Implementation Notes

1. Use inspect_environment.gd to query the target class's methods, properties, and signals; run native --dump-extension-api-with-docs when a complete cache is needed.
2. Read the relevant official documentation topic for the question. When Context7 is available, call resolve-library-id followed by query-docs; it is not a runtime dependency.
3. For editor capabilities, baking, and CLI lifecycle questions, inspect _bind_methods and call chains in the matching tag; do not treat internal C++ methods as script APIs.
4. Verify the target call with a minimal script; treat API existence, successful invocation, and correct behavior as separate evidence levels.

## Saving and Validation

Output only the API summary needed for the task. Store full API dumps in the validation directory rather than duplicating them in every skill.
Prove that required classes such as SceneTree exist, and confirm that LightmapGI.bake is unbound while VoxelGI.bake is bound; do not infer that the latter works on every GPU.

## Common Pitfalls and Recovery

- A method existing in ClassDB does not mean an editor singleton is available in a normal runtime context.
- An API dump is no substitute for GDScript compilation or runtime tests.

When versions differ, first switch to matching-version sources. If no public interface exists, report unsupported and assess existing native alternatives.

## Official Sources

- [CLI and build types](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Pinned source version](https://github.com/godotengine/godot/tree/4.7.2-stable)
- The API links above provide interface evidence; use actual examples to validate behavior. A call in source code does not imply a public binding.


## Evidence Verification Order

1. Run `GODOT --version` and `GODOT --help`; record the output files and actual binary.
2. Check method signatures, error codes, deprecations, and thread/rendering restrictions in class documentation for the matching major/minor version.
3. Confirm bindings with `ClassDB.class_has_method(class, method)` and inspect arguments with `class_get_method_list`. For singletons, also use `Engine.has_singleton`/`get_singleton` to verify availability in the current mode.
4. For disputed APIs, read `_bind_methods()` and the implementation at the same tag. Even C++ methods in public classes may lack script bindings.
5. Construct a minimal invocation and record inputs, return values, and actual effects, rather than checking only that a binding exists.

`--dump-extension-api-with-docs` is a CLI option in the standard editor distribution and writes to the current working directory; run it in an isolated directory. Local builds may omit modules, so a version number alone does not establish ENet, GLTF, or navigation support.

The 4.7.2 [LightmapGI binding source](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/lightmap_gi.cpp#L2122) comments out the bake binding; local ClassDB also returns false. Therefore, do not offer a `LightmapGI.bake()` script solution. Context7 can help locate information, but results from master or older versions must be checked against pinned-version sources; it is not a plugin runtime dependency.
