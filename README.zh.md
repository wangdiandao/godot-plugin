# godot-plugin

[English](README.md) | **简体中文**

面向 **Codex Desktop / CLI、Claude Code、Cursor 和 Gemini CLI** 的 Godot 原生开发插件：23 个可独立触发的 Skills、原生 GDScript 辅助脚本和可运行示例，覆盖 GDScript 2D/3D 开发，并提供架构、性能、编辑器工具及条件式 C#/GDExtension 工作流。

运行需要所选 Agent、**Godot 标准编辑器发行版和操作系统自带能力**。插件不新增 MCP Server、Godot 编辑器插件、Python 或 Node 运行依赖；Agent 本身的安装要求仍然适用。Context7 仅用于作者研究，不是用户运行依赖。

基线为 **Godot 4.7.2 stable**，2026-10-11 核对官方发行版、匹配版本文档、源码和真实二进制。实际通过范围见[验证报告](docs/validation.md)、[能力索引](docs/capabilities.json)和[宿主兼容说明](docs/compatibility.md)。支持宿主安装格式不代表已经在每个 Agent 中验证完整模型工作流。

## 安装

当前版本为 **0.2.2**，通过仓库市场或干净源码 checkout 安装。保留整个 `godot-plugin/` 目录及隐藏清单、`skills/`、`shared/`、`docs/`，只复制入口会破坏引用。更新内容见 [CHANGELOG](CHANGELOG.md)。

本地安装使用 `git clone https://github.com/wangdiandao/godot-plugin.git`，再按下方宿主说明操作。复制目录时使用干净 checkout，不要复制带有 `artifacts/`、`dist/` 或引擎缓存的开发工作区。

以下 PowerShell 示例假设插件解压到 `C:\Tools\godot-plugin`，请替换为实际绝对路径。macOS/Linux 使用对应路径和 shell 命令。Agent 应更新到支持所述插件机制的版本，Godot 安装在实际执行命令的机器上。

### Codex Desktop

1. 在 Codex Desktop 打开 **Plugins（插件）** 页。
2. 打开市场管理入口，选择 **Add marketplace（添加市场）**；不同桌面版本的标签可能不同。
3. 输入仓库地址 `https://github.com/wangdiandao/godot-plugin` 并添加。仓库已包含 `.agents/plugins/marketplace.json`，此桌面流程无需另行执行 CLI 注册命令。
4. 选择 **Godot Native Development** 市场（`godot-native-local`），打开 `godot-plugin` 并安装/启用。
5. 在本地游戏项目中新建聊天，输入：“使用 `$godot-workflow` 检查当前项目，报告已安装的 Godot 版本。”若新安装的插件未被加载，重启桌面端后重新开聊天。

使用本地解压 ZIP，或客户端没有 **Add marketplace** 时，可采用下面的 Codex CLI 注册/安装步骤，再重启桌面端。CLI 和桌面端必须使用同一用户及 Codex home 配置；在 WSL 或另一台机器注册，不会注册到 Windows 桌面端。该替代流程可通过 `codex plugin marketplace list` 排查。也可将解压后的 `godot-plugin` 目录作为本地项目打开，以发现仓库范围的市场。

