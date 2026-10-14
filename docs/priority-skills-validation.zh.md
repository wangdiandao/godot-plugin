# 重点技能实施与验证

[English](priority-skills-validation.md) | **简体中文**

[文档首页](README.zh.md) · [Skill 目录](skill-catalog.zh.md) · [证据索引](evidence.zh.md)

Issue：[#21](https://github.com/wangdiandao/godot-plugin/issues/21)。源码版本：0.2.2。本次变更保留全部 23 个 skill 名称和 Godot 原生运行方式。

## 已实现的任务合同

| Skill | 配方 | 独立案例 |
|---|---|---|
| godot-gdscript | [异步取消、替换与信号重入](../skills/godot-gdscript/references/tasks.md) | gdscript-async-lifecycle |
| godot-navigation | [真实代理运动、巡逻与避障回调](../skills/godot-navigation/references/movement.md) | navigation-moving-agent |
| godot-animation | [状态转换、混合与动作中断](../skills/godot-animation/references/locomotion.md) | animation-state-machine |
| godot-physics | [3D 运动、斜坡、刚体唤醒/冲量与快速点扫掠](../skills/godot-physics/references/controllers.md) | physics-body-3d |
| godot-3d | [程序化法线/切线与持久化骨骼挂点](../skills/godot-3d/references/models.md) | 3d-mesh-socket |
| godot-assets | [原生导入设置与保留创作的包装场景](../skills/godot-assets/references/pipelines.md) | assets-import-repair |
| godot-scenes | [重命名导出/动画路径且不展开实例](../skills/godot-scenes/references/refactoring.md) | scenes-refactor |
| godot-workflow | [跨系统资源命令、HUD 与重复重启](../skills/godot-workflow/references/vertical-slice.md) | workflow-bounded-resource |

动画另含 event-rig，导航另含单向链接。两个可玩示例都验证无效/未来版本存档及写入冲突时的字节保留。示例代码为原创，没有复制 Unity 源码或美术资源。

## 证据边界

[本次机器可读报告](priority-skills-validation.json)记录准确命令模板、引擎/平台、完整进程判定与具名断言。初次失败尝试与最终修正后的运行分开记录。历史报告仍是历史记录。运行执行不能证明安装后的宿主模型路由。

未认证其它平台/后端、任意美术骨骼、群体避障质量、真实音频/HDR、手柄/无障碍、断电持久性及跨进程存档锁。点扫掠不证明有限宽度或移动目标的 CCD。导入包装场景/材质保留不证明嵌套可编辑材质覆盖。链接图检查不证明实际跳跃。

## 复现

将 GODOT、PLUGIN 和新的 OUT 解析为绝对路径。使用标准 4.7.2 Windows 控制台编辑器，并在调用前创建 OUT：

```text
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/shared/scripts/run_checks.gd --log-file OUT/suite.log -- --manifest PLUGIN/tests/cases.json --out OUT/cases
python -X utf8 PLUGIN/tests/validate_structure.py --root PLUGIN --schema PLUGIN/artifacts/research/plugin.schema.json --report OUT/structure.json
GODOT --headless --path PLUGIN/shared/host --script PLUGIN/tests/package.gd --log-file OUT/package.log -- --root PLUGIN --out OUT/package
```

Schema 校验使用既有、被忽略的研究 schema，不属于干净 checkout 的依赖。报告记录其是否实际可用。源码和安装归档经过读回，记录 SHA256 值；搬移后的安装副本运行新增任务夹具。

## 本次结果

53 个清单案例均符合预期结果：42 个正常通过、六个预期失败、一个预期超时、两个不支持控制和两个工具链缺失控制。这 11 个控制认证诊断/前置检查，不代表故障操作成功。十个新增夹具和两个游戏在包搬移后通过。结构/schema/链接检查通过 1,456 项。最终自审在已记录修正后未发现剩余可操作问题。
