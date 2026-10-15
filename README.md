# godot-plugin

**English** | [简体中文](README.zh.md)

[Documentation](docs/README.md) · [Getting started](docs/getting-started.md) · [Skill catalog](docs/skill-catalog.md) · [Validation evidence](docs/evidence.md)

Native Godot development skills for **Codex Desktop / CLI, Claude Code, Cursor, and Gemini CLI**. Includes 24 focused Skills, native GDScript helpers, and runnable examples for GDScript2D/3D games plus architecture, performance, editor tools and conditional C#/GDExtension tasks.

Use your chosen agent, the **standard Godot editor distribution**, and operating-system tools. The default game workflow adds no MCP server, Python or Node runtime dependency; editor-tool and language-extension tasks use their explicitly documented prerequisites. Context7 is an author research tool, not a runtime dependency.

The engine baseline is **Godot 4.7.2 stable**, checked on 2026-10-11 against the official release, version-matched documentation, source, and binary. See the [validation report](docs/validation.md), [capability index](docs/capabilities.json), and [host compatibility notes](docs/compatibility.md). Host packaging support does not imply tested model-driven workflows in every agent.

## Installation

Install version **0.3.0** from the repository marketplace or a clean source checkout. Keep the entire `godot-plugin/` directory, including hidden manifests, `skills/`, `shared/`, and `docs/`. Copying entrypoints alone breaks references. See [CHANGELOG](CHANGELOG.md).

For local installation, use `git clone https://github.com/wangdiandao/godot-plugin.git`, then follow the host-specific steps below. Use a clean checkout for directory copies; do not copy a development workspace containing `artifacts/`, `dist/`, or engine caches.

The PowerShell examples use `C:\Tools\godot-plugin` as the extracted directory. Replace it with your actual absolute path. On macOS/Linux, use equivalent paths and shell commands. Install a current agent release with the documented plugin features, and keep Godot on the machine where the agent executes commands.

### Codex Desktop

1. Open **Plugins** in Codex Desktop.
2. Open the marketplace controls and choose **Add marketplace** (labels may vary by desktop version).
3. Enter the repository URL `https://github.com/wangdiandao/godot-plugin` and add it. The repository includes `.agents/plugins/marketplace.json`; no separate CLI registration is required for this desktop flow.
4. Select **Godot** (`godot-native-local`), open **Godot** (`godot-plugin`), and install/enable it.
5. Open your Godot project in a new local chat and ask: “Use `$godot-workflow` to inspect this project and report the installed Godot version.” If the installed plugin is not picked up, restart the desktop and start a new chat.

For an extracted local ZIP or clients without **Add marketplace**, use the Codex CLI registration/install steps below, then restart the desktop. The CLI and desktop must use the same user and Codex home configuration; registration inside WSL or on another machine does not register a Windows desktop marketplace. Inspect `codex plugin marketplace list` when troubleshooting that alternative. You can also open the extracted `godot-plugin` directory as a local project to discover its repository-scoped marketplace.

