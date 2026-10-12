# 贡献指南

## 工作流与职责

所有修改先在 [上游仓库](https://github.com/wangdiandao/godot-plugin/issues) 建立或关联一个 Issue，再开始编辑，包括文档、修复、新 skill 和版本发布。先查重；一个 Issue 对应一个清晰目标，不顺带改动无关领域。首次导入 `main` 与 `v0.1.0` 是唯一初始化例外。

1. 使用 Issue 模板说明问题、范围和可观察的验收条件；新 skill 先解释为何现有 skill 无法承担职责。
2. 外部贡献者 fork 上游仓库，配置 upstream；维护者可直接在仓库分支开发。
3. 从最新 upstream `main` 建立 `type/<issue-number>-<summary>`，例如 `docs/1-contribution-workflow`；不要直接向 `main` 推送。
4. 完成实现、示例和相关验证，再提交 PR。未完成的工作使用 Draft PR。
5. PR 用 `Closes #编号` 关联 Issue，附执行证据、未测范围及兼容性影响。
6. 修复审核意见，更新证据。外部贡献由维护者审核。仓库所有者发起且由 Codex 承担开发的 PR，由 Codex 自行审核最终改动、处理发现并记录结果，无需等待额外人工审核。GitHub 不允许作者批准自己的 PR 时，以 review comment 记录自检，不宣称获得独立批准。合并须符合所有者授权和仓库保护规则。

提交主题采用 `type: imperative summary (#issue)`，例如 `fix: detect import errors (#12)`。type 可为 `feat`、`fix`、`docs`、`test`、`chore`。这是新确立的规范，不是历史推断。

## Issue 标准

标题概括动作或故障；正文包括：问题与用户目标、类型、涉及路径/skill、范围与非目标、当前和预期行为、复现步骤、Godot/Codex 版本及平台、验收清单、验证计划。故障附最小项目和日志；新能力附官方资料与运行条件。未知条件明确标为未知。不要提交凭据、个人路径或用户项目中的私密资源。

## Skill 创建与修改

先阅读 [扩展规范](docs/authoring.md)，优先扩展既有 skill。新增 skill 必须有独立职责和清晰的正向、非目标及相邻触发边界。

```text
skills/godot-<domain>/
  SKILL.md
  agents/openai.yaml
  references/native.md
  assets/examples/minimal/
    project.godot
    example.gd
```

`scripts/` 仅在重复且领域特有的操作需要时添加。通用工具放在 `shared/scripts/`；不要建立空目录或新增默认运行依赖。

`SKILL.md` 必须包含 frontmatter `name` 和触发 `description`，名称与目录一致，并保留校验器要求的章节：

- `Purpose and Scope`
- `Prerequisite Checks`
- `Workflow and Key Decisions`
- `File Changes, Saving, and Recovery`
- `Acceptance and Delivery`
- `On-Demand References and Examples`

入口说明决策、保存、失败恢复与验收；详细 API 和完整命令放 `references/native.md`。`agents/openai.yaml` 的默认提示包含 `$skill-name`，UI 描述符合真实边界。最小示例须能复制到干净目录运行、接受输出目录、输出明确结果并退出。

同步修改 `tests/cases.json`、`tests/routing/prompts.json`、`docs/capabilities.json`。新增 skill 还须修改 `tests/validate_structure.py` 中固定 18 个 skill 的断言及 README 清单。删除或改名须说明兼容性影响并更新全部引用。使用 Context7 研究接口，随后核对版本匹配的官方文档、源码绑定与最小调用；研究工具不能成为插件运行依赖。

## 验证与审核门槛

运行命令见 [authoring.md](docs/authoring.md)。维护结构检查需要 Python 与 PyYAML；schema 校验还需要 jsonschema 及对应 schema。schema 当前位于被忽略的研究目录，不能宣称干净 checkout 已执行此项。

- 所有 PR 必须通过结构检查，并检查 Markdown 链接和清单一致性。
- 行为变更执行受影响案例及负例；共享执行器变更执行核心套件；打包变更验证两份 ZIP 的内容、哈希读回及搬移后运行。
- 截图/渲染使用真实 GPU；桌面导出注明 Windows 与模板版本；headless 或音频状态检查不能替代视觉或听感验收。
- 正常例结合日志、退出码、断言和实际产物；负例通过只代表识别预期失败。不得删除断言、忽略错误或清空用户缓存以获得通过。

PR 写明实际执行的命令、引擎版本、平台、结果及未测部分。原始证据可作为 PR/Release 附件或可访问链接；不要只引用被忽略的本地 `artifacts/`。历史报告与本次验证分开记录，未执行不得写入 tested 范围。

## 许可、发布与剩余治理

代码和自有示例采用 [MIT](LICENSE)。第三方资源注明来源、许可和再分发条件；不纳入未授权素材。

发布前同步根 manifest、Codex/Claude Code/Cursor 兼容 manifest、Gemini 扩展清单、市场条目与必要版本说明。保持 README.md 为英文主版，README.zh.md 为简体中文版，两版相互链接并同步安装方法与边界。生成安装/源码 ZIP，读回 SHA256，执行搬移验证，再由维护者发布版本标签和附件。源码包包含贡献指南与模板，两份 ZIP 都包含 LICENSE、两版 README 与全部宿主清单。已发布的标签与附件保持不变，后续修改通过新版本发布。

`AGENTS.md` 是所有者本地开发规范，由 `.gitignore` 排除，不提交到远端，也不进入任何发布包。公共贡献流程放在本指南，Issue/PR 格式放在 `.github/` 模板，skill 的技术合同和验证命令放在 `docs/authoring.md`，许可条款放在 `LICENSE`。

结构 CI、受保护分支和独立审核人目前尚未配置；文档规则不等于 GitHub 已强制执行。后续应通过独立 Issue 配置最低权限 CI、required checks 与审核保护，并补充可复现的维护依赖/schema；真实 GPU 和桌面测试仍需适配的执行环境。
