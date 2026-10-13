extends Node
const MODE: int = 3
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
	hud.text = ("ORBIT GARDEN" if MODE == 2 else "BEACON ISLAND") + "     /     CORES  %d / 3     /     BEST  %d" % [score, best]

func _load_best() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary and data.get("version") == 1 and data.get("best") is float:
		best = clampi(int(data.best), 0, 3)

func _save_best() -> bool:
	var temporary := save_path + ".tmp"
	var backup := save_path + ".bak"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "best": best}))
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	if not ok or not JSON.parse_string(FileAccess.get_file_as_string(temporary)) is Dictionary:
		return false
	# Preserve an existing save before replacing it. Unexpected backup -> no overwrite.
	if FileAccess.file_exists(backup):
		return false
	var had_save := FileAccess.file_exists(save_path)
	if had_save and DirAccess.rename_absolute(save_path, backup) != OK:
		return false
	if DirAccess.rename_absolute(temporary, save_path) != OK:
		if had_save:
			DirAccess.rename_absolute(backup, save_path)
		return false
	if had_save:
		DirAccess.remove_absolute(backup)
	return true

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
	var ok := true
	for item: Dictionary in checks:
		ok = ok and item.passed
	var result := {"schema_version": 1, "status": "passed" if ok else "failed", "engine": Engine.get_version_info(), "mode": MODE, "display": DisplayServer.get_name(), "checks": checks, "artifacts": [test_output]}
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(result))
	sound.stop()
	sound.stream = null
	await get_tree().create_timer(0.05).timeout
	get_tree().quit.call_deferred(0 if ok else 1)

func mesh_box(size: Vector3, position: Vector3, color: Color, parent: Node) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	visual.mesh = box
	visual.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	visual.material_override = material
	parent.add_child(visual)
	return visual
func _build_world() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("172b41")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c9ddff")
	environment.environment.ambient_light_energy = 0.7
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 12, 13)
	camera.rotation_degrees.x = -43
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20
	add_child(camera)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(16, 1, 10)
	shape.shape = box
	shape.position.y = -0.5
	floor_body.add_child(shape)
	mesh_box(Vector3(16, 1, 10), Vector3(0, -0.5, 0), Color("365d70"), floor_body)
	add_child(floor_body)
	for x in [-6.0, 0.0, 6.0]:
		mesh_box(Vector3(0.3, 2.5, 0.3), Vector3(x, 1.25, -4.3), Color("79ccb2"), self)
	var body := CharacterBody3D.new()
	body.position = Vector3(-4, 0.6, 0)
	var collider := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = Vector3(0.8, 1.0, 0.8)
	collider.shape = cube
	body.add_child(collider)
	mesh_box(cube.size, Vector3.ZERO, Color("58d9b3"), body)
	mesh_box(Vector3(0.12, 0.15, 0.82), Vector3(0.3, 0.2, 0), Color("effffb"), body)
	add_child(body)
	player = body
func _spawn_pickup(point: Vector2) -> void:
	var area := Area3D.new()
	area.position = Vector3(point.x, 0.65, point.y)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.65
	shape.shape = sphere
	area.add_child(shape)
	var crystal := mesh_box(Vector3(0.55, 0.85, 0.55), Vector3.ZERO, Color("ffcc66"), area)
	crystal.rotation_degrees = Vector3(0, 45, 20)
	area.body_entered.connect(_collect.bind(area))
	add_child(area)
	pickups.append(area)
