extends SceneTree
const Common = preload("common.gd")
var result: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func _fetch(url: String, destination: String = "") -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = 600.0
	request.use_threads = true
	request.download_file = destination
	root.add_child(request)
	var start: Error = request.request(url, ["User-Agent: godot-plugin/0.1.0", "Accept: application/vnd.github+json"])
	if start != OK:
		request.queue_free()
		return {"ok": false, "error": error_string(start)}
	var response: Array = await request.request_completed
	request.queue_free()
	return {"ok": response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200, "response_code": response[1], "body": response[3]}

func _run() -> void:
	var args: Dictionary = Common.arguments()
	result = Common.report("prepare_templates")
	if args.has("_error") or not args.has("dest") or not args.has("files"):
		Common.check(result, "arguments", false, "Required: --dest DIR --files NAME,NAME; either --archive TPZ --sha256 HASH or --download")
		Common.finish(self, result)
		return
	var engine: Dictionary = Engine.get_version_info()
	var version: String = "%d.%d" % [engine.major, engine.minor]
	if engine.patch > 0:
		version += ".%d" % engine.patch
	var tag: String = version + "-" + str(engine.status)
	var dest: String = Common.absolute(str(args.dest))
	var archive: String = Common.absolute(str(args.get("archive", dest.path_join("../downloads/" + tag + ".tpz"))))
	var expected_hash: String = str(args.get("sha256", "")).to_lower()
	if args.has("download"):
		var metadata: Dictionary = await _fetch("https://api.github.com/repos/godotengine/godot/releases/tags/" + tag)
		if not metadata.ok:
			result.status = "blocked"
			result.reason = "Official release metadata unavailable; provide a verified local --archive and --sha256."
			Common.finish(self, result, str(args.get("report", "")))
			return
		var release: Variant = JSON.parse_string((metadata.body as PackedByteArray).get_string_from_utf8())
		var url: String = ""
		if release is Dictionary:
			for asset: Dictionary in release.get("assets", []):
				if asset.get("name") == "Godot_v" + tag + "_export_templates.tpz":
					url = str(asset.get("browser_download_url", ""))
					expected_hash = str(asset.get("digest", "")).trim_prefix("sha256:")
		if not url.begins_with("https://github.com/godotengine/godot/releases/download/" + tag + "/") or expected_hash.length() != 64:
			result.status = "blocked"
			result.reason = "Official release did not supply a recognized asset and SHA256 digest."
			Common.finish(self, result, str(args.get("report", "")))
			return
		if not FileAccess.file_exists(archive) or FileAccess.get_sha256(archive) != expected_hash:
			DirAccess.make_dir_recursive_absolute(archive.get_base_dir())
			var download: Dictionary = await _fetch(url, archive + ".partial")
			if not download.ok or FileAccess.get_sha256(archive + ".partial") != expected_hash:
				Common.check(result, "download_verified", false, "Download failed or checksum mismatch; partial file retained for diagnosis.")
				Common.finish(self, result, str(args.get("report", "")))
				return
			if FileAccess.file_exists(archive):
				Common.check(result, "existing_archive", false, "Existing archive differs; select a new --archive path.")
				Common.finish(self, result, str(args.get("report", "")))
				return
			DirAccess.rename_absolute(archive + ".partial", archive)
	if expected_hash.length() != 64 or not FileAccess.file_exists(archive) or FileAccess.get_sha256(archive) != expected_hash:
		Common.check(result, "archive_sha256", false, "Missing archive or checksum mismatch.")
		Common.finish(self, result, str(args.get("report", "")))
		return
	var zip := ZIPReader.new()
	if zip.open(archive) != OK:
		Common.check(result, "open_archive", false)
		Common.finish(self, result, str(args.get("report", "")))
		return
	var files: PackedStringArray = str(args.files).split(",", false)
	if "version.txt" not in files:
		files.append("version.txt")
	var expected_version: String = version + "." + str(engine.status)
	var archive_version: String = zip.read_file("templates/version.txt").get_string_from_utf8().strip_edges()
	Common.check(result, "matching_version", archive_version == expected_version, archive_version)
	for name: String in files:
		Common.check(result, "member:" + name, name.is_valid_filename() and not name.contains("/") and not name.contains("\\") and zip.file_exists("templates/" + name))
	if result.status != "passed":
		zip.close()
		Common.finish(self, result, str(args.get("report", "")))
		return
	# Inspect all conflicts before writing any file. Existing identical files are reusable.
	for name: String in files:
		var path: String = dest.path_join(name)
		if FileAccess.file_exists(path):
			var hash := HashingContext.new()
			hash.start(HashingContext.HASH_SHA256)
			hash.update(zip.read_file("templates/" + name))
			Common.check(result, "existing:" + name, FileAccess.get_sha256(path) == hash.finish().hex_encode(), "Refuse to overwrite different content")
	if result.status == "passed":
		Common.check(result, "create_destination", DirAccess.make_dir_recursive_absolute(dest) == OK)
	if result.status == "passed":
		for name: String in files:
			var path: String = dest.path_join(name)
			if not FileAccess.file_exists(path):
				var file: FileAccess = FileAccess.open(path + ".partial", FileAccess.WRITE)
				if file == null:
					Common.check(result, "write:" + name, false, error_string(FileAccess.get_open_error()))
					break
				file.store_buffer(zip.read_file("templates/" + name))
				file.flush()
				var write_error: Error = file.get_error()
				file.close()
				if write_error != OK:
					Common.check(result, "write:" + name, false, error_string(write_error))
					break
				Common.check(result, "install:" + name, DirAccess.rename_absolute(path + ".partial", path) == OK)
			result.artifacts.append(path)
	zip.close()
	result.archive_sha256 = expected_hash
	Common.finish(self, result, str(args.get("report", "")))
