# 快速开始

[English](getting-started.md) | **简体中文** · [文档首页](README.zh.md)

## 安装完整插件

按[宿主安装说明](../README.zh.md#安装)选择 Codex Desktop/CLI、Claude Code、Cursor 或 Gemini CLI。保留完整插件根目录、隐藏清单、`skills/`、`shared/` 和 `docs/`，安装后新建宿主会话。

普通 GDScript 任务使用 Godot 标准编辑器发行版和系统工具。C# 任务另需 Godot.NET 与 .NET SDK；GDExtension 任务需要匹配的绑定与原生构建工具链。已记录的引擎基线为 Windows 上的 Godot 4.7.2，实际范围见[证据索引](evidence.zh.md)。

## 第一次任务

在所选 Agent 中打开游戏项目，输入：

> 使用 godot-workflow 检查当前项目。在修改前报告插件位置、Godot 二进制及版本、项目状态与缺失的前置条件。

显式调用时，Codex 使用 `$godot-workflow`，Claude Code 使用 `/godot-plugin:godot-workflow`。其他宿主按安装指南使用各自的 Skill 发现与调用机制。支持时可直接描述任务；仅通过包装检查不能证明安装后的隐式选路已验证。

确认 Agent 能读取整个插件根目录并执行找到的引擎。Gemini 会话还需按安装指南把已加载的扩展根目录加入允许目录。引擎位于无法发现或读取的位置时，应明确报告缺失。

## 提出有边界的请求

| 请求 | 入口 |
|---|---|
| 制作可玩的 2D 小游戏，保存进度并验证导出 | [godot-workflow](../skills/godot-workflow/SKILL.md) |
| 排查角色穿过地面 | [godot-physics](../skills/godot-physics/SKILL.md) |
| 修复菜单遮罩拦截按钮输入 | [godot-ui](../skills/godot-ui/SKILL.md) |
| 核对已安装版本是否提供某个公开 API | [godot-api](../skills/godot-api/SKILL.md) |

其他任务见 [Skill 目录](skill-catalog.zh.md)。每个 Skill 提供 `references/native.md` 合同和独立的 `assets/examples/minimal/` 项目；完整游戏示例属于 `godot-workflow`。

## 交付应包含什么

要求提供改动文件、实际命令、日志、断言、产物以及未满足的条件。持久化资源需要独立读回。headless 通过不能证明画面、听感或目标平台行为。结果判读见[测试策略](testing.zh.md)，执行和恢复合同见[共享工具](shared-tools.zh.md)。
