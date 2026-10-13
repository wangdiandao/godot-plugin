extends Node
const MODE: int = 2
var playing := false
var score := 0
var best := 0
var player: Node
var pickups: Array[Node] = []
var menu: PanelContainer
var start_button: Button
var hud: Label
var hint: Label
var sound: AudioStreamPlayer
var save_store = preload("res://save_store.gd").new()
var save_failure := ""
var save_path := "user://progress.json"
var test_output := ""
var checks: Array = []

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--out")
	if "--self-test" in args and at >= 0 and at + 1 < args.size():
		test_output = args[at + 1]
		DirAccess.make_dir_recursive_absolute(test_output)
		save_path = test_output.path_join("progress.json")
	_load_best()
	_build_world()
	_build_sound()
	_build_ui()
	if "--self-test" in args:
		_self_test.call_deferred()

func _build_sound() -> void:
	sound = AudioStreamPlayer.new()
	add_child(sound)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(6614)
	for i in range(3307):
		var envelope := 1.0 - float(i) / 3307.0
		data.encode_s16(i * 2, int(sin(TAU * 740.0 * i / 22050.0) * 5000.0 * envelope))
	stream.data = data
	sound.stream = stream
	sound.volume_db = -10.0

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	layer.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ribbon := ColorRect.new()
	ribbon.color = Color("101e30")
	ribbon.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	ribbon.offset_bottom = 76
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ribbon)
	hud = Label.new()
	hud.position = Vector2(32, 18)
	hud.add_theme_font_size_override("font_size", 25)
	hud.add_theme_color_override("font_color", Color("bceee0"))
	ui.add_child(hud)
	hint = Label.new()
	hint.position = Vector2(32, 500)
	hint.add_theme_font_size_override("font_size", 17)
	hint.text = "ARROW KEYS  Move     SPACE / ENTER  Start     R  Restart"
	ui.add_child(hint)
	menu = PanelContainer.new()
	menu.position = Vector2(64, 128)
	menu.size = Vector2(420, 310)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("13263af2")
	style.border_color = Color("58d9b3")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	menu.add_theme_stylebox_override("panel", style)
	ui.add_child(menu)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	menu.add_child(column)
	var tag := Label.new()
	tag.text = "NATIVE GODOT  /  " + str(MODE) + "D"
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", Color("58d9b3"))
	column.add_child(tag)
	var title := Label.new()
	title.text = "ORBIT GARDEN" if MODE == 2 else "BEACON ISLAND"
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	var description := Label.new()
	description.text = "Collect all three energy cores.\nYour best run is saved automatically."
	description.add_theme_font_size_override("font_size", 17)
	column.add_child(description)
	start_button = Button.new()
	start_button.text = "Begin expedition"
	start_button.custom_minimum_size.y = 54
	start_button.pressed.connect(_start)
	column.add_child(start_button)
	start_button.grab_focus()
	_update_hud()

func _start() -> void:
	for pickup: Node in pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	pickups.clear()
	score = 0
	playing = true
	menu.hide()
	if MODE == 2:
		(player as CharacterBody2D).position = Vector2(180, 270)
		for point in [Vector2(300, 270), Vector2(520, 350), Vector2(760, 210)]:
			_spawn_pickup(point)
	else:
		(player as CharacterBody3D).position = Vector3(-4, 0.6, 0)
		for point in [Vector2(-1, 0), Vector2(2, 2), Vector2(4, -2)]:
			_spawn_pickup(point)
	_update_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		_start()

func _physics_process(_delta: float) -> void:
	if not playing:
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if MODE == 2:
		var body := player as CharacterBody2D
		body.velocity = direction * 240.0
		body.move_and_slide()
		body.position = body.position.clamp(Vector2(45, 105), Vector2(915, 470))
	else:
		var body := player as CharacterBody3D
		body.velocity = Vector3(direction.x * 6.0, -2.0, direction.y * 6.0)
		body.move_and_slide()
		body.position.x = clampf(body.position.x, -7, 7)
		body.position.z = clampf(body.position.z, -4, 4)

