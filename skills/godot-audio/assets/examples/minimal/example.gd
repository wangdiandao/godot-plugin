extends SceneTree
var checks: Array = []
var output: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	output = args[i + 1] if i >= 0 and i + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/example")
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("OUTPUT_DIRECTORY_FAILED")
		quit(1)
		return
	call_deferred("_run")
func expect(value: bool, label: String) -> void:
	checks.append({"name": label, "status": "passed" if value else "failed"})
func finish() -> void:
	var ok := not checks.is_empty()
	for item: Dictionary in checks:
		ok = ok and item.status == "passed"
	var result := {"schema_version": 1, "status": "passed" if ok else "failed", "engine": Engine.get_version_info(), "platform": OS.get_name(), "display": DisplayServer.get_name(), "checks": checks, "artifacts": [output]}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	if file == null:
		push_error("REPORT_WRITE_FAILED")
		quit(1)
		return
	file.store_string(JSON.stringify(result, "	"))
	file.close()
	print("GODOT_PLUGIN_RESULT:" + JSON.stringify(result))
	quit(0 if ok else 1)

func _run() -> void:
	var original := AudioServer.generate_bus_layout()
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, "ExampleSFX")
	var limiter := AudioEffectLimiter.new()
	AudioServer.add_bus_effect(index, limiter)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(4410)
	for i in range(2205):
		bytes.encode_s16(i * 2, int(sin(TAU * 440.0 * i / 22050.0) * 5000.0))
	stream.data = bytes
	expect(stream.save_to_wav(output.path_join("tone.wav")) == OK, "native_pcm_wav_save")
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "ExampleSFX"
	root.add_child(player)
	player.play()
	expect(player.playing, "playback_started")
	expect(AudioServer.get_bus_effect_count(index) == 1, "effect_routed")
	expect(ResourceSaver.save(AudioServer.generate_bus_layout(), output.path_join("buses.tres")) == OK, "save_bus_layout")
	player.stop()
	player.queue_free()
	AudioServer.set_bus_layout(original)
	await process_frame
	finish()