参见 [OpenAI 官方本地市场指南](https://developers.openai.com/plugins/build/plugins)，无需修改插件缓存或发布到公共插件目录。

### Codex CLI

```powershell
codex plugin marketplace add "C:\Tools\godot-plugin"
codex plugin add godot-plugin@godot-native-local
codex plugin list --marketplace godot-native-local --json
```

在游戏项目中新开 Codex 会话，可显式调用 `$godot-workflow`、领域 Skill，或直接描述需求。市场条目的 `source.path` 相对于市场根目录解析，不是相对于 `.agents/plugins/`。

### Claude Code

在游戏项目中启动并加载整个插件：

```powershell
claude --plugin-dir "C:\Tools\godot-plugin"
```

`.claude-plugin/plugin.json` 标识插件，Claude Code 自动发现 `skills/` 下的 23 个 Skills。使用 `/godot-plugin:godot-workflow`、`/godot-plugin:godot-physics` 或自然语言发起任务。

支持 Skills 目录内插件的当前版本，也可将**完整解压后的安装目录**复制到 `~/.claude/skills/godot-plugin`，新会话中自动加载。保留内部清单与共享目录。通过 `/plugin` 检查加载错误；旧客户端可每次使用 `--plugin-dir` 启动。参见[本地开发说明](https://code.claude.com/docs/en/plugin-marketplaces)和[清单规范](https://code.claude.com/docs/en/plugins-reference)。

### Cursor

将**完整解压后的安装目录**复制到 `~/.cursor/plugins/local/godot-plugin`。Windows 下，目标目录尚不存在时可执行：

```powershell
$cursorLocalPlugins = Join-Path $env:USERPROFILE ".cursor\plugins\local"
if (Test-Path -LiteralPath (Join-Path $cursorLocalPlugins "godot-plugin")) { throw "Plugin already exists; review it before updating." }
New-Item -ItemType Directory -Force -Path $cursorLocalPlugins | Out-Null
Copy-Item -LiteralPath "C:\Tools\godot-plugin" -Destination $cursorLocalPlugins -Recurse
```

重启 Cursor 或执行 **Developer: Reload Window**。打开 **Customize**，确认 Godot Skills 出现，在游戏项目的 Agent 模式中要求使用 `godot-workflow`。插件提供 `.cursor-plugin/plugin.json`，采用默认 `skills/` 发现机制；根目录 `plugin.json` 也符合 Cursor 支持的 Agent Plugins 标准。

组织策略需允许本地插件导入。已安装的同名市场插件优先于本地副本；指向本地插件目录外部的符号链接会被 Cursor 跳过，因此应复制真实目录。参见[本地安装说明](https://cursor.com/docs/plugins)和[插件规范](https://cursor.com/docs/reference/plugins)。

### Gemini CLI

将整个目录安装为扩展：

```powershell
gemini extensions install "C:\Tools\godot-plugin"
gemini extensions list
```

在游戏项目中重启 Gemini CLI，执行 `/skills list` 确认 Godot Skills 出现，再要求使用 `godot-workflow` 或领域 Skill。根目录 `gemini-extension.json` 标识扩展，Gemini 自动发现 `skills/`，无需 MCP Server。源码开发可改用 `gemini extensions link "C:\Tools\godot-plugin"` 链接目录。参见[官方扩展规范](https://geminicli.com/docs/extensions/reference/)。

Skill 激活会授予该 Skill 目录的访问权限。本插件还使用同级 `shared/`、`docs/` 资源，因此在游戏项目中启动 Gemini 时，应将**实际加载的扩展根目录**加入访问范围：

```powershell
gemini --include-directories "$env:USERPROFILE\.gemini\extensions\godot-plugin"
```

上面是默认安装位置；若 `gemini extensions list` 显示其它位置，使用其实际路径。链接安装则使用链接指向的源码目录。已有会话也可在允许时使用 `/directory add <扩展根目录绝对路径>`。参见[工作目录命令](https://geminicli.com/docs/reference/commands/)。

### 更新与首次使用

保留本地注册或链接指向的源码/解压目录。Codex 按客户端支持的 `marketplace upgrade` / `plugin add` 流程刷新；Claude Code、Cursor 本地副本在核查现有目录后整体替换；Gemini 已安装扩展使用 `gemini extensions update godot-plugin`。更新后重启宿主，不混用不同版本的文件，不手改宿主生成的缓存。

首次使用要求 Agent 报告插件位置、发现 Godot、执行 `--version`，并在修改游戏前阅读执行约定。需要访问完整插件目录并获准执行 Godot；渲染验证另需显示/GPU 环境。便携引擎若位于无法发现或读取的位置，应报告查找结果。

## 使用

- “创建一个有菜单、收集、音效和存档的 Godot 2D 游戏，导出 Windows 版本并验证。”
- “接手这个项目，找出角色穿墙的原因，修复后验证碰撞。”
- “用原生能力搭建 3D 关卡，烘焙导航并测试敌人路径。”
- “检查当前版本能否从脚本完成这个编辑器操作，给出官方依据。”

单领域任务直接进入领域 Skill，完整游戏或跨系统改动使用 `godot-workflow`。Agent 自动发现引擎、核查版本、编辑项目并运行原生验证。引擎能够被发现时，无需预先设置 PATH 或手动打开 Godot 编辑器。

## Skills

| Skill | 适用任务 |
|---|---|
| [godot-workflow](skills/godot-workflow/SKILL.md) | 完整游戏、跨领域迭代与阶段验收 |
| [godot-project](skills/godot-project/SKILL.md) | 创建、接手、迁移、输入与 Autoload |
| [godot-api](skills/godot-api/SKILL.md) | 版本、CLI、公开 API 和源码核对 |
| [godot-gdscript](skills/godot-gdscript/SKILL.md) | 类型、信号、异步与代码组织 |
| [godot-scenes](skills/godot-scenes/SKILL.md) | 场景、所有权、实例、继承和持久化 |
| [godot-assets](skills/godot-assets/SKILL.md) | 原生导入、重导入和程序化资源 |
| [godot-2d](skills/godot-2d/SKILL.md) | 图块、地图、相机与 2D 内容 |
| [godot-3d](skills/godot-3d/SKILL.md) | 网格、模型、相机与 3D 内容 |
| [godot-physics](skills/godot-physics/SKILL.md) | 运动、碰撞、触发与射线 |
| [godot-navigation](skills/godot-navigation/SKILL.md) | 导航烘焙、路径与代理 |
| [godot-ui](skills/godot-ui/SKILL.md) | 菜单、布局、焦点、主题和本地化 |
| [godot-animation](skills/godot-animation/SKILL.md) | 动画库、属性动画和状态机 |
| [godot-rendering](skills/godot-rendering/SKILL.md) | Shader、材质、灯光与画面验证 |
| [godot-audio](skills/godot-audio/SKILL.md) | 播放、总线、效果与 PCM 音效 |
| [godot-data](skills/godot-data/SKILL.md) | 设置、存档、迁移与异常数据 |
| [godot-multiplayer](skills/godot-multiplayer/SKILL.md) | 原生联机、RPC、生成与复制 |
| [godot-validation](skills/godot-validation/SKILL.md) | 解析、行为、输入、截图与性能诊断 |
| [godot-export](skills/godot-export/SKILL.md) | 官方模板、预设、构建与产物验证 |
| [godot-gdextension](skills/godot-gdextension/SKILL.md) | 原生扩展构建、ABI 与加载诊断 |
| [godot-csharp](skills/godot-csharp/SKILL.md) | Godot.NET 构建、绑定和托管调试 |
| [godot-editor-tools](skills/godot-editor-tools/SKILL.md) | 工具脚本、EditorPlugin 事务与生命周期 |
| [godot-performance](skills/godot-performance/SKILL.md) | CPU/GPU/内存测量、定位与优化对照 |
| [godot-architecture](skills/godot-architecture/SKILL.md) | 模块契约、组件组合、生命周期与信号 |

Skills 按需加载，没有隐藏执行状态或强制加载全部 Skills 的要求。

## 示例和工具

每个 Skill 的 `assets/examples/minimal/` 都可独立复制到干净目录运行。完整游戏在 `skills/godot-workflow/assets/examples/game-2d/` 和 `game-3d/`，使用原生节点、几何和声音。命令中的 GODOT、PLUGIN、PROJECT、OUT 是执行时解析的路径，完整调用方式在各 Skill 的 `references/native.md`。

| 脚本 | 功能 |
|---|---|
| `shared/scripts/inspect_environment.gd` | 引擎、平台、公开绑定和指定类接口 |
| `shared/scripts/inspect_project.gd` | 资源加载、场景结构、依赖与错误收集 |
| `shared/scripts/run_checks.gd` | 隔离子进程、墙钟超时、结果与日志判据 |
| `shared/scripts/capture_scene.gd` | 真实渲染截图和 PNG 读回 |
| `shared/scripts/prepare_templates.gd` | 官方模板下载、SHA256、版本和覆盖保护 |

`common.gd` 是内部共享代码，`shared/host/` 避免启动目标 Autoload。工具不建立常驻服务。测试和辅助状态默认进入项目 `.godot-plugin/` 或外部指定目录，发布前确认不进入游戏包。

## 能力边界

原生诊断案例覆盖触发器、导航、指针输入和音频路由的故障、修复、重复成功及排除条件。见[分段原生工作流证据](docs/native-workflows-validation.json)；设备、视觉和宿主安装后发现的验收范围仍单独记录。

现有 UI skill 还提供[原生本地化流程](skills/godot-ui/references/localization.md)和独立冷启动翻译目录案例。目录、格式和语言刷新检查与字体、布局质量分别验收。

[Web 验收](skills/godot-export/references/web.md)使用 Godot TCPServer 实现的临时回环 HTTP 工具和真实导出游戏，不增加 MCP、编辑器桥接、Python 或 Node 运行依赖。

- headless 验证逻辑与资源；Shader、视觉、GPU 功能需要真实渲染进程。声音状态不等于听感验收。
- 4.7.2 的 `LightmapGI.bake()` 没有 GDScript 公开绑定，插件不提供虚构调用。
- 标准包支持原生桌面流程；Android/iOS 有必要 SDK、签名和宿主平台要求。`.blend` 导入需要 Blender。
- 原生内容自动化不能保证任意复杂美术素材、商业游戏质量或所有平台功能自动完成。
- 既有引擎行为证据来自 Windows；原生 Web 案例还已验证真实 Chrome 鼠标/键盘输入和刷新后存档恢复。其他浏览器、线程/PWA 变体、Linux/macOS、移动端、公网联机和安装后宿主隐式触发仍未实测，见分段证据。

## 维护和交付

贡献前阅读[贡献指南](CONTRIBUTING.md)：先提或关联 Issue，外部贡献者 fork 后开发，完成后提交 PR。外部贡献由维护者审核；所有者发起且由 Codex 开发的 PR，由 Codex 自行审核并记录结果。代码和自有示例采用 [MIT](LICENSE)。

安装包包含全部宿主清单、中英文 README、CHANGELOG、Skills、共享文件、示例和能力/验证说明；源码包另含测试与贡献模板。生成产物、研究下载、`dist/`、引擎缓存与本地 `AGENTS.md` 不进入任何发布包。本地归档仅用于可选的离线复制；本插件不通过 GitHub Releases 分发。

阅读[扩展规范](docs/authoring.md)、[研究依据](docs/research.md)、[验证报告](docs/validation.md)和 [Godot 基线官方发布](https://github.com/godotengine/godot/releases/tag/4.7.2-stable)。


中文任务覆盖与验收边界见[23 Skill覆盖总览](docs/coverage.zh.md)；本次研究与实施证据见[研究记录](docs/research/README.md)。

C#任务额外需要匹配的Godot.NET与.NET SDK；GDExtension任务额外需要绑定、C++编译器、构建工具及绑定生成器。默认原生路径保留。

优先任务流程和本次范围内的执行证据见[优先 Skill 验证](docs/priority-skills-validation.md)。包含游戏示例存档保护和十个新增隔离案例，保留现有 23 个 Skill 名称。
