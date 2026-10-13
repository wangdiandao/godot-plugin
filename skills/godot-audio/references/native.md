# Audio recipes and diagnostics (Godot 4.7)

Choose imported effect/music playback, bus mix modification, positional audio, recording or silence/latency diagnosis. API baseline is the [4.7 audio manual](https://docs.godotengine.org/en/4.7/tutorials/audio/index.html), [AudioServer](https://docs.godotengine.org/en/4.7/classes/class_audioserver.html) and locally tested standard Godot 4.7.2. Sound quality and device behavior require actual listening; state assertions do not establish those outcomes.

## Isolated executable acceptance

Copy `assets/examples/minimal/` to a clean directory; create OUT, then:

```text
GODOT --headless --path EXAMPLE --script EXAMPLE/example.gd --log-file OUT/engine.log -- --out OUT
```

The script creates a short mono 16-bit 22050 Hz tone, saves `tone.wav`, loads it from the external output path and checks rate/channels/length. It creates an ExampleSFX bus sending to Master at -12 dB with a limiter, saves `buses.tres`, reloads CACHE_MODE_IGNORE and asserts volume/send/effect identity, mute/unmute and missing-bus detection. Playback must start and a nonlooping stream must finish. The original bus layout is restored. This proves native resource and player behavior, not actual audible output, clipping safety or limiter quality. Run without headless for device audition.

## Develop an effect/music system

1. Inspect source licenses and choose import format deliberately. Uncompressed short WAV/PCM avoids repeated decompression for low-latency effects but costs decoded memory. Longer music/ambience usually benefits from compressed Ogg Vorbis/MP3; measure decoding CPU, seek/loop behavior and memory rather than a universal size rule. Mono is normally appropriate for positional sources; stereo may be intentional for nonpositional music. Preserve source assets and importer sidecars when reimporting.
2. Create an explicit bus plan: Master, then Music/UI/SFX/Voice as needed. Sends go from right to a bus on the left, preventing cycles. Resolve existing buses by name before creating duplicates; bus indices can change. Assign players to a validated name because an invalid route can silently fall back to Master.
3. Choose AudioStreamPlayer for nonpositional UI/music, AudioStreamPlayer2D for world 2D and AudioStreamPlayer3D for 3D attenuation. Assign a resource loaded through ResourceLoader for imported res:// assets; raw load_from_file APIs are for external runtime paths. Configure loop through the stream/import resource and implement retrigger/polyphony policy separately.
4. Connect finished for nonlooping lifecycle cleanup. stop is intentional interruption, stream_paused suspends playback, and looping streams never complete normally. For a bursty SFX pool, set a bounded voice budget and reclaim idle players; blindly allocating a new node per event can create spikes and orphaned nodes.
5. Save a bus layout, checked preferences and scene references. Reload in a clean copy, trigger sound through the actual interaction/event path, then audition both quiet and peak gameplay. Inspect master level and dynamics; avoid clipping by mix gain rather than assuming a limiter fixes every overloaded source.

Minimal checked playback setup:

```gdscript
func play_ui_sound(player: AudioStreamPlayer, stream: AudioStream) -> bool:
    if stream == null or AudioServer.get_bus_index("UI") < 0:
        return false
    player.bus = "UI"
    player.stream = stream
    player.play()
    return player.playing
```

Place the player inside the active tree first. Add a nonlooping finished observer with a timeout for testing, and do not count playing alone as successful device playback. [Audio streams](https://docs.godotengine.org/en/4.7/tutorials/audio/audio_streams.html), [AudioStreamPlayer](https://docs.godotengine.org/en/4.7/classes/class_audiostreamplayer.html).

## Modify a mix or volume settings safely

Save the current AudioServer.generate_bus_layout before runtime modification. Locate target buses by name, inspect sends and effect order, then change only the requested category. A compressor, EQ, reverb and limiter are different signal processors; adding each creates cost and must have a concrete listening goal. Distinguish bus bypass, individual effect enabled, bus mute, solo and player volume.

Expose user volume as linear amplitude with explicit zero handling or use linear_to_db/db_to_linear as appropriate:

```gdscript
func set_category_volume(bus_name: StringName, value: float) -> bool:
    var index := AudioServer.get_bus_index(bus_name)
    if index < 0 or not is_finite(value):
        return false
    var amplitude := clampf(value, 0.0, 1.0)
    AudioServer.set_bus_mute(index, amplitude == 0.0)
    if amplitude > 0.0:
        AudioServer.set_bus_volume_db(index, linear_to_db(amplitude))
    return true
```

Persist the amplitude and mute policy in checked ConfigFile; bus runtime changes are not automatically project resources. When rebuilding a bus layout, ensure player names remain present. Save AudioBusLayout with ResourceSaver, reload CACHE_MODE_IGNORE, apply and assert sends, dB values, effect count/type and mute state. Restore the original layout on failure. Final audio layout usually lives at res://default_bus_layout.tres; user settings live under user://. [Audio buses](https://docs.godotengine.org/en/4.7/tutorials/audio/audio_buses.html).

## Positional audio and listener recipe

Ensure the correct Viewport processes audio and its active camera or explicit AudioListener defines the listener. Multiple cameras/worlds/split-screen viewports can create an unexpected listener or duplicated audio. Locate sound emitters in the intended coordinate space; choose attenuation/unit size, max distance, emission direction and panning independently. Teleporting a player changes listener conditions, not the source clip.

Test a known mono effect while moving the listener left/right/near/far and behind relevant gameplay occlusion. Audio physics obstruction is not automatic unless implemented. Do not promise headphone HRTF parity solely from AudioStreamPlayer3D. Verify pause behavior and Doppler settings against the intended motion. For 3D audio with texture-Viewport UI, confirm the world/player rather than the UI viewport is the listener. [AudioStreamPlayer2D](https://docs.godotengine.org/en/4.7/classes/class_audiostreamplayer2d.html), [AudioStreamPlayer3D](https://docs.godotengine.org/en/4.7/classes/class_audiostreamplayer3d.html).

## Import, recording and platform conditions

For import modification, identify the source and .import sidecar, change intended sample-rate/channel/compression/loop options, run normal reimport, then check actual loaded stream properties and auditory loop boundaries. Import transformations are destructive to output quality even when source remains recoverable; preserve originals and retest target export. For external WAV, AudioStreamWAV.load_from_file returns null on invalid input and supports explicit conversion options; verify shape/length rather than only accepting its extension. Packed data returned from stream properties may be copies, requiring reassignment.

For microphone input, enable audio input in project settings, request platform permissions through the proper export/device flow, route AudioStreamMicrophone into a dedicated recording bus and use AudioEffectRecord/AudioEffectCapture for the desired capture format. Avoid accidental speaker feedback while monitoring. Verify selected input device, real input rate, permission denial, record start/stop and checked WAV save/readback. Recordings are user data; filenames need collision policy and validated paths. [Microphone recording](https://docs.godotengine.org/en/4.7/tutorials/audio/recording_with_microphone.html), [AudioStreamWAV](https://docs.godotengine.org/en/4.7/classes/class_audiostreamwav.html).

Query actual driver/device/rate/latency rather than requested settings. Dummy is intentionally silent. Web browser audio may require user activation; Sample playback targets lower latency but does not support ordinary AudioEffects, so use Stream when the mix requires those effects and retest latency. Browser, mobile permissions, background/pause behavior and OS device switches require their actual environment. Output latency is an estimate and playback positions are not exact wall-clock presentation times. The music-clock method must account for AudioServer.get_time_since_last_mix and get_output_latency, and still needs empirical synchronization acceptance. [Audio synchronization](https://docs.godotengine.org/en/4.7/tutorials/audio/sync_with_audio.html).

## Diagnosis: symptom → check → cause → fix → retest

| Symptom | Check | Cause and fix | Retest |
|---|---|---|---|
| Player playing but silent | Dummy driver, output device, bus mute/solo/send, source level | No real output or muted route; select actual device and repair graph | Audible known test tone plus bus meters |
| Sound uses wrong mix | Bus name/index, layout reload, missing destination | Missing bus falls back or indices moved; resolve name and reject missing route | Saved/reloaded scene and layout under gameplay |
| 3D sound inaudible | Listener viewport/camera, distances, channels, direction | Wrong listener or attenuation; fix world/listener and source properties | Near/far and left/right movement |
| Effect does nothing on Web | Playback type and effect support | Sample path lacks effects; choose supported Stream path | Browser gesture activation, mix and latency |
| Loop clicks or gaps | Import loop points, codec, stream duration | Boundary discontinuity or decoding/seek issue; correct source/loop settings | Many actual loop cycles on target device |
| SFX CPU/memory grows | Player allocation, voice count, decoded assets, retained references | Unbounded voices or resource retention; bounded pool and lifecycle cleanup | Peak burst and repeated level cycles |
| Audio distorts | Master peak, source gain, effect order, sample clipping | Mix overload; reduce gain and tune dynamics | Loudest concurrent scene and headphones/speakers |
| Recording empty | Input setting, permissions, driver/device, bus capture | Denied/unavailable or wrong route; fix device and permission lifecycle | Known input plus denial case and saved readback |
| Music and animation drift | Mix timing, latency, speed changes, device switch | Different clocks; derive presentation clock and resynchronize | Long playback on actual output device |

## Delivery boundaries

### Repair a missing route without changing the mix

1. Record the actual player path, stream, driver/device, requested bus name, bus sends, mute/solo and effects. Distinguish a missing name from an existing silent bus.
2. Resolve names with `AudioServer.get_bus_index()` before assigning the player. Reject a missing destination while preserving the previous route; fallback to Master can hide the error.
3. Choose the intended existing bus, or create a bus only when the requested mix requires one. Change routing separately from loudness, effects, source files and listener configuration.
4. Save/read back authored scene/layout changes. Replay nonlooping start/completion twice and verify the send, effects and volume stayed intact. Preserve the old route on validation failure.
5. For audible success, use the actual device and bus meters. Dummy/headless lifecycle assertions do not establish hearing, clipping, latency or output quality.

The bundled case rejects a missing route without mutation, accepts an existing destination and repeats playback while retaining its saved mix.

Record rate/channels/import policy, bus sends/effects, lifecycle assertions, actual driver/device and output files. State checks under headless may pass with Dummy while listening remains untested. Never claim microphone, surround, headphones, Web effects or target latency from a resource-only run. Low-frequency DSP APIs remain on-demand in the versioned class reference; do not invent a specialized recipe for every AudioEffect subclass.


Binding reference: [fixed4.7.2 implementation](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/scene/audio/audio_stream_player.cpp). Internal methods are not public API evidence unless bound and verified in the task environment.
