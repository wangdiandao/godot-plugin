extends SceneTree
var checks: Array[Dictionary] = []
var output: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--out")
	if index < 0 or index + 1 >= args.size():
		push_error("OUTPUT_ARGUMENT_REQUIRED")
		quit(1)
		return
	output = args[index + 1].replace("\\", "/").simplify_path()
	if not output.is_absolute_path() or DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("OUTPUT_DIRECTORY_FAILED")
		quit(1)
		return
	call_deferred("_run")
func expect(value: bool, label: String) -> void:
	checks.append({"name": label, "status": "passed" if value else "failed"})
func finish() -> void:
	var passed := not checks.is_empty()
	for item: Dictionary in checks:
		passed = passed and item.status == "passed"
	var report := {"schema_version": 1, "status": "passed" if passed else "failed", "engine": Engine.get_version_info(), "platform": OS.get_name(), "display": DisplayServer.get_name(), "checks": checks, "artifacts": [output]}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	if file == null:
		push_error("REPORT_WRITE_FAILED")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(report))
	quit(0 if passed else 1)

func put(path: String, text: String) -> bool:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true
func execute(project: String, label: String, script: String = "", arguments: PackedStringArray = []) -> bool:
	var log := output.path_join(label + ".log")
	var flags: PackedStringArray = ["--headless","--path",project,"--log-file",log]
	if script.is_empty():
		flags.append("--import")
	else:
		flags.append_array(["--script",project.path_join(script),"--"])
		flags.append_array(arguments)
	var pid := OS.create_process(OS.get_executable_path(),flags,false)
	if pid <= 0:
		return false
	var deadline := Time.get_ticks_msec() + 20000
	while OS.is_process_running(pid) and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	if OS.is_process_running(pid):
		OS.kill(pid)
		return false
	var text := FileAccess.get_file_as_string(log)
	return OS.get_process_exit_code(pid) == 0 and not text.contains("ERROR:") and (script.is_empty() or text.contains('"status":"passed"'))
func model(width: float) -> Dictionary:
	var points := PackedFloat32Array([0,0,0,width,0,0,0,1,0]).to_byte_array()
	return {"asset":{"version":"2.0"},"buffers":[{"byteLength":points.size(),"uri":"data:application/octet-stream;base64,"+Marshalls.raw_to_base64(points)}],"bufferViews":[{"buffer":0,"byteLength":points.size(),"target":34962}],"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3","min":[0,0,0],"max":[width,1,0]}],"meshes":[{"primitives":[{"attributes":{"POSITION":0}}]}],"nodes":[{"mesh":0,"name":"Triangle"}],"scenes":[{"nodes":[0]}],"scene":0}
func _run() -> void:
	var project := output.path_join("fixture")
	expect(DirAccess.make_dir_recursive_absolute(project) == OK, "isolated_project_directory")
	expect(put(project.path_join("project.godot"), 'config_version=5\n[application]\nconfig/name="Import repair"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'), "fixture_configuration")
	expect(DirAccess.copy_absolute(ProjectSettings.globalize_path("res://check.gd"),project.path_join("check.gd")) == OK, "copy_resource_checker")
	var picture := Image.create(32,32,false,Image.FORMAT_RGBA8)
	picture.fill(Color.CORAL)
	expect(picture.save_png(project.path_join("art.png")) == OK and put(project.path_join("model.gltf"),JSON.stringify(model(1))), "source_assets_created")
	expect(await execute(project,"initial-import"), "native_import_creates_metadata")
	var settings := ConfigFile.new()
	expect(settings.load(project.path_join("art.png.import")) == OK, "native_sidecar_loaded")
	var uid: Variant = settings.get_value("remap","uid","")
	var importer: Variant = settings.get_value("remap","importer","")
	settings.set_value("params","mipmaps/generate",false)
	expect(settings.save(project.path_join("art.png.import")) == OK, "set_initial_mipmap_policy")
	expect(await execute(project,"no-mip-import") and await execute(project,"create-wrapper","check.gd",["1","false","create"]), "initial_loaded_resources_and_wrapper")
	var wrapper_hash := FileAccess.get_sha256(project.path_join("wrapper.tscn"))
	var material_hash := FileAccess.get_sha256(project.path_join("authored.tres"))
	settings.set_value("params","mipmaps/generate",true)
	expect(settings.save(project.path_join("art.png.import")) == OK, "change_only_mipmap_policy")
	expect(put(project.path_join("model.gltf"),JSON.stringify(model(2))), "model_source_modified")
	expect(await execute(project,"modified-import") and await execute(project,"modified-readback","check.gd",["2","true","verify"]), "new_process_observes_reimported_content")
	var reloaded := ConfigFile.new()
	expect(reloaded.load(project.path_join("art.png.import")) == OK and reloaded.get_value("remap","uid",null) == uid and reloaded.get_value("remap","importer",null) == importer, "reimport_preserves_identity_and_importer")
	expect(FileAccess.get_sha256(project.path_join("wrapper.tscn")) == wrapper_hash and FileAccess.get_sha256(project.path_join("authored.tres")) == material_hash, "reimport_preserves_authored_wrapper_and_material")
	var bytes := FileAccess.get_file_as_bytes(project.path_join("art.png"))
	expect(DirAccess.remove_absolute(project.path_join("art.png")) == OK and not FileAccess.file_exists(project.path_join("art.png")), "missing_source_preflight_blocks_import")
	var restored := FileAccess.open(project.path_join("art.png"),FileAccess.WRITE)
	restored.store_buffer(bytes)
	restored.close()
	expect(await execute(project,"repair-import") and await execute(project,"repair-readback","check.gd",["2","true","verify"]), "source_repair_repeats_valid_import")
	expect(FileAccess.get_sha256(project.path_join("wrapper.tscn")) == wrapper_hash, "repair_preserves_neighboring_authoring")
	finish()
