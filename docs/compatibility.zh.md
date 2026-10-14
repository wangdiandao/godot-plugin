# 宿主兼容性

[English](compatibility.md) | **简体中文**

[文档首页](README.zh.md) · [快速开始](getting-started.zh.md) · [证据索引](evidence.zh.md)

本文件保留按版本记录的兼容历史。开头的 0.1.1 章节描述当时的清单；23 个 Skill 的包及后续验证批次参见[当前 Skill 目录](skill-catalog.zh.md)和[证据索引](evidence.zh.md)。

0.1.1 在 Codex Desktop/CLI 之外，新增 Claude Code、Cursor 和 Gemini CLI 原生包装。各宿主共用同一套 18 个 `skills/<name>/SKILL.md` 文件、GDScript 工具、示例和相对引用，没有引入适配服务器或新的运行环境。Codex Desktop 可以直接从 Plugins 页面添加 GitHub 市场；CLI 注册是替代方式。

| 宿主 | 清单与发现方式 | 安装 |
|---|---|---|
| Codex Desktop / CLI | 根 Agent Plugins 清单及 `.codex-plugin/plugin.json`；`.agents/plugins/marketplace.json` | 注册本地市场，然后安装 |
| Claude Code | `.claude-plugin/plugin.json`；默认发现 `skills/` | `claude --plugin-dir`，或在支持的版本中将完整插件放入用户 skills 目录 |
| Cursor | `.cursor-plugin/plugin.json`；默认发现 `skills/`；也支持根 Agent Plugins 清单 | 将完整包复制到 `~/.cursor/plugins/local/godot-plugin` 并重新加载 |
| Gemini CLI | `gemini-extension.json`；发现扩展的 `skills/` | `gemini extensions install` 或开发用 `link` |

参见[英文安装说明](../README.md)或[简体中文安装说明](../README.zh.md)。命令和 UI 名称取决于安装的宿主版本。须保持完整插件根目录可读：`../../shared/references/execution.md` 等引用有意访问同一包中的共享资源。不支持将单个 Skill 复制到另一布局。路径从实际加载的 Skill 位置解析，不从游戏项目的工作目录解析。