func _collect(body: Node, pickup: Node) -> void:
	if body != player or not playing or pickup.is_queued_for_deletion():
		return
	pickup.queue_free()
	score += 1
	sound.play()
	if score == 3:
		playing = false
		best = maxi(best, score)
		if not _save_best():
			push_error("SAVE_FAILED")
		menu.show()
		start_button.text = "Expedition complete — play again"
		start_button.grab_focus()
	_update_hud()

func _update_hud() -> void:
	hint.text = save_failure if not save_failure.is_empty() else "ARROW KEYS  Move     ENTER  Start     R  Restart"
	hud.text = ("ORBIT GARDEN" if MODE == 2 else "BEACON ISLAND") + "     /     CORES  %d / 3     /     BEST  %d" % [score, best]

func _load_best() -> void:
	var loaded: Dictionary = save_store.load_path(save_path)
	best = int(loaded.best) if loaded.status == "ok" else 0
	save_failure = "" if loaded.status in ["ok", "missing"] else "Save protected: " + str(loaded.status)

func _save_best() -> bool:
	var outcome: String = save_store.commit(best)
	save_failure = "" if outcome == "ok" else "Save protected: " + outcome
	return outcome == "ok"

func _expect(value: bool, label: String) -> void:
	checks.append({"name": label, "passed": value})

func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func _self_test() -> void:
	for i in range(4):
		await get_tree().process_frame
	_expect(menu.visible and not playing, "initial_menu")
	_key(KEY_ENTER, true)
	await get_tree().process_frame
	_key(KEY_ENTER, false)
	await get_tree().process_frame
	_expect(playing and not menu.visible, "menu_keyboard_start")
	var initial: Vector2 = (player as CharacterBody2D).position if MODE == 2 else Vector2((player as CharacterBody3D).position.x, (player as CharacterBody3D).position.z)
	_key(KEY_RIGHT, true)
	for i in range(35):
		await get_tree().physics_frame
	_key(KEY_RIGHT, false)
	var current: Vector2 = (player as CharacterBody2D).position if MODE == 2 else Vector2((player as CharacterBody3D).position.x, (player as CharacterBody3D).position.z)
	_expect(current.x > initial.x + (80.0 if MODE == 2 else 2.0), "input_moves_physics_body")
	_expect(score == 1, "movement_collects_first_core")
	_expect(sound.stream != null and sound.get_playback_position() >= 0, "audio_stream_configured")
	# Teleport for remaining collision checks; movement itself was tested above.
	for point in ([Vector2(520, 350), Vector2(760, 210)] if MODE == 2 else [Vector2(2, 2), Vector2(4, -2)]):
		if MODE == 2:
			(player as CharacterBody2D).position = point
		else:
			(player as CharacterBody3D).position = Vector3(point.x, 0.6, point.y)
		for i in range(5):
			await get_tree().physics_frame
	_expect(score == 3 and not playing, "win_condition")
	_expect(FileAccess.file_exists(save_path), "save_created")
	best = 0
	_load_best()
	_expect(best == 3, "save_reloaded")
	if DisplayServer.get_name() != "headless" and not test_output.is_empty():
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		_expect(image.get_width() == 960 and image.get_height() == 540, "viewport_dimensions")
		_expect(image.save_png(test_output.path_join("game.png")) == OK, "screenshot_saved")
	_key(KEY_R, true)
	for i in range(3):
		await get_tree().process_frame
	_key(KEY_R, false)
	await get_tree().process_frame
	_expect(playing and score == 0, "restart_input")
	_save_contract_checks()
	var ok := true
	for item: Dictionary in checks:
		ok = ok and item.passed
	var result := {"schema_version": 1, "status": "passed" if ok else "failed", "engine": Engine.get_version_info(), "mode": MODE, "display": DisplayServer.get_name(), "checks": checks, "artifacts": [test_output]}
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(result))
	sound.stop()
	sound.stream = null
	await get_tree().create_timer(0.05).timeout
	get_tree().quit.call_deferred(0 if ok else 1)

