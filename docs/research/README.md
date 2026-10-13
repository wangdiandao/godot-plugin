# Godot 4.7 全文档研究进度

本目录是 Issue #7 的研究与验收记录。2026-10-13 全页面阅读门槛已通过，现进入 Skill 实施；阅读完成不代表运行能力验收完成。

## 固定来源与范围

- 官方文档：`godotengine/godot-docs`，4.7 分支提交 `9adca4c1c72917bfe1b7be3108abed5ce26696a6`。
- 来源清单：[4.7-page-inventory.json](4.7-page-inventory.json)，包含固定提交中的 1,596 个 RST 文档源文件：教程、手册、类参考、引擎细节、社区页面及源索引。
- 本次重新运行标准引擎 `--version` 得到 `4.7.2.stable.official.ed1daf0bf`。文档分支提交与引擎 patch 构建是两种证据；前者不能替代后者的接口和行为验证。
- 官方文档原作者为 Juan Linietsky、Ariel Manzur 和 Godot Engine community，文档采用 CC BY 3.0。这里保留来源链接和原创研究结论，不将官方全文复制到插件或改称 MIT。

Sphinx 生成的搜索和总索引导航不是独立 RST 内容页，需要另外核对构建/网站导航；源文件清单完整不能单独证明网站每个生成 URL 已核对。外部站点、其他语言和其他文档版本不纳入清单；4.7 文档内的旧版本迁移指南仍纳入。

2026-10-13 使用该提交的官方 `requirements.txt`（Sphinx 8.1.3）在隔离环境串行构建 HTML，进程退出码为 0，构建日志报告 `build succeeded`。实际生成 1,598 个 HTML 页面：全部 1,596 个 RST 页面均有对应输出，新增生成页面为 `genindex.html` 与 `search.html`。这只证明构建及枚举一致；两项生成导航仍须单独阅读和映射，不计入 RST 已读数。命令、控制台日志与页面差异检查脚本保存在忽略目录 `artifacts/research/`。

```powershell
& artifacts/research/docs-build-venv/Scripts/python.exe -X utf8 -m sphinx -b html -j 1 -w artifacts/research/docs-build-serial-warnings.log artifacts/research/deepening-docs-4.7 artifacts/research/deepening-docs-html-serial *> artifacts/research/docs-build-serial-console.log
python -X utf8 artifacts/research/check-html-pages.py
```

## 阅读证据

`page-reviews/*.json` 中的每条记录必须包含页面路径、固定源内容 SHA256、实际阅读者、`read` 状态、页面特有结论及 Skill 归属或明确范围边界。只有实际读取完整页面内容后才能提交记录；工具输出截断时须补读缺失部分。不能用下载、关键词命中、自动提取标题或自动摘要作为已读证据。

清单里的 `pending` 是枚举时的状态，不会被自动改成已读。实际进度通过独立阅读记录合并计算，防止再次生成清单时覆盖已读证据。哈希、重复、结论及归属检查只是证据结构校验；主 Agent 仍需审查研究结论的正确性与实用性。

```powershell
python -X utf8 tests/research_inventory.py --snapshot artifacts/research/deepening-docs-4.7 --inventory docs/research/4.7-page-inventory.json
python -X utf8 tests/research_inventory.py --inventory docs/research/4.7-page-inventory.json
python -X utf8 tests/research_inventory.py --inventory docs/research/4.7-page-inventory.json --require-complete
python -X utf8 tests/research_inventory.py --inventory docs/research/4.7-page-inventory.json --source artifacts/research/deepening-docs-4.7 --generated-reviews docs/research/generated-page-reviews.json --html-root artifacts/research/deepening-docs-html-serial --require-complete
python -X utf8 -m unittest discover -s tests -p test_research_inventory.py
```

第一条命令只枚举来源，不产生已读记录。第三条在页面未完成或证据失效时返回非零退出码。官方源码快照和工具缓存位于被忽略的 `artifacts/research/`，不会进入 Git 或安装包。

带 `--source` 的检查重新读取每份 RST 并核对清单哈希；带 `--generated-reviews` 和 `--html-root` 的检查将 `search.html`、`genindex.html` 的实际阅读记录与生成文件哈希一并纳入门槛。Skill 归属须匹配计划中的 23 个名称，未登记名称不能通过。生成页面已读不代表其浏览器交互已测。

## 领域结论

- [模块架构与开源实践](architecture-research.md)
- [渲染、CPU 性能与 HDR](rendering-research.md)
- [C#、GDExtension 与编辑器工具](extensions-research.md)

以上是研究材料；具体运行证据另见各实施报告。最终交付仍需完成 23 个 Skill、操作案例、任务验证及打包搬移验收。

2026-10-13：Context7 对 Godot 4.7 Jiggle 的质量、阻尼、传送重置和碰撞执行模式查询未匹配文档（INVALID_ARGUMENT）。该调用不计为成功检索；相关结论以固定官方 RST 和 4.7.2 源码为据，行为仍待运行验证。


2026-10-13 本轮检查点：RST 阅读 1484/1596，待读 112，账本错误 0；`python -X utf8 -m unittest discover -s tests -p test_research_inventory.py` 实测 8 项通过。`--require-complete` 实测退出 1，符合未完成阅读门槛。生成的 `genindex.html` 仍待完整阅读，不能计入全页完成。渲染分配 335 页完成后新增转交 25 页，已完成 5 页；扩展分配 334/335，RenderingServer 已部分阅读但未登记已读。两名代理因模型容量错误中断，未消费的内容不计已读。该检查点不是 Skill 或运行能力验收。


2026-10-13 最终阅读门槛：1,596/1,596 个 RST 页面、2/2 个生成页面完成，未读 0，哈希、归属、重复错误 0。带源快照和生成 HTML 的完整门槛命令退出 0；研究单元测试 12 项通过（0.192 秒）。main、foundation、render、extension 四份账本合并通过；研究自审列出的 Resource/Script、HDR 缓冲、RPC 归属和 TextEdit 语义已修正。此前检查点保留为历史记录。

本轮 Context7 Theme 研究：Godot Engine resolve 成功，选择官方 4.7 文档分支；独立 Theme、导航跨区域与 AnimationLibrary 持久化概念查询成功。检索的邻接 2D 导航段落不能替代 3D 接口校验；实现仍核对对应 3D 固定源码并运行。

PR 自审补强：完整门槛同时拒绝错误固定版本、空清单及遗漏的本地 RST 文件；新增回归断言后 13 项测试通过（0.143 秒），完整门槛再次退出 0。安装结构自审在原始 18 Skill 的隔离快照加研究批次上通过 777 项；后续新增 Skill 不借用该快照结果。
