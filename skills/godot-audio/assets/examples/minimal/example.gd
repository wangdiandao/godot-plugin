extends SceneTree
var checks: Array = []
var output: String
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	output = args[i + 1] if i >= 0 and i + 1 < args.size() else ProjectSettings.globalize_path("res://.godot-plugin/example")
	output = output.replace("\\", "/")
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

var playback_finished := false
func _on_finished() -> void:
	playback_finished = true

func route_player(player: AudioStreamPlayer, bus_name: String) -> bool:
	if AudioServer.get_bus_index(bus_name) < 0:
		return false
	player.bus = bus_name
	return true

func _run() -> void:
	var original := AudioServer.generate_bus_layout()
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, "ExampleSFX")
	AudioServer.set_bus_send(index, "Master")
	AudioServer.set_bus_volume_db(index, -12.0)
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
	var restored_stream := AudioStreamWAV.load_from_file(output.path_join("tone.wav"))
	expect(restored_stream != null and restored_stream.mix_rate == 22050 and not restored_stream.stereo and is_equal_approx(restored_stream.get_length(), 0.1), "wav_saved_state_readback")
	var player := AudioStreamPlayer.new()
	player.stream = restored_stream
	player.bus = "ExampleSFX"
	root.add_child(player)
	player.finished.connect(_on_finished)
	player.play()
	expect(player.playing, "playback_started")
	expect(AudioServer.get_bus_effect_count(index) == 1, "effect_routed")
	expect(ResourceSaver.save(AudioServer.generate_bus_layout(), output.path_join("buses.tres")) == OK, "save_bus_layout")
	var saved := ResourceLoader.load(output.path_join("buses.tres"), "AudioBusLayout", ResourceLoader.CACHE_MODE_IGNORE) as AudioBusLayout
	expect(saved != null, "bus_layout_cache_ignored_readback")
	if saved != null:
		AudioServer.set_bus_layout(saved)
		index = AudioServer.get_bus_index("ExampleSFX")
		expect(index > 0 and AudioServer.get_bus_send(index) == "Master" and is_equal_approx(AudioServer.get_bus_volume_db(index), -12.0), "saved_bus_routing_and_volume")
		expect(AudioServer.get_bus_effect(index, 0) is AudioEffectLimiter, "saved_limiter")
		AudioServer.set_bus_mute(index, true)
		expect(AudioServer.is_bus_mute(index), "mute_state")
		AudioServer.set_bus_mute(index, false)
		expect(not AudioServer.is_bus_mute(index), "unmute_state")
	expect(AudioServer.get_bus_index("MissingBus") == -1, "missing_bus_detected_before_routing")
	await create_timer(0.5).timeout
	expect(playback_finished and not player.playing, "nonlooping_playback_finishes")
	var prior_bus := player.bus
	expect(not route_player(player, "MissingBus") and player.bus == prior_bus, "missing_bus_route_rejected_without_mutation")
	expect(route_player(player, "ExampleSFX") and player.bus == "ExampleSFX", "valid_bus_route_repairs_request")
	for cycle in range(2):
		playback_finished = false
		player.play()
		await create_timer(0.5).timeout
		expect(playback_finished and not player.playing, "repaired_audio_lifecycle_repeats_" + str(cycle))
	expect(AudioServer.get_bus_send(index) == "Master" and AudioServer.get_bus_effect(index, 0) is AudioEffectLimiter and is_equal_approx(AudioServer.get_bus_volume_db(index), -12.0), "audio_route_repair_preserves_mix")
	player.stop()
	player.queue_free()
	AudioServer.set_bus_layout(original)
	await process_frame
	finish()
