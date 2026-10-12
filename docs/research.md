# 研究基线与技术选择

核对日期：2026-10-11。基线为 **4.7.2-stable**，官方构建提交 `ed1daf0bf001b61586d9930840f2f1394092c079`。发行信息来自[官方 release](https://github.com/godotengine/godot/releases/tag/4.7.2-stable)及[官方 API](https://api.github.com/repos/godotengine/godot/releases/tags/4.7.2-stable)，不是根据模型记忆推定版本。

本机使用匹配标准 Windows 编辑器二进制、官方导出模板和官方源码归档。下载摘要与官方发行元数据核对：

| 资产 | SHA256 |
|---|---|
| Godot_v4.7.2-stable_win64.exe.zip | `731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953` |
| Godot_v4.7.2-stable_export_templates.tpz | `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` |

人类文档固定到 en/4.7；该分支仍可能变化，因此精确 patch 的接口判断同时使用同 tag 源码、源码中的类 XML 和本机 `--dump-extension-api-with-docs`。能力索引提供各领域对应的官方类文档和固定提交 XML 链接。

Context7 后续在会话中可用，已解析 Godot Engine 并选择 `/godotengine/godot-docs/__branch__4.7`，分别查询 CLI/导出、PackedScene 保存、导航同步三个概念。结果中夹杂 master 来源时不将其视为 4.7.2 证据；关键结论再由固定源码和运行测试确认。Context7 不随插件声明或安装。

## 关键判断

| 结论 | 官方依据与验证 |
|---|---|
| CLI 脚本是 SceneTree/MainLoop | [CLI 文档](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)，所有辅助脚本实际运行 |
| 原生导入与导出可脱离交互编辑器 | 同上；干净副本导入、Windows/Web 构建及 Windows 产物运行 |
| 场景 owner 和持久化信号不可省略 | [PackedScene](https://docs.godotengine.org/en/4.7/classes/class_packedscene.html)、[Object](https://docs.godotengine.org/en/4.7/classes/class_object.html)，保存后重载并触发信号 |
| 导航可使用 CPU 几何烘焙 | [源几何 API](https://docs.godotengine.org/en/4.7/classes/class_navigationmeshsourcegeometrydata3d.html)，烘焙非空网格并跨区域寻路 |
| map/region 更新需要等待 | [NavigationServer3D](https://docs.godotengine.org/en/4.7/classes/class_navigationserver3d.html)，等待有效 iteration 与区域后路径通过 |
| LightmapGI.bake 不向 GDScript 暴露 | [绑定源码](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/3d/lightmap_gi.cpp#L2122)，本机 ClassDB 为 false |
| GUI 输入不能只用 action_press 代替 | [Input](https://docs.godotengine.org/en/4.7/classes/class_input.html)，parse_input_event 驱动聚焦按钮与游戏 |
| headless 不证明真实渲染 | [CLI](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)，真实 GPU Shader 像素检查和游戏截图 |
| 导出预设不能漏 include_filter | [预设读取源码](https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export.cpp#L378)，缺失会写错误日志；补齐后通过 |
| 导入错误可能退出 0 | [导入流程](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html)，损坏 PNG 故障案例实际观察，父执行器识别失败 |

## 无外部工具的边界

原生资源、程序化几何、UI、GDScript、物理、导航、动画、音效和序列化可用标准能力操作；引擎已有导入和导出流程直接复用。高级渲染/编辑器功能逐项检查公开 API、GPU 条件和上下文，不声称所有可视化按钮都有脚本等价物。

在 `--editor --script` 探针中可访问 EditorInterface/EditorFileSystem，但本机退出出现资源泄漏日志；该路径没有列为生产辅助脚本的通过能力。常规操作采用原生 `--import` 与普通 SceneTree 资源 API。平台 SDK、签名、无公开绑定的烘焙与外部 DCC 格式如实保留边界。
