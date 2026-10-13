# Native Web export and browser acceptance

Use this workflow for Web builds that fail to load, need input/storage validation or need a reproducible browser baseline. Native export success, HTTP delivery, browser interaction and measured performance are separate outcomes. Preserve the project's renderer and presets unless an evidenced target limitation requires a change.

## Prepare and export

1. Record actual Godot version, Web preset, renderer, template variant, thread/extension/PWA options and target browser. Verify matching template version and build variant.
2. Copy [the native Web example](../assets/examples/web/project.godot) to EXAMPLE or use the user's intended project. Its Compatibility renderer and real Button exercise only its own `user://native_web_acceptance.cfg`. Invalid existing save data blocks further writes rather than being overwritten.
3. Create a Web preset with ConfigFile or edit the selected existing preset. The example uses `export_filter="all_resources"`, explicit empty `include_filter`, `exclude_filter=".godot-plugin/*"`, `custom_template/release` pointing to a matching `web_nothreads_release.zip`, `variant/thread_support=false`, `variant/extensions_support=false`, `html/export_icon=false` and `progressive_web_app/enabled=false`. Use actual supported options/paths; do not enable threading to hide another failure.
4. Create fresh BUILD/OUT directories, import and export to BUILD/index.html. Check full logs, exit code and output files.

```text
GODOT --headless --path EXAMPLE --import --log-file OUT/import.log
GODOT --headless --path EXAMPLE --export-release "Web" BUILD/index.html --log-file OUT/export.log
```

Sources: [Web export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html), [matching exporter options](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/platform/web/export/export_plugin.cpp).

## Serve through Godot

Serve only the copied export directory:

```text
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/skills/godot-export/scripts/serve_web.gd --log-file OUT/server.log -- --root BUILD --out OUT --port 8080 --seconds 300
```

The helper binds only 127.0.0.1, prints `GODOT_WEB_SERVER_READY` with its URL, streams flat allowlisted artifact files and exits after the requested 1–3600 seconds. It allows GET/HEAD and rejects foreign Host names, links/reparse files, nested paths, percent escapes, oversized headers and write methods. Use plain ASCII export filenames such as `index.html`; encoded names and nested/PWA asset trees are outside its scope. Stop only the task-owned process for early cleanup. This is a temporary HTTP test tool, not a persistent service, MCP bridge or production server.

COOP/COEP headers support isolation requirements, but successful nonthreaded delivery does not prove threaded/extension builds work. The server report proves bounded serving only. Native protocol/lifetime checks in `tests/integration/web_server.gd` need no Python/Node runtime. APIs: [TCPServer](https://docs.godotengine.org/en/4.7/classes/class_tcpserver.html), [StreamPeerTCP](https://docs.godotengine.org/en/4.7/classes/class_streampeertcp.html), [DirAccess](https://docs.godotengine.org/en/4.7/classes/class_diraccess.html).

## Exercise the actual browser

1. Open the reported HTTP URL in the intended browser. Verify rendered startup and console/network failures; file:// is not equivalent.
2. Record initial count/restored count. Click **Collect and save**, then activate the focused button with Enter. Require two distinct increments and readback, not an emitted signal or a direct JavaScript gameplay call.
3. After browser storage synchronization, reload at the same origin. Require the saved count as `restored_count` and zero `saves_this_session`. In-memory readback and `OS.is_userfs_persistent()` alone do not prove cross-reload durability. Test private-mode/denial behavior separately when requested; do not change browser settings to force acceptance.
4. Save screenshot and console evidence. The example emits `GODOT_WEB_ACCEPTANCE` and exposes a JSON fixture summary as `window.godotAcceptance`; inspect read-only and do not mutate it to create a pass.
5. Separate canvas/input/storage acceptance from real audio, mobile browsers, threaded builds, offline/PWA, accessibility and frame pacing. This no-audio fixture does not certify sound.

Storage: [OS persistence](https://docs.godotengine.org/en/4.7/classes/class_os.html#class-os-method-is-userfs-persistent), [Web export limitations](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html), [JavaScriptBridge](https://docs.godotengine.org/en/4.7/classes/class_javascriptbridge.html).

## Diagnose before changing settings

| Failure | Ordered observations | Repair and retest |
|---|---|---|
| Blank/loading forever | Console/network -> HTML/JS/WASM/PCK status/MIME -> renderer -> preset/template variant | Correct the failed request/variant; cold browser startup and real interaction |
| Threads/extensions cannot initialize | Preset -> secure context -> cross-origin isolation -> template/native target | Correct the evidenced header/build mismatch; test the intended variant |
| Input works only in editor | Canvas focus -> actual DOM input -> viewport coordinates -> action mapping | Correct focus/mapping; pointer and keyboard independently |
| Save resets on reload | Origin -> persistence availability -> path -> sync -> fresh readback | Correct path/lifecycle and prove same-origin reload; preserve bad saves |
| Browser silent | User activation -> player state -> playback mode/effects -> console | Use audio/device acceptance; this no-audio fixture cannot certify it |

For performance, use godot-performance: collect actual transferred bytes, navigation-to-interactive time and fixed-workload frame/loading distributions before/after. `ready_since_start_usec` measures local script initialization only, not download or first-interactive time. Separate cold/warm cache and debug/release, preserving input/storage/visual equivalence.
