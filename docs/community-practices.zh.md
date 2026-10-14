# 社区玩法实践（Issue #25）

[English](community-practices.md) | **简体中文**

[文档首页](README.zh.md) · [本次验证](community-validation.json)

## 本次范围

2026-10-14：保留既有 23 个 skill 名称，新增 godot-ai。社区文章和帖子提供具体用例与取舍；能力范围以源码、固定版本的官方文档和运行验收为准。新增示例代码和着色器均为原创，不再分发第三方美术资源或教程代码。Context7 仍是研究工具，不是安装后的运行依赖。

| 吸收的用例 | 负责领域与可运行合同 |
|---|---|
| 嵌套等待的终止、已取消的 Tween、所有事件的归属 | [godot-gdscript 终端等待](../skills/godot-gdscript/references/terminal-waits.md)；动画领域链接到此合同 |
| 瓦片规则、负坐标/变换后的单元格、动态阻挡 | [导航网格桥接](../skills/godot-navigation/references/grid.md)；2d 负责创作的关卡内容 |
| 共享定义、隔离数量、JSON ID 和受保护的进度 | [数据背包](../skills/godot-data/references/inventory.md)；workflow 负责整体验收 |
| 分支图、逐字显示/跳过、键盘选择及重复关闭 | [UI 对话](../skills/godot-ui/references/dialogue.md)；data 负责任务事实的持久化 |
| 分阶段着色器像素验证和嵌入式弹窗后处理 | [渲染传送门/弹窗](../skills/godot-rendering/references/portal-popup.md)；UI 负责真实输入 |
| 合法的敌人决策、稳定的局部平局处理、有界候选规划 | [新增 godot-ai](../skills/godot-ai/SKILL.md)；navigation 负责路径，physics 负责传感与运动 |

各原生参考文档在对应建议附近注明社区来源，并保留日期和版本限定。性能领域补充游戏专属监控的归属、大规模群体的取舍及鼠标轮询诊断。架构领域补充状态机/模块选择；编辑器工具补充撤销引用的生命周期；多人领域记录可选的同一场景树内诊断。这些补充配方没有被赋予虚构的运行证据。

## 研究核对

Context7 解析 Godot Engine，并分别查询 4.7 Tween 终止、TileMapLayer/AStarGrid2D 点数据和嵌入窗口/屏幕读取的分层。结果与既有固定文档快照及当前 4.7.2 二进制核对。未采用 Context7 关于较高 CanvasLayer 更早执行的转述：数值更大的层绘制在较低层上方。SceneMultiplayer 是 RefCounted，并非某论坛帖子所称的 Node。数组深拷贝并不普遍克隆 Resource 元素。作者已撤回根因判断的 UID 崩溃报告，不会被转换成删除缓存的修复方案。

## 验收边界

七个独立复制的项目及一个 headless 渲染负例登记于 tests/cases.json。背包覆盖规则/HUD/JSON 操作；对话覆盖通过 action 派发的键盘选择，不包括指针/CJK 布局。AI 使用提供的可见性信息；操作预算不是毫秒级性能保证。弹窗 GPU 检查适用于 Compatibility 下的嵌入式 Windows 窗口，不覆盖原生窗口或所有渲染器。未声称已验证真实编辑器预览断点交互、公网多人、团队 AI 和安装宿主后的自动路由。实际执行命令及结果在验证后写入 community-validation.json；此前报告仍为历史记录。

## 本次实测

Windows 上的 Godot 4.7.2：完整 61 案例套件均符合预期结果，包括八个新增案例（七个正常示例与 headless GPU 拒绝）。组合的剧情/背包夹具在三次对话重启中验证由规则管理的单次奖励和重新加载的任务事实。GPU 截图同时经过视觉检查和数值核对。自审修正了 JSON 数值归一化、过期对话选项、删除 AI 目标、状态边界滞回及分阶段哈希读回。原有 23 个 skill 的宿主路由证据仍为历史记录；本批次 godot-ai 仅有作者审核的路由和原生执行证据。

[完整原生/GPU/打包/搬移日志](https://gist.github.com/wangdiandao/55cebaeea4b1ee5eeb5354a12da4f9b9)已发布，仓库路径前缀经过规范化。原始本地日志哈希保留在验证记录中。最终归档哈希与搬移检查独立记录于 PR。
