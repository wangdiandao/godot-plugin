# Skill 目录

[English](skill-catalog.md) | **简体中文** · [文档首页](README.zh.md)

按预期结果选择入口。跨系统游戏工作交给 `godot-workflow`，单领域改动交给对应 Skill。遵守每个入口的前置条件与相邻任务排除边界。

| 领域 | Skill | 负责范围 |
|---|---|---|
| 协调 | [godot-workflow](../skills/godot-workflow/SKILL.md) | 完整游戏、跨系统分段工作与交付 |
| 基础 | [godot-project](../skills/godot-project/SKILL.md) | 项目创建、接手、迁移、输入与 Autoload |
| 基础 | [godot-api](../skills/godot-api/SKILL.md) | 版本、CLI 与公开绑定核验 |
| 基础 | [godot-gdscript](../skills/godot-gdscript/SKILL.md) | 类型、信号、异步生命周期与脚本组织 |
| 基础 | [godot-scenes](../skills/godot-scenes/SKILL.md) | 场景归属、实例、继承与持久化 |
| 基础 | [godot-assets](../skills/godot-assets/SKILL.md) | 导入、重导入与程序化资源 |
| 内容 | [godot-2d](../skills/godot-2d/SKILL.md) | 瓦片、地图、相机与 2D 内容 |
| 内容 | [godot-3d](../skills/godot-3d/SKILL.md) | 网格、模型、相机与 3D 内容 |
| 交互 | [godot-physics](../skills/godot-physics/SKILL.md) | 移动、碰撞、触发器与射线 |
| 交互 | [godot-navigation](../skills/godot-navigation/SKILL.md) | 烘焙、连通性、路径与移动代理 |
| 交互 | [godot-ui](../skills/godot-ui/SKILL.md) | 布局、焦点、主题、指针输入与本地化 |
| 表现 | [godot-animation](../skills/godot-animation/SKILL.md) | 动画库、轨道、混合与状态切换 |
| 表现 | [godot-rendering](../skills/godot-rendering/SKILL.md) | 材质、着色器、光照与视觉检查 |
| 表现 | [godot-audio](../skills/godot-audio/SKILL.md) | 播放、总线、效果与 PCM 生成 |
| 状态/联网 | [godot-data](../skills/godot-data/SKILL.md) | 存档、迁移、受保护写入与恢复 |
| 状态/联网 | [godot-multiplayer](../skills/godot-multiplayer/SKILL.md) | RPC、权限、生成与复制 |
| 交付 | [godot-validation](../skills/godot-validation/SKILL.md) | 解析、行为、输入、截图与故障诊断 |
| 交付 | [godot-export](../skills/godot-export/SKILL.md) | 模板、预设、构建与导出游戏验收 |
| 工程 | [godot-architecture](../skills/godot-architecture/SKILL.md) | 模块合同、依赖注入与生命周期 |
| 工程 | [godot-performance](../skills/godot-performance/SKILL.md) | 实测 CPU/GPU/内存诊断与比较 |
| 工程 | [godot-editor-tools](../skills/godot-editor-tools/SKILL.md) | 工具脚本、编辑器事务与插件生命周期 |
| 条件式 | [godot-csharp](../skills/godot-csharp/SKILL.md) | Godot.NET 构建、绑定与托管调试 |
| 条件式 | [godot-gdextension](../skills/godot-gdextension/SKILL.md) | 原生构建、ABI、注册与加载诊断 |

## 从入口到可运行示例

每个入口链接到 `references/native.md` 合同及 `assets/examples/minimal/` 项目，领域专用参考进一步扩展操作合同。[重点任务报告](priority-skills-validation.md)将深入流程映射到命名案例。完整 2D/3D 游戏位于 `godot-workflow/assets/examples/`。

[能力索引](capabilities.json)记录来源、条件、测试 ID 和已测/未测范围。[中文覆盖总览](coverage.zh.md)提供创建、修改及诊断请求示例。通过[证据索引](evidence.zh.md)区分可运行示例与实际验证过的平台或宿主流程。
