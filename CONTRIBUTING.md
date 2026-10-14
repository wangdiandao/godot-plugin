# Contributing / 贡献指南

[English](#english) · [简体中文](#简体中文)

## English

### Workflow and responsibilities

Open or associate an Issue in the [upstream repository](https://github.com/wangdiandao/godot-plugin/issues) before editing anything, including documentation, fixes, new skills, and releases. Search for duplicates first. Each Issue should have one clear goal; avoid unrelated changes. The initial import of `main` and `v0.1.0` is the only initialization exception.

1. Use the Issue template to describe the problem, scope, and observable acceptance criteria. For a new skill, first explain why existing skills cannot cover its responsibility.
2. External contributors fork the upstream repository and configure upstream; maintainers may develop directly on repository branches.
3. Create `type/<issue-number>-<summary>` from the latest upstream `main`, for example `docs/1-contribution-workflow`. Do not push directly to `main`.
4. Complete the implementation, examples, and relevant validation before submitting a PR. Use a Draft PR for unfinished work.
5. Link the Issue with `Closes #<number>` in the PR and include execution evidence, untested scope, and compatibility impact.
6. Address review findings and update evidence. Maintainers review external contributions. For owner-initiated PRs implemented by Codex, Codex reviews the final changes, addresses findings, and records the result without waiting for additional human review. If GitHub prevents authors from approving their own PRs, record the self-review in a review comment; do not claim independent approval. Merging must comply with the owner's authorization and repository protection rules.

Use commit subjects in the form `type: imperative summary (#issue)`, for example `fix: detect import errors (#12)`. Supported types are `feat`, `fix`, `docs`, `test`, and `chore`. This is a newly established convention, not an inference from historical commits.

### Issue standards

Summarize the action or failure in the title. Include the problem and user goal, type, affected paths/skills, scope and non-goals, current and expected behavior, reproduction steps, Godot/Codex versions and platform, acceptance checklist, and validation plan in the body. For failures, attach a minimal project and logs; for new capabilities, include official sources and runtime requirements. Explicitly mark unknown conditions as unknown. Do not submit credentials, personal paths, or private resources from user projects.

### Creating and modifying skills

Read the [authoring specification](docs/authoring.md) first and prefer extending existing skills. A new skill must have an independent responsibility and clear boundaries for positive triggers, non-goals, and adjacent requests.

```text
skills/godot-<domain>/
  SKILL.md
  agents/openai.yaml
  references/native.md
  assets/examples/minimal/
    project.godot
    example.gd
```

Add `scripts/` only when repeated, domain-specific operations require it. Put general tools in `shared/scripts/`. Do not create empty directories or introduce default runtime dependencies.

`SKILL.md` must contain frontmatter with `name` and a trigger `description`. The name must match the directory, and the following validator-required sections must remain:

- `Purpose and Scope`
- `Prerequisite Checks`
- `Workflow and Key Decisions`
- `File Changes, Saving, and Recovery`
- `Acceptance and Delivery`
- `On-Demand References and Examples`

The entry document explains decisions, saving, failure recovery, and acceptance. Put detailed APIs and complete commands in `references/native.md`. The default prompt in `agents/openai.yaml` includes `$skill-name`, and UI descriptions reflect the actual boundaries. Minimal examples must run when copied to a clean directory, accept an output directory, emit explicit results, and exit.

Update `tests/cases.json`, `tests/routing/prompts.json`, and `docs/capabilities.json` together. When adding a skill, also check the actual directory inventory, case/capability references, and README inventory checked by `tests/validate_structure.py`; fixed-count assertions are no longer used. Deletions or renames must explain compatibility impact and update all references. Research interfaces with Context7, then verify version-matched official documentation, source bindings, and a minimal call. Research tools must not become plugin runtime dependencies.

### Validation and review requirements

See [authoring.md](docs/authoring.md) for commands. Maintenance structure checks require Python and PyYAML; schema validation also requires jsonschema and the corresponding schema. The schema is currently in an ignored research directory, so do not claim that this check has run in a clean checkout.

- Every PR must pass structure checks and check Markdown links and inventory consistency.
- Behavior changes run affected cases and negative cases; shared executor changes run the core suite; packaging changes verify both ZIPs' contents, hash readback, and execution after relocation.
- Screenshots/rendering use a real GPU. Desktop exports identify the Windows and template versions. Headless or audio-state checks cannot replace visual or listening acceptance.
- Positive cases combine logs, exit codes, assertions, and actual outputs. A passing negative case means only that the expected failure was detected. Do not remove assertions, ignore errors, or clear user caches to obtain a pass.

PRs state the actual commands executed, engine version, platform, results, and untested scope. Raw evidence may be attached to the PR/Release or provided through accessible links; do not refer only to ignored local `artifacts/`. Record historical reports separately from current validation, and never include unexecuted checks in the tested scope.

### Licensing, releases, and remaining governance work

Code and original examples use the [MIT License](LICENSE). Identify third-party resources' sources, licenses, and redistribution conditions; do not include unauthorized material.

Before release, synchronize the root manifest, Codex/Claude Code/Cursor compatibility manifests, Gemini extension manifest, marketplace entry, and necessary version notes. Keep README.md as the primary English version and README.zh.md as the Simplified Chinese version; cross-link both and synchronize installation methods and boundaries. Generate installation/source ZIPs, read back SHA256 hashes, and validate relocation before maintainers publish the version tag and attachments. Source archives include the contribution guide and templates. Both ZIPs include LICENSE, both READMEs, and all host manifests. Published tags and attachments remain unchanged; subsequent changes ship through new releases.

`AGENTS.md` contains the owner's local development rules. It is excluded by `.gitignore`, is not committed to the remote, and is not included in release packages. Public contribution procedures belong in this guide, Issue/PR formats in `.github/` templates, skill technical contracts and validation commands in `docs/authoring.md`, and license terms in `LICENSE`.

Structure CI, protected branches, and independent reviewers are not currently configured. Documented rules do not mean GitHub already enforces them. Separate Issues should configure CI with minimum permissions, required checks, and review protection, and add reproducible maintenance dependencies/schema. Real GPU and desktop tests still require suitable execution environments.

## 简体中文

### 工作流与职责

所有修改先在 [上游仓库](https://github.com/wangdiandao/godot-plugin/issues) 建立或关联一个 Issue，再开始编辑，包括文档、修复、新 skill 和版本发布。先查重；一个 Issue 对应一个清晰目标，不顺带改动无关领域。首次导入 `main` 与 `v0.1.0` 是唯一初始化例外。

1. 使用 Issue 模板说明问题、范围和可观察的验收条件；新 skill 先解释为何现有 skill 无法承担职责。
2. 外部贡献者 fork 上游仓库，配置 upstream；维护者可直接在仓库分支开发。
3. 从最新 upstream `main` 建立 `type/<issue-number>-<summary>`，例如 `docs/1-contribution-workflow`；不要直接向 `main` 推送。
4. 完成实现、示例和相关验证，再提交 PR。未完成的工作使用 Draft PR。
5. PR 用 `Closes #编号` 关联 Issue，附执行证据、未测范围及兼容性影响。
6. 修复审核意见，更新证据。外部贡献由维护者审核。仓库所有者发起且由 Codex 承担开发的 PR，由 Codex 自行审核最终改动、处理发现并记录结果，无需等待额外人工审核。GitHub 不允许作者批准自己的 PR 时，以 review comment 记录自检，不宣称获得独立批准。合并须符合所有者授权和仓库保护规则。

提交主题采用 `type: imperative summary (#issue)`，例如 `fix: detect import errors (#12)`。type 可为 `feat`、`fix`、`docs`、`test`、`chore`。这是新确立的规范，不是历史推断。

### Issue 标准

标题概括动作或故障；正文包括：问题与用户目标、类型、涉及路径/skill、范围与非目标、当前和预期行为、复现步骤、Godot/Codex 版本及平台、验收清单、验证计划。故障附最小项目和日志；新能力附官方资料与运行条件。未知条件明确标为未知。不要提交凭据、个人路径或用户项目中的私密资源。

### Skill 创建与修改

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

同步修改 `tests/cases.json`、`tests/routing/prompts.json`、`docs/capabilities.json`。新增 skill 还须核对 `tests/validate_structure.py` 所检查的实际目录清单、案例/能力引用及 README 清单，不再设置固定数量断言。删除或改名须说明兼容性影响并更新全部引用。使用 Context7 研究接口，随后核对版本匹配的官方文档、源码绑定与最小调用；研究工具不能成为插件运行依赖。

### 验证与审核门槛

运行命令见 [authoring.md](docs/authoring.md)。维护结构检查需要 Python 与 PyYAML；schema 校验还需要 jsonschema 及对应 schema。schema 当前位于被忽略的研究目录，不能宣称干净 checkout 已执行此项。

- 所有 PR 必须通过结构检查，并检查 Markdown 链接和清单一致性。
- 行为变更执行受影响案例及负例；共享执行器变更执行核心套件；打包变更验证两份 ZIP 的内容、哈希读回及搬移后运行。
- 截图/渲染使用真实 GPU；桌面导出注明 Windows 与模板版本；headless 或音频状态检查不能替代视觉或听感验收。
- 正常例结合日志、退出码、断言和实际产物；负例通过只代表识别预期失败。不得删除断言、忽略错误或清空用户缓存以获得通过。

PR 写明实际执行的命令、引擎版本、平台、结果及未测部分。原始证据可作为 PR/Release 附件或可访问链接；不要只引用被忽略的本地 `artifacts/`。历史报告与本次验证分开记录，未执行不得写入 tested 范围。

### 许可、发布与剩余治理

代码和自有示例采用 [MIT](LICENSE)。第三方资源注明来源、许可和再分发条件；不纳入未授权素材。

发布前同步根 manifest、Codex/Claude Code/Cursor 兼容 manifest、Gemini 扩展清单、市场条目与必要版本说明。保持 README.md 为英文主版，README.zh.md 为简体中文版，两版相互链接并同步安装方法与边界。生成安装/源码 ZIP，读回 SHA256，执行搬移验证，再由维护者发布版本标签和附件。源码包包含贡献指南与模板，两份 ZIP 都包含 LICENSE、两版 README 与全部宿主清单。已发布的标签与附件保持不变，后续修改通过新版本发布。

`AGENTS.md` 是所有者本地开发规范，由 `.gitignore` 排除，不提交到远端，也不进入任何发布包。公共贡献流程放在本指南，Issue/PR 格式放在 `.github/` 模板，skill 的技术合同和验证命令放在 `docs/authoring.md`，许可条款放在 `LICENSE`。

结构 CI、受保护分支和独立审核人目前尚未配置；文档规则不等于 GitHub 已强制执行。后续应通过独立 Issue 配置最低权限 CI、required checks 与审核保护，并补充可复现的维护依赖/schema；真实 GPU 和桌面测试仍需适配的执行环境。
