# 验证与研究证据

[English](evidence.md) | **简体中文** · [文档首页](README.zh.md)

## 能力合同

[capabilities.json](capabilities.json)将 23 个 Skills 关联到官方来源、示例、测试 ID、前置条件与已测/未测范围。其记录基线为 Windows 上的 Godot 4.7.2。声称支持某个任务或平台前，先阅读对应记录及关联证据。

## 已记录的验证批次

以下是既有工作的带日期记录，不是文档重组时新执行的测试。

| 批次 | 阅读说明 | 机器可读结果 |
|---|---|---|
| 2026-10-11 初始基线 | [验证报告](validation.md)（中文，当时为 18 个 Skills） | [validation-results.json](validation-results.json) |
| 2026-10-12 宿主包装，后续更新追加于文内 | [兼容历史](compatibility.md)（英文） | 结果/限制记录于报告及关联 PR |
| 2026-10-13 0.2.0 深化为 23 个 Skills | [研究与实施索引](research/README.md)、[覆盖总览](coverage.zh.md)（中文） | [deepening-validation.json](deepening-validation.json) |
| 2026-10-13 0.2.1 原生诊断、本地化与 Web | [验证报告导言](validation.md)、[兼容更新](compatibility.md) | [native-workflows-validation.json](native-workflows-validation.json) |
| 2026-10-13 0.2.2 重点任务与受保护存档 | [重点任务报告](priority-skills-validation.md)（英文） | [priority-skills-validation.json](priority-skills-validation.json) |

0.2.2 报告记录 53 个预期结果：42 个正常通过、六个预期失败、一个预期超时、两个不支持控制和两个工具链缺失控制。11 个控制证明识别/前置检查，不代表对应操作执行成功。该批次是本索引中最新的版本化报告，结果不扩展为每个已安装宿主或平台均已验证。

## 研究链路

- [基线与技术选择](research.md)记录来源固定和初始原生边界。
- [研究索引](research/README.md)关联领域研究、实施、自审与任务评估。
- [页面清单](research/4.7-page-inventory.json)、[生成页面阅读记录](research/generated-page-reviews.json)和[基线快照](research/baseline-20261013.json)属于研究记录，不是运行测试结果。

原始本地日志和下载位于被忽略的 `artifacts/`，不随插件分发。复现阅读清单/哈希检查需要原始源码及 HTML 快照。对应 PR 的报告链接或附件提供可审阅证据，仅有被忽略的本地路径不代表其他读者能访问其中内容。

## 仍需遵守的边界

已记录的原生行为限于 Windows。真实渲染和实际听感分别区别于 headless/状态检查。清单及包装验证不能证明安装宿主后的隐式 Skill 选择。浏览器、公网、移动端与其他平台变体需各自证据。具体条件、例外及命令见各批次报告；选择新的验证流程见[测试策略](testing.zh.md)。
