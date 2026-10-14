# 插件架构

[English](architecture.md) | **简体中文** · [文档首页](README.zh.md)

## 包内职责

| 路径 | 职责 |
|---|---|
| `plugin.json`、宿主清单和市场条目 | 宿主发现、身份和展示，见[兼容说明](compatibility.zh.md) |
| `skills/<name>/SKILL.md` | 任务触发、前置条件、决策、保存/恢复和验收 |
| `skills/<name>/references/` | 原生 API/CLI 详细合同及领域任务流程 |
| `skills/<name>/assets/examples/` | 由该 Skill 负责、能独立运行的项目 |
| `shared/references/` | 共享执行、保存、恢复与证据合同 |
| `shared/scripts/`、`shared/host/` | 原生辅助工具与中性宿主项目 |
| `tests/` | 案例清单、夹具、集成检查、选路提示及作者结构校验 |
| `docs/` | 阅读导航、编写规范、能力记录及带日期的验证/研究证据 |

宿主加载 Skill，并提供 Agent 的文件和进程工具。插件默认执行路径使用 Godot 原生 CLI/GDScript。Context7 用于作者研究，不是插件运行依赖。条件式语言或工具任务单独声明前置条件。

## 任务流程

1. 按用户意图选择领域 Skill；跨系统工作选择 `godot-workflow`。
2. 发现引擎，记录实际版本，检查项目和环境。
3. 按需加载相关原生流程与共享合同。
4. 执行有边界的改动，保留无关文件，按任务的持久化合同保存。
5. 运行适当检查，检查外层进程日志，独立读回已保存产物。
6. 交付证据，说明阻塞、不支持和未测范围。

职责分配见 [Skill 目录](skill-catalog.zh.md)，可复用操作见[共享工具](shared-tools.zh.md)。单次任务无需加载所有 Skills。

## 执行边界

[中性共享宿主](../shared/host/project.godot)使仅调用辅助工具的任务不启动目标项目的 Autoload。在目标项目运行检查可能执行其初始化与工具脚本。编辑器限定操作和真实渲染需使用对应上下文，不能把所有检查都当作普通 headless 脚本。

安装包包含运行用 Skills、共享资源和文档；源码包还包括测试及贡献材料。生成产物、研究下载与引擎缓存不进入分发。保留完整包，才能维持 Skills、共享文件和文档间的相对引用。

## 权威位置

Skill 入口负责选路和任务验收，原生参考负责详细操作。[编写规范](authoring.zh.md)负责贡献技术合同。[能力索引](capabilities.json)关联 Skill、来源、示例与测试。[证据索引](evidence.zh.md)按日期和范围整理观察结果。主题页通过链接引用这些合同，避免重复长流程，也不把历史运行重新解释为当前验证。
