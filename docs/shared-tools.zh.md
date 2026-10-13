# 共享工具与合同

[English](shared-tools.md) | **简体中文** · [文档首页](README.zh.md)

## 原生辅助工具

| 源文件 | 用途与边界 |
|---|---|
| [inspect_environment.gd](../shared/scripts/inspect_environment.gd) | 报告引擎、环境与公开绑定；`--class` 可额外选择要检查的类 |
| [inspect_project.gd](../shared/scripts/inspect_project.gd) | 加载项目资源并记录依赖、场景结构及错误；引擎执行可能运行项目代码 |
| [run_checks.gd](../shared/scripts/run_checks.gd) | 隔离执行清单案例，检查墙钟期限、日志与报告；`--case` 选择案例 ID |
| [capture_scene.gd](../shared/scripts/capture_scene.gd) | 加载场景、渲染并读回 PNG；需要真实显示/渲染进程 |
| [prepare_templates.gd](../shared/scripts/prepare_templates.gd) | 获取选定的官方导出模板，核对版本、哈希并保护已有文件 |
| [common.gd](../shared/scripts/common.gd) | 辅助工具与示例使用的内部参数、进程、结果及文件工具 |
| [shared/host/project.godot](../shared/host/project.godot) | 中性项目，用于无需启动目标项目 Autoload 的辅助任务 |

这些工具不创建持久桥接或服务，默认路径仍为 Godot 原生执行。详细命令放在[执行约定](../shared/references/execution.md)及相关 Skill 原生参考中，参数以辅助工具源码为准。

## 共享合同

| 合同 | 何时阅读 |
|---|---|
| [执行](../shared/references/execution.md) | 首次执行、发现引擎或切换执行模式 |
| [持久化](../shared/references/persistence.md) | 修改资源/场景、保存与独立读回 |
| [恢复](../shared/references/recovery.md) | 故障、重试、回滚与本次操作的清理 |
| [证据](../shared/references/evidence.md) | 验证、结果判读和能力更新 |

明确解析引擎、插件、项目与输出路径，执行前创建日志和输出父目录。生成产物不混入业务资源或导出。保留已有文件和存档，只清理确认属于本次任务的路径。退出码为零或子进程成功标记都不足以证明通过，还需外层日志、断言和预期产物，见[测试策略](testing.zh.md)。