See the [official local marketplace guide](https://developers.openai.com/plugins/build/plugins). No cache editing or public directory publishing is required.

### Codex CLI

```powershell
codex plugin marketplace add "C:\Tools\godot-plugin"
codex plugin add godot-plugin@godot-native-local
codex plugin list --marketplace godot-native-local --json
```

Start a new Codex session in your game project. Invoke `$godot-workflow` or a domain Skill, or describe your task naturally. The marketplace entry's `source.path` resolves relative to the marketplace root, not `.agents/plugins/`.

### Claude Code

From your game project, load the complete plugin for a session:

```powershell
claude --plugin-dir "C:\Tools\godot-plugin"
```

The `.claude-plugin/plugin.json` manifest identifies the plugin; Claude Code discovers the 24 Skills under `skills/`. Invoke `/godot-plugin:godot-workflow`, `/godot-plugin:godot-physics`, or describe a task naturally.

For persistence on current versions that support plugins in skills directories, copy the **complete extracted installation directory** to `~/.claude/skills/godot-plugin`, then start a new session. Preserve its nested manifests and shared directories. Check `/plugin` for loading errors; older clients can use `--plugin-dir` on each launch. See [local development](https://code.claude.com/docs/en/plugin-marketplaces) and the [manifest reference](https://code.claude.com/docs/en/plugins-reference).

### Cursor

Copy the **complete extracted installation directory** to `~/.cursor/plugins/local/godot-plugin`. On Windows, if the destination does not already exist:

```powershell
$cursorLocalPlugins = Join-Path $env:USERPROFILE ".cursor\plugins\local"
if (Test-Path -LiteralPath (Join-Path $cursorLocalPlugins "godot-plugin")) { throw "Plugin already exists; review it before updating." }
New-Item -ItemType Directory -Force -Path $cursorLocalPlugins | Out-Null
Copy-Item -LiteralPath "C:\Tools\godot-plugin" -Destination $cursorLocalPlugins -Recurse
```

Restart Cursor or run **Developer: Reload Window**. Open **Customize**, confirm the Godot Skills are present, then use Agent mode in your game project and request `godot-workflow`. The plugin provides `.cursor-plugin/plugin.json` with default `skills/` discovery; the root `plugin.json` also follows the supported Agent Plugins standard.

Your organization must allow local plugin imports. An installed marketplace plugin with the same name takes precedence. Cursor skips local-plugin symlinks targeting directories outside its local plugin directory, so copy the actual directory. See [local installation](https://cursor.com/docs/plugins) and the [plugin reference](https://cursor.com/docs/reference/plugins).

### Gemini CLI

Install the complete directory as an extension:

```powershell
gemini extensions install "C:\Tools\godot-plugin"
gemini extensions list
```

Restart Gemini CLI in your game project. Run `/skills list` to confirm the Godot Skills appear, then ask it to use `godot-workflow` or a domain Skill. The root `gemini-extension.json` identifies the extension; Gemini discovers `skills/` without an MCP server. For development, `gemini extensions link "C:\Tools\godot-plugin"` links the directory instead of installing a copy. See the [official extension reference](https://geminicli.com/docs/extensions/reference/).

Skill activation grants access to that Skill's directory. This plugin also uses sibling `shared/` and `docs/` resources, so include the **loaded extension root** when starting Gemini in your game project:

```powershell
gemini --include-directories "$env:USERPROFILE\.gemini\extensions\godot-plugin"
```

That is the default installed location; use the actual extension path reported by `gemini extensions list` if it differs. For a linked extension, include its source directory instead. An existing session can use `/directory add <absolute-extension-root>` where allowed. See [workspace directory commands](https://geminicli.com/docs/reference/commands/).

### Updates and first-use checks

Keep source/extracted directories available for local registrations and links. Refresh Codex with its supported `marketplace upgrade` / `plugin add` flow; replace complete local Claude Code or Cursor copies after reviewing their existing directories; use `gemini extensions update godot-plugin` for an installed Gemini extension. Restart the host. Do not mix versions or edit generated host caches.

On first use, ask the agent to report the plugin location, discover Godot, run `--version`, and read the execution conventions before changing the game. It needs access to the complete plugin and permission to run Godot; rendering checks also need a display/GPU. A portable engine in an unreadable or undiscoverable location must be reported as missing.

## Usage

- “Create a Godot 2D game with a menu, collectibles, sound, and saving; export and verify a Windows build.”
- “Find why the character passes through walls, fix the collision, and verify it.”
- “Build a native 3D level, bake navigation, and test enemy paths.”
- “Check whether this editor operation has a public scripting API in my Godot version.”

Use a domain Skill for isolated tasks and `godot-workflow` for complete games or changes across systems. The agent discovers the engine, checks its version, edits the project, and runs native verification. Setting PATH or opening the editor manually is unnecessary when the engine can be discovered.

## Skills

| Skill | Tasks |
|---|---|
| [godot-workflow](skills/godot-workflow/SKILL.md) | Complete games, iteration across systems, staged acceptance |
| [godot-project](skills/godot-project/SKILL.md) | Creation, takeover, migration, input, Autoload |
| [godot-api](skills/godot-api/SKILL.md) | Versions, CLI, public APIs, source verification |
| [godot-gdscript](skills/godot-gdscript/SKILL.md) | Types, signals, async, code organization |
| [godot-scenes](skills/godot-scenes/SKILL.md) | Ownership, instancing, inheritance, persistence |
| [godot-assets](skills/godot-assets/SKILL.md) | Native import, reimport, procedural resources |
| [godot-2d](skills/godot-2d/SKILL.md) | Tiles, maps, cameras, 2D content |
| [godot-3d](skills/godot-3d/SKILL.md) | Meshes, models, cameras, 3D content |
| [godot-physics](skills/godot-physics/SKILL.md) | Movement, collision, triggers, raycasts |
| [godot-navigation](skills/godot-navigation/SKILL.md) | Navigation baking, paths, agents |
| [godot-ui](skills/godot-ui/SKILL.md) | Menus, layout, focus, themes, localization |
| [godot-animation](skills/godot-animation/SKILL.md) | Animation libraries, property animation, state machines |
| [godot-rendering](skills/godot-rendering/SKILL.md) | Shaders, materials, lighting, visual checks |
| [godot-audio](skills/godot-audio/SKILL.md) | Playback, buses, effects, PCM audio |
| [godot-data](skills/godot-data/SKILL.md) | Settings, saves, migration, malformed data |
| [godot-multiplayer](skills/godot-multiplayer/SKILL.md) | Native networking, RPC, spawning, replication |
| [godot-validation](skills/godot-validation/SKILL.md) | Parsing, behavior, input, screenshots, diagnostics |
| [godot-export](skills/godot-export/SKILL.md) | Official templates, presets, builds, artifact checks |
| [godot-gdextension](skills/godot-gdextension/SKILL.md) | Native extension builds, ABI and loading diagnosis |
| [godot-csharp](skills/godot-csharp/SKILL.md) | Godot.NET builds, bindings and managed debugging |
| [godot-editor-tools](skills/godot-editor-tools/SKILL.md) | Tool scripts, EditorPlugin transactions and lifecycle |
| [godot-performance](skills/godot-performance/SKILL.md) | Measured CPU/GPU/memory diagnosis and comparison |
| [godot-architecture](skills/godot-architecture/SKILL.md) | Module contracts, composition, lifecycle and signals |
| [godot-ai](skills/godot-ai/SKILL.md) | Enemy decisions, perception contracts, utility scoring and bounded planning |

Skills load on demand; there is no hidden execution state or requirement to load all of them.

## Examples and tools

Each Skill has an independently runnable `assets/examples/minimal/` project. Complete games are in `skills/godot-workflow/assets/examples/game-2d/` and `game-3d/`, using native nodes, geometry, and sound. `GODOT`, `PLUGIN`, `PROJECT`, and `OUT` in command examples are paths resolved at execution time; complete calls are in each Skill's `references/native.md`.

| Script | Purpose |
|---|---|
| `shared/scripts/inspect_environment.gd` | Engine, platform, public bindings, selected class APIs |
| `shared/scripts/inspect_project.gd` | Resource loading, scene structure, dependencies, errors |
| `shared/scripts/run_checks.gd` | Isolated processes, wall-clock timeout, results, log checks |
| `shared/scripts/capture_scene.gd` | Real rendered screenshots and PNG readback |
| `shared/scripts/prepare_templates.gd` | Official template download, SHA256, version, overwrite protection |

`common.gd` is internal shared code. `shared/host/` avoids starting the target project's Autoloads. Helpers establish no persistent service. Test/helper output defaults to the project's `.godot-plugin/` or an explicit external directory and must stay out of game exports.

## Limits

Native diagnosis examples exercise fault, repair, repeated success and excluded conditions for triggers, navigation, pointer input and audio routing. See [staged native workflow evidence](docs/native-workflows-validation.json); device/visual and installed-host discovery boundaries remain explicit.

The existing UI skill also includes a [native localization workflow](skills/godot-ui/references/localization.md) and a standalone cold-start catalog example. Catalog, formatting and language-refresh checks are distinct from font/layout quality.

[Web acceptance](skills/godot-export/references/web.md) uses a temporary loopback HTTP helper implemented with Godot TCPServer and a real exported game. It adds no MCP, editor bridge, Python or Node runtime dependency.

- Headless checks cover logic/resources. Shaders, visuals, and GPU features need real rendering. Audio state checks do not prove listening quality.
- Godot 4.7.2 has no public GDScript binding for `LightmapGI.bake()`; the plugin does not invent one.
- Native desktop workflows use the standard editor. Android/iOS require SDKs, signing, and host platforms; `.blend` import requires Blender.
- Native content automation does not guarantee arbitrary artwork, commercial game quality, or every platform feature.
- Existing engine behavior evidence is from Windows. The native Web fixture also passes actual Chrome pointer/keyboard input and save restoration after reload. Other browsers, threaded/PWA variants, Linux/macOS, mobile, public networking and installed-host implicit routing remain untested; see the staged evidence.

## Contributing and distribution

The plugin uses the official Godot Engine icon (Andrea Calabró, CC BY 4.0).
See [icon attribution](assets/README.md). This community plugin is not affiliated with or endorsed by the Godot developers or the Godot Foundation.

Read [CONTRIBUTING.md](CONTRIBUTING.md): open/associate an Issue before editing; external contributors fork and submit a PR. Maintainers review external contributions. Owner-initiated changes are reviewed, corrected, and validated before merging, with findings and results recorded. Code and original examples use the [MIT license](LICENSE).

The installation ZIP includes all host manifests, both READMEs, both changelog and contribution-guide versions, Skills, shared files, examples, and capability/validation documentation. The source ZIP also includes tests and contribution templates. Generated artifacts, research downloads, `dist/`, engine caches, and local `AGENTS.md` are excluded. Local archives remain optional offline copies; GitHub Releases are not used to distribute this plugin.

See [authoring contracts](docs/authoring.md), [research sources](docs/research.md), [validation](docs/validation.md), and the [official Godot baseline release](https://github.com/godotengine/godot/releases/tag/4.7.2-stable).


C# tasks additionally require matching Godot.NET and a .NET SDK; GDExtension tasks require bindings, a C++ compiler/build tools and a binding generator. The default native path remains available.

Priority task recipes and current scoped evidence are indexed in [priority skill validation](docs/priority-skills-validation.md). These include protected playable-example saves and ten additional isolated fixtures; the original 23 skill identities remain stable.

[Community practices and current validation](docs/community-practices.md).
