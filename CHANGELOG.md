# Changelog

## [0.1.1] - 2026-10-12

### Added

- Agent Plugin support for **Claude Code, Cursor, and Gemini CLI**, sharing the existing 18 Godot Skills, native GDScript helpers, and examples.
- Host-specific plugin/extension manifests and installation, discovery, update, and shared-resource access instructions.
- English `README.md` and Simplified Chinese `README.zh.md` with language-switch links.
- Host compatibility notes separating packaging/discovery checks from untested model-driven workflows.
- Manifest consistency, bilingual documentation, changelog, archive contents, and exclusion checks; both release ZIPs include all host manifests and the changelog.

### Changed

- Codex Desktop installation now starts in **Plugins → Add marketplace**, using the repository URL. Codex CLI registration remains an alternative.
- Synchronize all host manifests and release archives to **0.1.1**. The earlier 0.2.0 development version was not published as a release.

### 简体中文

- 新增 **Claude Code、Cursor、Gemini CLI 等 Agent Plugin 支持**，共用原有 18 个 Godot Skills、原生 GDScript 工具与示例。
- 新增宿主清单、安装与更新说明，以及带语言切换链接的中英文 README。
- 修正 Codex Desktop 安装教程：在插件页直接添加市场，CLI 作为替代方式。
- 发布版本统一为 **0.1.1**，两份安装/源码 ZIP 均包含 CHANGELOG 与全部宿主清单。

## [0.1.0] - 2026-10-12

- Initial Godot native development baseline for Codex with 18 Skills, GDScript helpers, runnable examples, and validation/export workflows.
- Contribution guidelines, Issue/PR templates, and MIT licensing.

[0.1.1]: https://github.com/wangdiandao/godot-plugin/releases/tag/v0.1.1
[0.1.0]: https://github.com/wangdiandao/godot-plugin/tree/v0.1.0