Gemini 激活 Skill 时将单个 Skill 目录加入允许路径。使用 `--include-directories`（或支持的会话中的 `/directory add`）包含已加载扩展的根目录，以读取同级共享资源。安装副本通常位于 `~/.gemini/extensions/godot-plugin`；链接使用源目录。参见 [Skill 激活](https://geminicli.com/docs/cli/skills/)与[工作区目录命令](https://geminicli.com/docs/reference/commands/)。

## 验证范围

宿主清单和归档检查与模型路由、游戏验收分开。最初 2026-10-11 的 Godot 行为结果仍是 [validation.zh.md](validation.zh.md) 中的历史证据，并非在新宿主下重新执行的结果。

以下检查于 2026-10-12 在较早、未发布的 0.2.0 开发快照上执行，环境为 Windows、Godot `4.7.2.stable.official.ed1daf0bf`、Codex CLI `0.142.5`、Claude Code `2.1.198`。0.1.1 保留这些运行文件；发布检查另行记录于下文。

| 检查 | 实际结果与范围 |
|---|---|
| `python -X utf8 tests/validate_structure.py --root PLUGIN --schema SCHEMA --report REPORT` | 源码树和搬移后的源码 ZIP 均通过；检查清单、根 Agent Plugins schema、语言切换、全部 Skill 链接、元数据和本地 Markdown 引用 |
| `claude plugin validate --strict PLUGIN/.claude-plugin/plugin.json` | 源码树和搬移后的安装 ZIP 均通过；验证清单，不验证模型驱动的技能选择 |
| `claude --plugin-dir PLUGIN plugin details godot-plugin` | 搬移后的安装副本在隔离 Claude 配置目录下通过；清单报告 0.2.0 和全部 18 个 Skills，无 agents、hooks 或 servers |
| Cursor 官方 `schemas/plugin.schema.json` 配合 Python `jsonschema.validate` | `.cursor-plugin/plugin.json` 通过；schema 来自官方 Cursor 插件仓库 |
| Codex `plugin marketplace add PLUGIN`、`plugin add godot-plugin@godot-native-local --json`、`plugin list --marketplace godot-native-local --json` | 使用搬移后的安装目录及隔离 Codex home 通过；报告 0.2.0 已安装并启用 |
| `GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/package.gd --log-file LOG -- --root PLUGIN --out OUT` | 安装/源码 ZIP 创建、必需文件、禁入路径和逐文件 SHA256 读回均通过 |
| 搬移后的源码 `shared/scripts/run_checks.gd` 配合 `tests/cases.json` | 全部 31 案例通过，包括真实渲染和预期失败检测 |
| 搬移后的安装副本 `shared/scripts/run_checks.gd` 配合 `tests/cases.json` 中 22 个随包案例 | 全部 22 案例通过；项目/脚本指向解压后的安装副本，包括两个游戏、真实渲染和预期 headless 截图拒绝 |

`PLUGIN`、`SCHEMA`、`REPORT`、`GODOT`、`LOG` 和 `OUT` 代表执行时实际提供的绝对路径。安装清单选择项目位于 `../skills/` 下的案例，并从解压后的包解析项目/脚本路径；夹具案例留在源码套件。原始报告和日志位于维护者被忽略的 `artifacts/multi-agent-3/` 目录；PR 记录命令和结果供审核。负例只有检测到预期失败才算通过。

本维护环境未安装 Cursor 和 Gemini CLI。其包装遵循官方文档；安装 UI、运行时发现和模型驱动流程仍需在对应宿主中验证。Codex Desktop UI 交互及 Claude Code 模型驱动流程也不属于包装检查范围。

## 0.1.1 发布检查（2026-10-12）

全部五份宿主清单现标记为 0.1.1。[更新日志](../CHANGELOG.zh.md)和两份 README 均纳入安装/源码归档。Codex Desktop 说明从 Plugins 页面添加仓库市场开始；该流程依据所有者的桌面使用反馈修正，不宣称进行了新的 UI 自动化测试。

源码结构/根 schema/Markdown 链接检查及 Claude 严格清单校验再次通过。两份 0.1.1 ZIP 均通过原生创建、必需/禁入内容检查及逐文件 SHA256 读回。解压到新的中文/空格路径后，源码结构检查通过；隔离 Codex 注册/安装/列举报告 0.1.1 已启用；隔离 Claude 发现报告 0.1.1 及全部 18 个 Skills。安装 workflow 示例和源码 physics 示例均退出 0，提供明确报告且引擎日志无错误。0.1.1 的 Cursor 官方清单 schema 也经过检查。

归档内每个 `skills/` 和 `shared/` 成员的字节与此前用于上述 31/22 案例套件的包一致。本次元数据/文档发布没有重跑完整套件。原始发布检查记录位于被忽略的 `artifacts/release-0.1.1/`；实际命令/结果和发布 SHA256 值记录于发布 PR 及公开资产。不可用宿主及模型路由的限制仍如上所述。

## 官方来源

- [OpenAI 插件包装与本地市场](https://developers.openai.com/plugins/build/plugins)
- [Claude Code 插件清单](https://code.claude.com/docs/en/plugins-reference)与[本地开发](https://code.claude.com/docs/en/plugin-marketplaces)
- [Cursor 本地插件导入](https://cursor.com/docs/plugins)与[清单/发现参考](https://cursor.com/docs/reference/plugins)
- [Gemini CLI 扩展清单、Skills 与安装](https://geminicli.com/docs/extensions/reference/)

文档于 2026-10-12 使用 Context7 和官方来源核对。插件不安装 Context7。

## 0.2.0 已记录工作（2026-10-13）

全部五份宿主清单标记为 0.2.0，并发现实际 23 个 Skill。此前 0.1.1 及未发布快照的检查为历史记录。本轮子代理语义路由和原生代表任务记录于[任务评估](research/task-evaluation.md)；它们不认证安装宿主后的隐式自动加载。C#/GDExtension 的条件性前置要求不会成为普通 GDScript 任务的依赖。本次打包和搬移证据随交付单独记录；不创建公开发布。

本轮本地 0.2.0 检查：Claude 严格清单校验通过。安装/源码归档成员排除及 SHA256 读回通过；搬移后的源码结构/schema/本地链接通过 1247 项检查及 13 项研究单元测试。搬移后的安装 architecture 通过 16 项断言；搬移后的源码七个选定案例，包括真实正常编辑器事务，均符合预期。原生编译 release 从零缓存经过已记录的启动登记/导入/运行，完成 13 项断言。这些是本轮运行，与上文历史宿主发现检查分开。已识别 Codex CLI 0.142.5；不据此推断新的安装宿主自动加载结果。

## 0.2.1 原生工作流更新（2026-10-13）

全部五份宿主清单标记为 0.2.1，保留同样 23 个 skills；市场标识/来源不变。本次证据见[原生工作流验证](native-workflows-validation.json)。十个受影响的原生案例在 Windows Godot 4.7.2 上通过 159 项断言，源码归档搬移后同样案例通过。安装归档的本地化示例通过 24 项断言，其原生 HTTP 工具完成有界生命周期。真实 Chrome 非线程 Web 指针/键盘交互及重新加载后的保存数量恢复通过。

这些检查不认证新安装的 Desktop 隐式自动加载、其它宿主、其它浏览器/平台、线程/PWA 构建、音频或性能提升。可选回环 HTTP 测试进程显式退出，不引入 MCP/编辑器桥接或 Python/Node 运行依赖。上文 0.2.0/0.1.1 历史记录仍独立保留。本地 ZIP 为离线副本，不发布标签或 GitHub Release。
