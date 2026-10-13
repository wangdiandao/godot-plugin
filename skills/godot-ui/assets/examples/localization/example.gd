extends SceneTree

class LocalizedLabel extends Label:
	func _ready() -> void:
		auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		refresh()
	func _notification(what: int) -> void:
		if what == NOTIFICATION_TRANSLATION_CHANGED and is_inside_tree():
			refresh()
	func refresh() -> void:
		# Explicit TranslationServer lookup because this label owns its refresh.
		text = TranslationServer.translate("READY")

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

func expect(condition: bool, name: String) -> void:
	checks.append({"name": name, "status": "passed" if condition else "failed"})

func placeholders(message: String) -> Array[String]:
	var pattern := RegEx.new()
	pattern.compile("\\{[A-Za-z_][A-Za-z0-9_]*\\}")
	var found: Array[String] = []
	for match_value: RegExMatch in pattern.search_all(message):
		found.append(match_value.get_string())
	found.sort()
	return found

func audit(catalog: Translation) -> Array[String]:
	var failures: Array[String] = []
	for key: String in ["READY", "WELCOME"]:
		var message := String(catalog.get_message(key))
		if message.is_empty():
			failures.append("missing:" + key)
		elif key == "WELCOME" and placeholders(message) != placeholders("Welcome, {player}"):
			failures.append("placeholders:" + key)
	return failures

func _run() -> void:
	expect(ClassDB.class_has_method("Translation", "get_message") and ClassDB.class_has_method("TranslationServer", "reload_pseudolocalization"), "public_bindings_available")
	var initial_locale := TranslationServer.get_locale()
	var initial_pseudo := TranslationServer.pseudolocalization_enabled
	TranslationServer.pseudolocalization_enabled = false
	var configured: PackedStringArray = ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray())
	var source_hash := FileAccess.get_sha256("res://locale/es.po")
	expect(configured.size() == 2 and TranslationServer.get_loaded_locales().has("en") and TranslationServer.get_loaded_locales().has("es"), "cold_start_loads_configured_catalogs")
	var source := ResourceLoader.load("res://locale/es.po", "Translation", ResourceLoader.CACHE_MODE_IGNORE) as Translation
	expect(source != null, "po_loaded_by_native_resource_loader")
	if source == null:
		finish()
		return
	expect(audit(source).is_empty(), "catalog_required_keys_and_named_placeholders")
	var saved_path := output.path_join("es.tres")
	expect(ResourceSaver.save(source, saved_path) == OK, "catalog_saved")
	var restored := ResourceLoader.load(saved_path, "Translation", ResourceLoader.CACHE_MODE_IGNORE) as Translation
	expect(restored != null and restored.get_message("Open", "menu") == "Abrir" and restored.get_message("Open", "state") == "Abierto", "uncached_catalog_preserves_context")
	if restored == null:
		TranslationServer.set_locale(initial_locale)
		TranslationServer.pseudolocalization_enabled = initial_pseudo
		finish()
		return
	expect(restored.get_plural_message("%d apple", "%d apples", 1) == "%d manzana" and restored.get_plural_message("%d apple", "%d apples", 2) == "%d manzanas", "uncached_catalog_preserves_plural_forms")
	TranslationServer.set_locale("en")
	var label := LocalizedLabel.new()
	root.add_child(label)
	expect(label.text == "Ready", "initial_label_uses_english")
	TranslationServer.set_locale("es")
	await process_frame
	expect(label.text == "Listo", "locale_notification_refreshes_existing_ui")
	expect(TranslationServer.translate("Open", "menu") == "Abrir" and TranslationServer.translate("Open", "state") == "Abierto", "runtime_context_disambiguation")
	expect(String(TranslationServer.translate_plural("%d apple", "%d apples", 1)) % 1 == "1 manzana" and String(TranslationServer.translate_plural("%d apple", "%d apples", 2)) % 2 == "2 manzanas", "runtime_pluralization")
	expect(String(TranslationServer.translate("WELCOME")).format({"player": "Ada"}) == "Bienvenido, Ada", "named_placeholder_formatting")
	expect(TranslationServer.translate("UNREGISTERED_KEY") == "UNREGISTERED_KEY", "missing_key_fallback_does_not_prove_completeness")
	TranslationServer.set_locale("fr")
	expect(TranslationServer.translate("READY") == "Ready", "unsupported_locale_uses_configured_fallback")
	var faulty := restored.duplicate() as Translation
	faulty.erase_message("WELCOME")
	expect(audit(faulty) == ["missing:WELCOME"], "audit_detects_missing_entry_without_fallback")
	faulty.add_message("WELCOME", "Bienvenido, {name}")
	expect(audit(faulty) == ["placeholders:WELCOME"], "audit_detects_changed_placeholder")
	faulty.add_message("WELCOME", "Bienvenido, {player}")
	expect(audit(faulty).is_empty() and audit(source).is_empty(), "repair_keeps_original_catalog_intact")
	expect(FileAccess.get_sha256("res://locale/es.po") == source_hash, "negative_controls_preserve_source_file_hash")
	TranslationServer.set_locale("en")
	TranslationServer.pseudolocalization_enabled = true
	var expanded := String(TranslationServer.translate("WELCOME"))
	expect(expanded != "Welcome, {player}", "pseudolocalization_changes_text")
	expect(String(TranslationServer.pseudolocalize("Hello %s")).contains("%s"), "pseudolocalization_preserves_printf_placeholder")
	TranslationServer.pseudolocalization_enabled = false
	for locale_name: String in ["es", "en", "es", "en"]:
		TranslationServer.set_locale(locale_name)
		await process_frame
		expect(label.text == ("Ready" if locale_name == "en" else "Listo"), "repeated_locale_switch_" + locale_name + "_" + str(checks.size()))
	label.queue_free()
	TranslationServer.set_locale(initial_locale)
	TranslationServer.pseudolocalization_enabled = initial_pseudo
	await process_frame
	finish()

func finish() -> void:
	var passed := not checks.is_empty()
	for check: Dictionary in checks:
		passed = passed and check.status == "passed"
	var report := {"schema_version": 1, "status": "passed" if passed else "failed", "engine": Engine.get_version_info(), "platform": OS.get_name(), "display": DisplayServer.get_name(), "checks": checks, "artifacts": [output], "limitations": ["No packaged-font glyph, RTL layout, screen-reader or visual pseudolocalization acceptance.", "Placeholder audit covers named brace tokens in this example, not arbitrary format/markup syntax."]}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	if file == null:
		push_error("REPORT_WRITE_FAILED")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(report))
	quit(0 if passed else 1)
