# Godot Skill 覆盖总览

[English](coverage.md) | **简体中文**

[文档首页](README.zh.md) · [双语 Skill 目录](skill-catalog.zh.md) · [验证证据](evidence.zh.md)

固定文档：4.7，提交9adca4c1c72917bfe1b7be3108abed5ce26696a6；本机标准/ .NET引擎：4.7.2。全文档1,596源页与2生成页面已读，页面记录见[研究入口](research/README.md)。阅读不是能力运行验收。

24个入口保留原有调用名称，包含架构、性能、编辑器工具、C#、GDExtension与新增游戏AI决策。每个入口连接对应操作配方、诊断路径和隔离案例。具体能力范围以[能力索引](capabilities.json)与本次证据为准。

| Skill | 开发任务 | 修改任务 | 诊断任务 |
|---|---|---|---|
| [godot-workflow](../skills/godot-workflow/SKILL.md) | 构建并验证完整 Godot 2D 循环，包含开始、移动/碰撞、收集、胜利、保存/读回和键盘重启。 | 为可玩循环新增有限跳跃资源，贯穿 HUD、命令检查及重启重置。 | 多次重启后计分和音效在多个系统中重复；追踪完整循环，验证重复重启能恢复一致的游戏状态。 |
| [godot-project](../skills/godot-project/SKILL.md) | 创建包含持久化跳跃输入和 Session Autoload 的 Godot 项目配置，启动并验证引导状态。 | 新增持久化输入动作，区分临时 InputMap 变更与已保存的项目配置。 | Session 在脚本测试中存在，项目重启后消失；检查保存的 Autoload 条目和启动就绪状态。 |
| [godot-api](../skills/godot-api/SKILL.md) | 核验瓦片层和导航烘焙的公开 Godot 绑定，通过最小真实调用证明场景打包/保存的归属。 | 将 Godot 4.7 调用适配到旧引擎前，检查准确的公开绑定与最低版本。 | 方法出现在 Godot C++ 源码中，GDScript 却报告不存在；区分内部方法与已绑定 API。 |
| [godot-gdscript](../skills/godot-gdscript/SKILL.md) | 实现带类型的 Godot 计数器，包含信号派发和异步继续执行；验证重连与断开行为。 | 将计数器重构为带类型的 GDScript，确保更新后不调用已断开的接收者。 | 等待中的玩法逻辑不再继续；检查节点生命周期和实际等待的信号。 |
| [godot-scenes](../skills/godot-scenes/SKILL.md) | 创建含有归属子节点和持久化信号的 Godot 打包场景；验证重载后信号执行，且不包含无 owner 的预览节点。 | 向既有场景新增持久化子节点和连接，同时保留归属与实例边界。 | 生成的子节点在保存后消失；检查 owner 与 parent，验证 PackedScene 读回。 |
| [godot-assets](../skills/godot-assets/SKILL.md) | 生成并导入 Godot 纹理，修改源宽度后重导入，再恢复缺失源文件并验证 glTF 边界。 | 将纹理源从 32 改为 64 像素，将 glTF 三角形宽度从一改为二；重导入时保留无关文件。 | 源图像消失但导入元数据仍在；仅恢复该源文件，验证纹理可加载。 |
| [godot-2d](../skills/godot-2d/SKILL.md) | 创建边缘匹配的三格 Godot 地形条，验证保存单元格和世界到地图的坐标转换。 | 仅替换 2D 关卡中的一个图集瓦片，保留单元格坐标和共享 TileSet 的使用者。 | 地形连接的左边缘有接缝；重绘前检查地形相邻位和缺失组合。 |
| [godot-3d](../skills/godot-3d/SKILL.md) | 构建含方盒、相机和太阳光的 Godot 3D 场景，独立调整第二个网格并验证保存尺寸。 | 调整一个方盒实例的尺寸，不改变共享原模型，保留相机和灯光节点。 | 3D 场景全黑；改变灯光前检查当前相机、裁剪和可见性。 |
| [godot-physics](../skills/godot-physics/SKILL.md) | 创建落在地板上的 Godot 角色，按每秒单位移动，带掩码射线检测，并且只触发一次穿越事件。 | 修改水平移动速度，保留地面接触，不重复应用 delta。 | 射线未命中可见地板；检查碰撞掩码，并验证错误掩码会按预期不命中。 |
| [godot-navigation](../skills/godot-navigation/SKILL.md) | 烘焙并保存 Godot 导航，验证跨两个区域的路径，以及对排除或禁用目标的拒绝。 | 禁用一个导航区域并调整层掩码，保留经过其余连通区域的路线。 | 路径跨区域时在终点之前停止；检查同步、连通性和导航掩码。 |
| [godot-ui](../skills/godot-ui/SKILL.md) | 构建带继承 Theme、局部覆盖读回、聚焦按钮输入和先阻止后允许点击的覆盖层的 Godot 菜单。 | 移除一个按钮的局部字体颜色覆盖，让父 Theme 再次生效。 | 不可见 Control 阻止按钮点击；检查 mouse_filter，验证覆盖层忽略输入后按钮可激活。 |
| [godot-animation](../skills/godot-animation/SKILL.md) | 创建 Godot 位置动画库，计算中点并重载保存的轨道和关键帧。 | 修改移动片段时长，不编辑无关轨道，也不与 AnimationTree 播放争用。 | AnimationPlayer 播放但目标不动；检查根节点和属性轨道路径。 |
| [godot-rendering](../skills/godot-rendering/SKILL.md) | 创建 Godot canvas 着色器材质，保存色调，在隔离 uniform 修改前后验证真实 GPU 像素。 | 仅修改一个材质实例的色调，证明原共享材质保留已保存颜色。 | Inspector 中着色器参数变化但像素不变；检查绑定材质和绘制帧读回。 |
| [godot-audio](../skills/godot-audio/SKILL.md) | 生成短单声道 Godot WAV，让播放器经过带限幅器的总线，保存/读回路由并测试静音/取消静音和播放结束。 | 仅将 SFX 总线降低十二分贝，在保存的布局中保留 Master 发送和限幅器。 | 播放器指向不存在的总线；播放前检测缺失路由，验证非循环播放结束。 |
| [godot-data](../skills/godot-data/SKILL.md) | 实现并验证版本化 Godot 存档迁移、受保护提交、备份读回和恢复，保留损坏/未来版本文件。 | 将第一版分数迁移为第二版进度，拒绝并发写入，不覆盖较新的存档。 | 玩家存档损坏且备份无效；报告需要恢复并保留两份原文件。 |
| [godot-multiplayer](../skills/godot-multiplayer/SKILL.md) | 创建本地 Godot 服务端和客户端，包含生成、复制和 RPC；拒绝无效权限/越界，验证断线和重连。 | 修改多人命令处理器，在服务端检查发送者归属和预算。 | 客户端重连后保留过期复制状态；检查 peer ID、断线清理及生成/同步器路径。 |
| [godot-validation](../skills/godot-validation/SKILL.md) | 创建有界 Godot 检查，检测解析错误、运行故障、退出零但有错误、超时和缺失报告，并拒绝无关失败。 | 加强测试执行器，确保子进程 passed 标记不能掩盖启动错误或缺失报告。 | 测试在 push_error 后仍退出零；检查完整进程日志和预期失败原因。 |
| [godot-export](../skills/godot-export/SKILL.md) | 创建 Windows Godot 导出预设，导入微型项目，用既有匹配模板构建并启动实际导出程序。 | 仅修改导出架构和自定义 release 模板，保留其它预设。 | 导出因模板缺失失败；重新构建前核实实际版本和模板路径。 |
| [godot-architecture](../skills/godot-architecture/SKILL.md) | 创建带注入服务和命令/事实信号的 Godot 模块；验证就绪、重复连接、替换和销毁。 | 替换组件服务依赖，不保留对旧服务的订阅者。 | 重载关卡后服务通知重复；追踪模块生命周期和幂等信号连接。 |
| [godot-performance](../skills/godot-performance/SKILL.md) | 对固定 512 角色快照中的距离/平方距离半径查询做基准，包含预热、分布和行为等价性。 | 优化已测半径查询，保留零、小、大半径及位置变更后的结果。 | 游戏卡顿但平均 FPS 正常；改动功能前建立匹配负载并比较帧节奏分布。 |
| [godot-editor-tools](../skills/godot-editor-tools/SKILL.md) | 实现 Godot 编辑器 dock，通过撤销/重做添加有 owner 的标记，保存/重载场景并经受重复禁用/启用。 | 让编辑器场景变更使用场景上下文的撤销管理器，并正确持久化新增子节点。 | 插件禁用后再次启用出现重复 dock；在真实编辑器进程中检查注册与清理。 |
| [godot-csharp](../skills/godot-csharp/SKILL.md) | 构建带限幅 Score 和生成的 ScoreChanged 信号的 Godot C# Resource，验证方法调用及无缓存保存/读回。 | 通过复制、修改、重新赋值改变 C# Node 位置，运行场景前重新构建 partial 类。 | 当前 Godot 程序无法使用 .cs Resource；归咎于缓存前识别标准或 .NET 构建。 |
| [godot-gdextension](../skills/godot-gdextension/SKILL.md) | 构建并加载暴露 score、add、score_changed 的原生 Godot Resource，验证限幅和保存后的独立读回。 | 为原生扩展新增公开属性，注册 getter/setter 和存储元数据，再构建并加载。 | 扩展 DLL 存在但 Windows 报加载错误 126；检查依赖 DLL、ABI 和 feature 路径。 |

