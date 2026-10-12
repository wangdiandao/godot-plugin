# Host compatibility

Version 0.2.0 adds native packaging for Claude Code, Cursor, and Gemini CLI alongside Codex Desktop/CLI. All hosts share the same 18 `skills/<name>/SKILL.md` files, GDScript helpers, examples, and relative references. No adapter server or new runtime is introduced.

| Host | Manifest and discovery | Installation |
|---|---|---|
| Codex Desktop / CLI | Root Agent Plugins manifest plus `.codex-plugin/plugin.json`; `.agents/plugins/marketplace.json` | Register the local marketplace, then install |
| Claude Code | `.claude-plugin/plugin.json`; default `skills/` discovery | `claude --plugin-dir` or a complete plugin in the user's skills directory on supported versions |
| Cursor | `.cursor-plugin/plugin.json`; default `skills/` discovery; also supports the root Agent Plugins manifest | Copy the complete package into `~/.cursor/plugins/local/godot-plugin` and reload |
| Gemini CLI | `gemini-extension.json`; extension `skills/` discovery | `gemini extensions install` or development `link` |

See [English installation instructions](../README.md) or [简体中文安装说明](../README.zh.md). Commands and UI names depend on the installed host version. Keep the complete plugin root readable: references such as `../../shared/references/execution.md` intentionally reach shared resources inside the same package. Copying individual Skills to another layout is unsupported. Resolve paths from the loaded Skill's actual location, not from the game project's working directory.

Gemini's Skill activation adds the individual Skill directory to allowed paths. Include the loaded extension root with `--include-directories` (or `/directory add` in supported sessions) to read the sibling shared resources. Installed copies normally live under `~/.gemini/extensions/godot-plugin`; links use their source directory. See [Skill activation](https://geminicli.com/docs/cli/skills/) and [workspace directory commands](https://geminicli.com/docs/reference/commands/).

## Verification scope

Host manifest and archive checks are separate from model routing and game acceptance. The original 2026-10-11 Godot behavior results remain historical evidence in [validation.md](validation.md); they are not reruns under the new hosts.

The following checks were run on 2026-10-12 on Windows with Godot `4.7.2.stable.official.ed1daf0bf`, Codex CLI `0.142.5`, and Claude Code `2.1.198`:

| Check | Actual result and scope |
|---|---|
| `python -X utf8 tests/validate_structure.py --root PLUGIN --schema SCHEMA --report REPORT` | Passed on the source tree and relocated source ZIP; checks manifests, root Agent Plugins schema, language links, all Skill links, metadata, and local Markdown references |
| `claude plugin validate --strict PLUGIN/.claude-plugin/plugin.json` | Passed on the source tree and relocated installation ZIP; validates the manifest, not model-driven skill selection |
| `claude --plugin-dir PLUGIN plugin details godot-plugin` | Passed on the relocated installation with an isolated Claude config directory; inventory reports version 0.2.0 and all 18 Skills, with no agents, hooks, or servers |
| Cursor official `schemas/plugin.schema.json` with Python `jsonschema.validate` | Passed for `.cursor-plugin/plugin.json`; schema fetched from the official Cursor plugins repository |
| Codex `plugin marketplace add PLUGIN`, `plugin add godot-plugin@godot-native-local --json`, `plugin list --marketplace godot-native-local --json` | Passed using a relocated installation directory and an isolated Codex home; version 0.2.0 reported installed and enabled |
| `GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/package.gd --log-file LOG -- --root PLUGIN --out OUT` | Installation and source ZIP creation, required files, excluded paths, and per-file SHA256 readback passed |
| Relocated source `shared/scripts/run_checks.gd` with `tests/cases.json` | All 31 cases passed, including real rendering and expected failure detection |
| Relocated installation `shared/scripts/run_checks.gd` with the 22 bundled cases from `tests/cases.json` | All 22 cases passed; projects/scripts point at the extracted installation, including both games, real rendering, and the expected headless capture refusal |

`PLUGIN`, `SCHEMA`, `REPORT`, `GODOT`, `LOG`, and `OUT` stand for actual absolute paths supplied at execution time. The installation manifest selects cases whose projects are under `../skills/` and resolves their project/script paths against the extracted package; fixture cases stay in the source suite. Raw reports and logs are in the maintainer's ignored `artifacts/multi-agent-3/` directory; the PR records commands and results for reviewers. Negative cases pass only when the expected failure is detected.

Cursor and Gemini CLI are not installed in this maintenance environment. Their packaging follows official documentation; their installation UI, runtime discovery, and model-driven workflows require verification in those hosts. Codex Desktop UI interactions and Claude Code model-driven workflows are also outside the packaging checks.

## Official sources

- [OpenAI plugin packaging and local marketplaces](https://developers.openai.com/plugins/build/plugins)
- [Claude Code plugin manifests](https://code.claude.com/docs/en/plugins-reference) and [local development](https://code.claude.com/docs/en/plugin-marketplaces)
- [Cursor local plugin imports](https://cursor.com/docs/plugins) and [manifest/discovery reference](https://cursor.com/docs/reference/plugins)
- [Gemini CLI extension manifests, Skills, and installation](https://geminicli.com/docs/extensions/reference/)

Documentation was checked on 2026-10-12, using Context7 and the official sources. Context7 is not installed by the plugin.