func polygon(points: PackedVector2Array, color: Color, parent: Node) -> Polygon2D:
	var node := Polygon2D.new()
	node.polygon = points
	node.color = color
	parent.add_child(node)
	return node
func _build_world() -> void:
	polygon(PackedVector2Array([Vector2.ZERO, Vector2(960, 0), Vector2(960, 540), Vector2(0, 540)]), Color("172b41"), self)
	for x in range(32, 960, 48):
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(x, 85), Vector2(x, 480)])
		line.default_color = Color("28425a")
		line.width = 1
		add_child(line)
	for y in range(95, 490, 48):
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(32, y), Vector2(928, y)])
		line.default_color = Color("28425a")
		line.width = 1
		add_child(line)
	var body := CharacterBody2D.new()
	body.position = Vector2(180, 270)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15
	shape.shape = circle
	body.add_child(shape)
	polygon(PackedVector2Array([Vector2(-16, -12), Vector2(20, 0), Vector2(-16, 12), Vector2(-8, 0)]), Color("58d9b3"), body)
	add_child(body)
	player = body
func _spawn_pickup(point: Vector2) -> void:
	var area := Area2D.new()
	area.position = point
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16
	shape.shape = circle
	area.add_child(shape)
	polygon(PackedVector2Array([Vector2(0, -18), Vector2(14, 0), Vector2(0, 18), Vector2(-14, 0)]), Color("ffcc66"), area)
	area.body_entered.connect(_collect.bind(area))
	add_child(area)
	pickups.append(area)

func _save_contract_checks() -> void:
	var original_path := save_path
	var original_best := best
	var guard_path := test_output.path_join("guard.json")
	for bad: String in ['{broken', '{"version":99,"new_data":"keep"}', '{"version":1,"best":1.5}', '{"version":1,"best":-1}', 'null']:
		var file := FileAccess.open(guard_path, FileAccess.WRITE)
		file.store_string(bad)
		file.close()
		save_path = guard_path
		_load_best()
		var hash_before := FileAccess.get_sha256(guard_path)
		best = 3
		_expect(not _save_best() and FileAccess.get_sha256(guard_path) == hash_before, "protected_save_" + str(checks.size()))
	var file := FileAccess.open(guard_path, FileAccess.WRITE)
	file.store_string('{"version":1,"best":1}')
	file.close()
	_load_best()
	file = FileAccess.open(guard_path, FileAccess.WRITE)
	file.store_string('{"version":1,"best":2}')
	file.close()
	var changed_hash := FileAccess.get_sha256(guard_path)
	_expect(not _save_best() and FileAccess.get_sha256(guard_path) == changed_hash, "external_save_change_preserved")
	var protected := preload("res://save_store.gd").new()
	protected.load_path(guard_path)
	var backup := FileAccess.open(guard_path + ".bak",FileAccess.WRITE)
	backup.store_string("UNEXPECTED_BACKUP_KEEP")
	backup.close()
	var target_before := FileAccess.get_sha256(guard_path)
	var backup_before := FileAccess.get_sha256(guard_path + ".bak")
	_expect(protected.commit(3) == "backup_conflict" and FileAccess.get_sha256(guard_path) == target_before and FileAccess.get_sha256(guard_path + ".bak") == backup_before,"unexpected_backup_and_target_preserved")
	var normal := preload("res://save_store.gd").new()
	normal.load_path(test_output.path_join("repeat-save.json"))
	_expect(normal.commit(1) == "ok" and normal.commit(2) == "ok" and normal.read_file(normal.path).best == 2,"repeated_valid_commit_readback")
	var missing := preload("res://save_store.gd").new()
	missing.load_path(test_output.path_join("missing-parent/save.json"))
	_expect(missing.commit(2) == "write_failed", "save_io_failure_rejected")
	save_path = original_path
	_load_best()
	best = original_best