## 验证边界

独立Codex代理实际完成69项语义选路，并分别执行23项显式调用和23项自然语言代表任务；每组21项通过、2项正确报告额外工具链未就绪。C#另有实际构建与14项运行断言，原生扩展另有编译与13项运行断言。原生冷启动扫描的引擎故障仍保留为失败；隔离案例的启动登记→导入→13项运行断言流程已由主代理与独立审核复测通过。宿主桌面自动发现、视觉HDR校准、真实听感及其他平台没有借用这些结果。详见[独立任务评估](research/task-evaluation.md)。

默认执行依然使用Godot原生CLI/GDScript。仅C#任务需要匹配Godot.NET与.NET SDK；仅GDExtension任务需要匹配绑定、C++编译器与构建工具。编辑器工具示例需要正常编辑器MainLoop，与普通--script执行不同。引擎源码内部优化仅保留研究结论和边界。

## 社区实践与新增AI入口

[godot-ai](../skills/godot-ai/SKILL.md)负责敌人目标与动作决策、效用评分和有界规划；路径与避障仍由navigation负责。示例覆盖提供的感知快照与决策，不声称真实视线、战斗、团队规划或宿主隐式触发已测。新增配方与当前证据见[社区实践实施记录](community-practices.zh.md)。上面的23入口独立代理结果保留为历史证据，不能自动扩展到新入口。
