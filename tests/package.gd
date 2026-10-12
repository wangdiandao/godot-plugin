extends SceneTree
const Common = preload("../shared/scripts/common.gd")
var files: Array[String] = []
var result: Dictionary
var source: String

func _initialize() -> void:
	call_deferred("_run")

func collect(relative: String) -> void:
	var directory := DirAccess.open(source.path_join(relative))
	if directory == null:
		Common.check(result, "directory:" + relative, false)
		return
	for name: String in directory.get_files():
		if directory.is_link(name) or name.ends_with(".tmp") or name.ends_with(".pyc"):
			continue
		files.append(relative.path_join(name))
	for name: String in directory.get_directories():
		if name in [".godot", ".godot-plugin", "__pycache__", "artifacts", "dist", ".git"] or directory.is_link(name):
			continue
		collect(relative.path_join(name))

func archive(path: String, manifest: Dictionary) -> void:
	if FileAccess.file_exists(path):
		Common.check(result, "archive_must_be_new", false, path)
		return
	var packer := ZIPPacker.new()
	if packer.open(path) != OK:
		Common.check(result, "open_archive", false, path)
		return
	files.sort()
	for relative: String in files:
		var name: String = str(manifest.name).path_join(relative)
		var error := packer.start_file(name)
		if error == OK:
			error = packer.write_file(FileAccess.get_file_as_bytes(source.path_join(relative)))
		if error == OK:
			error = packer.close_file()
		Common.check(result, "zip:" + relative, error == OK)
	packer.close()
	var reader := ZIPReader.new()
	Common.check(result, "reopen_archive", reader.open(path) == OK)
	var file_count := 0
	for member: String in reader.get_files():
		if not member.ends_with("/"):
			file_count += 1
	Common.check(result, "member_count", file_count == files.size())
	for relative: String in files:
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(reader.read_file(str(manifest.name).path_join(relative)))
		Common.check(result, "readback:" + relative, hash.finish().hex_encode() == FileAccess.get_sha256(source.path_join(relative)))
	reader.close()
	result.artifacts.append({"path": path, "sha256": FileAccess.get_sha256(path), "files": files.size()})

func _run() -> void:
	result = Common.report("package")
	var args := Common.arguments()
	if not args.has_all(["root", "out"]):
		Common.check(result, "arguments", false, "--root PLUGIN --out NEW_OUTPUT_DIRECTORY")
		Common.finish(self, result)
		return
	source = Common.absolute(str(args.root))
	var output := Common.absolute(str(args.out))
	DirAccess.make_dir_recursive_absolute(output)
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(source.path_join("plugin.json")))
	if not manifest is Dictionary:
		Common.check(result, "manifest", false)
		Common.finish(self, result)
		return
	files = ["plugin.json", "README.md", "LICENSE", "AGENTS.md", "CONTRIBUTING.md"]
	for directory: String in [".codex-plugin", ".agents/plugins", "skills", "shared", "docs"]:
		collect(directory)
	if result.status != "passed":
		Common.finish(self, result)
		return
	var stem: String = "%s-%s" % [manifest.name, manifest.version]
	archive(output.path_join(stem + ".zip"), manifest)
	collect("tests")
	collect(".github")
	files.append(".gitignore")
	archive(output.path_join(stem + "-source.zip"), manifest)
	Common.finish(self, result, output.path_join("package-report.json"))
