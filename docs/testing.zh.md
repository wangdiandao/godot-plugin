# 测试策略

[English](testing.md) | **简体中文** · [文档首页](README.zh.md)

## 按改动选择验证

| 改动 | 所需证据 |
|---|---|
| 文档/元数据 | 结构、本地 Markdown 链接、清单及语言一致性 |
| Skill 行为 | 受影响的正常案例与检查预期原因的负例 |
| 共享执行 | 核心套件、日志、进程生命周期、超时与结果判读 |
| 渲染/UI | 真实 GPU/窗口和合适的输入/产物检查 |
| 音频 | 状态/数据检查；声称听感质量时还需实际聆听 |
| 打包 | 必需/禁入成员、字节及哈希读回、搬移后执行 |
| 宿主发现/选路 | 实际安装宿主的发现与模型调用，和清单检查分开记录 |

headless 逻辑检查、清单有效性、语义选路与用户可见验收分别证明不同事实。执行适合改动的检查，并明确剩余范围。

## 作者结构检查

在仓库根目录运行：

```text
python -X utf8 tests/validate_structure.py --root .
```

维护时需要 Python 与 PyYAML，不是插件运行要求。检查宿主元数据、Skill 合同、能力/案例引用、两版根 README 和 Skills、共享文件及 docs 中的本地 Markdown 链接。

已有本地研究 schema 且安装了 `jsonschema` 时：

```text
python -X utf8 tests/validate_structure.py --root . --schema artifacts/research/plugin.schema.json --report artifacts/docs-structure.json
```

schema 被忽略，不随干净 checkout 提供。第一条命令不执行 schema 校验，不能将其报告为 schema 通过。生成报告不进入 Git。

## 原生检查

完整套件、桌面/资源/故障集成及打包命令统一维护在 [authoring.md](authoring.zh.md)。将 `GODOT`、`PLUGIN`、`OUT` 和模板解析为实际绝对路径，使用新的输出目录并创建日志父目录。示例与工具遵守[执行合同](../shared/references/execution.md)。安装归档不包含源码案例清单，复现源码套件命令需要源码 checkout。

## 结果判读

辅助工具输出 `GODOT_PLUGIN_RESULT:` JSON，包含引擎/平台、状态、检查、错误及产物。将子报告与完整外层日志、退出码、墙钟终止和实际输出一起核对。`passed` 标记不能掩盖启动/退出错误或保存文件缺失。

负例只有识别预期故障原因才算通过。`unsupported`、工具链缺失控制及预期超时，都不证明被阻塞操作成功。历史报告见[证据索引](evidence.zh.md)，新增命令与结果记录在 PR，不能借用历史结果作为本次验证。
