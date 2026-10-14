# Godot 插件文档

[English](README.md) | **简体中文**

本插件提供 24 个 Godot 开发 Skills、可运行示例和共享原生辅助工具。按任务选择阅读入口；详细执行合同放在负责该任务的 Skill 内。

## 按目标阅读

| 目标 | 阅读入口 |
|---|---|
| 安装并完成第一次任务 | [快速开始](getting-started.zh.md)，然后按[宿主安装指南](../README.zh.md#安装)操作 |
| 选择合适的 Skill | [Skill 目录](skill-catalog.zh.md) |
| 理解插件组成与执行流程 | [架构](architecture.zh.md) |
| 查找辅助脚本和共享合同 | [共享工具](shared-tools.zh.md) |
| 修改或新增 Skill | [开发指南](development.zh.md) |
| 选择检查并理解结果 | [测试策略](testing.zh.md) |
| 确认实际验证范围 | [证据索引](evidence.zh.md) |

## 文档结构

上述主题页采用英文 `*.md` 与简体中文 `*.zh.md` 配对，并提供双向语言切换。修改主题时同步两版。平铺结构对应插件的实际组成：Skills、共享执行、宿主清单和验证证据。

[编写合同](authoring.zh.md)、[兼容历史](compatibility.zh.md)、[覆盖总览](coverage.zh.md)、[研究基线](research.zh.md)、[验证报告](validation.zh.md)、[重点任务报告](priority-skills-validation.zh.md)和[社区实践](community-practices.zh.md)也采用中英配对。`research/` 中的历史记录保留原路径及语言。[证据索引](evidence.zh.md)说明各记录的日期与职责。JSON 继续作为机器可读记录，翻译不得修改测试 ID、来源哈希或已记录结果。

双语主题组织参考了 [DeepSeek Harness docs](https://github.com/deepseek-ai/deepseek-harness/tree/master/docs)；这里的内容和结构按本插件的实际职责编写。

[社区玩法实践与本次证据](community-practices.zh.md) · [本次原生结果](community-validation.json).
