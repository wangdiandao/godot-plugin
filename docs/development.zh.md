# 开发指南

[English](development.md) | **简体中文** · [文档首页](README.zh.md)

## 贡献流程

贡献开发使用源码 checkout，安装归档不包含测试和贡献模板。编辑前阅读 [CONTRIBUTING.md](../CONTRIBUTING.md)。先查重并建立或关联上游 Issue，确定可观察的验收条件。外部贡献者 fork；维护者可从最新上游 `main` 建立关联 Issue 的分支。完成后通过 PR 提交，包含 `Closes #编号`、实际验证及未测范围。

外部贡献由维护者审核。所有者发起且由 Codex 实施的工作，由 Codex 审核最终改动、修复发现、执行相关检查，并在所有者授权及仓库保护规则内合并前记录自审。自审评论不等于独立批准。

## Skill 合同

优先扩展已有 Skill，仅在职责与触发边界独立时新增。[编写规范](authoring.md)是权威合同，规定必需章节、原生参考、可运行示例、保存/恢复和验收。

| 组成 | 必须同步的内容 |
|---|---|
| `SKILL.md` | 名称与目录一致，触发描述精确，保留必需流程章节 |
| `agents/openai.yaml` | UI 边界真实，默认提示包含该 Skill 的 `$name` |
| `references/native.md` 与示例 | 匹配版本的公开 API、完整执行方法及独立可运行示例 |
| [tests/cases.json](../tests/cases.json) | 案例、条件、预期结果与能力 ID |
| [tests/routing/prompts.json](../tests/routing/prompts.json) | 正向、非目标及相邻任务提示 |
| [capabilities.json](capabilities.json) | 来源、示例路径、测试 ID 和实际已测/未测范围 |
| 根 README 与 [Skill 目录](skill-catalog.zh.md) | 实际清单与同步的语言导航 |

研究 API 时通过 Context7 解析 Godot Engine，按概念分别查询，再核对匹配的官方文档、源码与实际公开绑定。研究工具不成为运行依赖。

## 文档改动

英文与中文主题页配对，提供双向语言切换和对应语言的文档首页链接。同步语义、路径、数量及限制。增加导航时保留已有公开路径。历史报告保留日期、结果与原语言，通过[证据索引](evidence.zh.md)组织，避免改写历史结果。

文档改动运行[结构与链接检查](testing.zh.md)。行为改动还需受影响的正常/负例；打包改动需归档读回和搬移验证。生成报告、下载与缓存不进入 Git。本地 `AGENTS.md` 保持未跟踪并排除出分发包。

## 版本与交付

发布属于任务范围时，同步全部宿主清单、市场元数据、变更日志及两版根 README，再执行规定的打包检查。仅重组文档不引入新的运行版本。不可把无法执行的 schema 校验、宿主选路、渲染或平台测试写为已完成。具体命令和限制记录在 PR 中。
