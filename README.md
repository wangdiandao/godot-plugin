# godot-plugin

面向 Codex 的 Godot 原生开发插件：18 个可独立触发的 Skills、原生 GDScript 辅助脚本和可运行示例，覆盖 GDScript 2D/3D 游戏的创建、内容制作、诊断、测试与导出。

运行需要 **Codex、Godot 标准编辑器发行版和操作系统自带能力**。不安装 MCP Server、Godot 编辑器插件、Python 或 Node。Context7 仅用于作者研究，不是用户运行依赖。

基线为 **Godot 4.7.2 stable**，2026-10-11 核对官方发行版、4.7 文档、同 tag 源码和真实二进制。实际通过范围见[验证报告](docs/validation.md)，逐项证据见[能力索引](docs/capabilities.json)。旧版、其他平台和未覆盖的高级功能不因有 Skill 就自动视为已验证。

## 安装与使用

解压安装包，保留 `godot-plugin/` 整个目录，包括隐藏清单和 `shared/`。在支持本地插件的 Codex CLI 中执行：

```powershell
codex plugin marketplace add "C:\实际解压路径\godot-plugin"
codex plugin add godot-plugin@godot-native-local
codex plugin list --marketplace godot-native-local --json
```

也可以把路径指向当前源码目录。注册的是目录内 `.agents/plugins/marketplace.json` 所描述的本地市场，条目的 `source.path` 相对于市场根目录。更新版本后按当前客户端支持的 marketplace upgrade / plugin add 流程刷新缓存，不手改 Codex 插件缓存。安装操作由用户或获得安装授权的 Codex 完成；本次交付不改动现有全局插件安装。

插件生效后直接用自然语言发起任务，例如：

- “创建一个有菜单、收集、音效和存档的 Godot 2D 游戏，导出 Windows 版本并验证。”
- “接手这个项目，找出角色穿墙的原因，修复后验证碰撞。”
- “用原生能力搭建 3D 关卡，烘焙导航并测试敌人路径。”
- “检查当前版本能否从脚本完成这个编辑器操作，给出官方依据。”

也可显式使用 `$godot-workflow` 或对应领域 Skill。Codex 自动发现已安装的引擎、核查版本、编辑项目并运行验证；无需事先设置 PATH 或手动打开 Godot 编辑器。便携引擎若放在无法发现/读取的位置，任务会报告具体查找结果，不会伪装找到引擎。

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

单领域任务直接进入领域 Skill。完整游戏使用 workflow 协调；接口有疑问读取 api，复杂故障读取 validation。没有隐藏执行状态或强制加载全部 Skills 的要求。

## 示例和工具

每个 Skill 的 `assets/examples/minimal/` 都可独立复制到干净目录运行。完整游戏在 `skills/godot-workflow/assets/examples/game-2d/` 和 `game-3d/`，使用原生节点、几何和声音。命令中的 GODOT、PLUGIN、PROJECT、OUT 是执行时解析的路径，完整调用方式在各 Skill 的 `references/native.md`。

| 脚本 | 功能 |
|---|---|
| `shared/scripts/inspect_environment.gd` | 引擎、平台、公开绑定和指定类的接口 |
| `shared/scripts/inspect_project.gd` | 资源加载、场景结构、依赖与错误收集 |
| `shared/scripts/run_checks.gd` | 隔离子进程、墙钟超时、结果与日志判据 |
| `shared/scripts/capture_scene.gd` | 真实渲染截图和 PNG 读回 |
| `shared/scripts/prepare_templates.gd` | 官方模板下载、SHA256、版本和覆盖保护 |

`common.gd` 是上述脚本的内部共享代码，`shared/host/` 是避免启动目标 Autoload 的中性工具项目。工具不建立常驻服务。测试和辅助状态默认进入项目 `.godot-plugin/` 或外部指定目录，发布前验证不进入游戏包。

## 能力边界

- headless 验证逻辑与资源；Shader、视觉、GPU 功能需要真实渲染进程。声音状态不等于听感验收。
- 4.7.2 的 `LightmapGI.bake()` 没有 GDScript 公开绑定，插件不提供虚构调用。
- 标准包支持原生桌面流程；Android/iOS 仍有必要 SDK、签名和宿主平台要求。`.blend` 导入需要 Blender，不在默认依赖内。
- 自动化可创建和组合原生内容，不能保证任意复杂美术素材、商业游戏质量或所有平台功能自动完成。
- 本版实测 Windows；Web 只验证构建。Linux/macOS、移动端、公网联机与安装后的模型语义触发尚未实测。

## 维护和交付

贡献前阅读 [贡献指南](CONTRIBUTING.md) 与 [Repository Guidelines](AGENTS.md)：先提 Issue，外部贡献者 fork 后开发，完成后提交 PR，由维护者人工审核再合并。代码和自有示例采用 [MIT](LICENSE)。

安装包包含清单、Skills、共享文件、示例和能力/验证说明。源码包另含测试与扩展文档。原始日志、截图、隔离项目和研究下载保留在工作区 `artifacts/`；`artifacts/`、`dist/` 和引擎缓存不递归进入任何发布包。

阅读[扩展规范](docs/authoring.md)、[研究依据](docs/research.md)和[验证报告](docs/validation.md)。插件格式依据 [OpenAI 官方包装说明](https://developers.openai.com/plugins/build/plugins)；引擎依据 [Godot 4.7.2 官方发布](https://github.com/godotengine/godot/releases/tag/4.7.2-stable)。
