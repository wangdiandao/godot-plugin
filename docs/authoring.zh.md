# 编写与扩展规范

[English](authoring.md) | **简体中文**

[文档首页](README.zh.md) · [开发指南](development.zh.md) · [测试策略](testing.zh.md)

## 分层职责

`SKILL.md` 是任务入口，保留完成工作必需的决策和验收条件；`references/` 承载实际 API、平台差异和长示例。`assets/examples/` 是能独立复制运行的完整项目。专用 `scripts/` 只在存在重复而领域特有的操作时增加，不创建空目录。

共享执行、保存、恢复、证据约定位于 `shared/references/`。只在首次执行、持久化、故障或证据更新时按需加载相关文件。默认共享执行工具使用 Godot 原生能力；C# 与 GDExtension 仅为对应任务启用其必要工具链；能直接用 `--import` / `--export-release` 完成的操作不再创建包装服务。

## 每个 Skill 的十项合同

| 要求 | 位置与检查 |
|---|---|
| 名称、触发描述 | frontmatter；与目录名一致，说明相邻领域边界 |
| 使用场景与边界 | 入口目标，不能用宽泛描述抢占所有 Godot 请求 |
| 前置条件 | 引擎、模式、资源和平台条件；说明自动检查路径 |
| 执行流程 | 有序步骤与关键分支；单领域可独立完成 |
| CLI/API | native.md 与可运行示例；核实版本、签名及上下文 |
| 文件保存 | 最小差异、引用、owner、UID、缓存与读回 |
| 错误恢复 | 明确失败原因；相同故障最多两次有依据的修复 |
| 验证方式 | 可观察断言、日志、退出码、产物；包含失败判据 |
| 官方来源 | 结论附近固定版本链接；争议 API 检查源码绑定 |
| 示例和陷阱 | 干净目录可运行；完整命令、输出、副作用与清理范围 |

入口按目标 → 前置检查 → 流程 → 保存/恢复 → 验收 → 按需资料组织。UI 的 display_name、short_description、default_prompt 与真实触发边界一致，默认 allow_implicit_invocation=true。默认提示必须包含该 `$skill-name`。

## 新增能力步骤

1. 先为用户意图选择现有 Skill；只有职责独立且触发边界清晰时才新增 Skill。
2. 在研究会话可用时按 Godot Engine resolve Context7，并按概念分别查询；仍核查匹配版本官方资料。不要把研究用 MCP 写成运行依赖。
3. 通过 ClassDB 与最小调用核验接口；对编辑器限定功能检查实际运行模式，不能把内部 C++ 方法写成脚本 API。
4. 添加最小完整项目。每个案例接收明确输出目录、显式退出并输出结果；测试输出不写入源项目业务文件。
5. 更新 `tests/cases.json`，关联 Skill、输入、条件和预期；新增负例必须说明预期故障文本。正常例复用随包示例，故障只放独立夹具。
6. 更新 `tests/routing/prompts.json` 的应触发、非目标、相邻请求。人工评审和真实宿主模型选择分开记录。
7. 运行必要的原生检查，只有结果通过才更新 capabilities 的 tested 范围。新增平台需实际运行，不能从跨平台 API 推断通过。
8. 同步根 manifest、Codex/Claude Code/Cursor 兼容 manifest、Gemini 扩展清单与市场条目，提升版本；同步英文 README.md 与简体中文 README.zh.md。生成包、读回 ZIP、检查共享引用、搬移后运行，再交付。

## 测试命令

以下命令均在源码根目录运行；先将 GODOT/PLUGIN/OUT/TEMPLATES 替换为绝对路径，OUT 为新的可写目录，`--log-file` 的父目录提前创建。

```text
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/shared/scripts/run_checks.gd --log-file OUT/suite.log -- --manifest PLUGIN/tests/cases.json --out OUT/cases
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/integration/desktop.gd --log-file OUT/desktop.log -- --plugin PLUGIN --templates TEMPLATES --out OUT/desktop
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/integration/assets.gd --log-file OUT/assets.log -- --plugin PLUGIN --out OUT/assets
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/integration/failures.gd --log-file OUT/failures.log -- --plugin PLUGIN --out OUT/failures
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/package.gd --log-file OUT/package.log -- --root PLUGIN --out PLUGIN/dist
```

desktop 集成测试需要 Windows、真实 GPU 和匹配的 Windows/Web 模板；它不是跨平台自动测试。多人重复测试可将 run_checks 的 manifest 指向 `tests/integration/multiplayer-repeat.json`，执行六轮相同断言。原生套件中的 rendering/capture/game 案例会启动短暂窗口并自动退出，multiplayer 仅使用本机回环。

作者结构检查 `python -X utf8 tests/validate_structure.py --root PLUGIN --schema artifacts/research/plugin.schema.json` 使用 Python、PyYAML 和 jsonschema，PLUGIN 替换为绝对路径；仅用于维护，不进入安装包或成为游戏开发运行条件。也可用 skill-creator 的 quick_validate.py 复核单个 Skill；Windows 下使用 Python UTF-8 模式读取中文。结构检查不能替代行为测试。

新增宿主包装时，结构检查核对全部清单的 name/version/description、双语切换链接和实际 Skill 清单的全部链接。Claude Code 可用 `claude plugin validate --strict PLUGIN/.claude-plugin/plugin.json` 校验宿主清单。打包器核对全部清单与 README 的存在、禁入目录及逐文件哈希；随后将两份 ZIP 解压到新的隔离目录，运行源码结构检查与随包原生示例。宿主发现/模型触发与 GDScript 运行证据分开记录，不能仅凭清单校验宣称完整 Agent 流程通过。详见 [compatibility.md](compatibility.zh.md)。

## 保存、清理与证据更新

修改已有文件先记录内容和哈希，恢复只覆盖仍属于本次操作的版本。用户并发修改要保留双方；不通过清空 `.godot` 全目录回避问题。失败产物保留作诊断，重复执行使用新输出目录。

清理只针对自己创建的隔离目录，先规范化并确认绝对路径位于预定父目录。不要删除用户资源、正式存档或未知 PID。正式发行不包含临时引擎、模板、原始研究源码和测试缓存。

维护 `docs/capabilities.json` 的来源、条件、例子、测试 ID、具体已测范围和未测范围；摘要结果放 `docs/validation-results.json`，原始日志留 `artifacts/`。报告中的负例通过表示“正确识别预期失败”，并不代表被测失败操作成功。
