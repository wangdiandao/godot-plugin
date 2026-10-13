# Networking and delivery implementation

中文概览：联网、测试诊断与导出三个既有 Skill 已深化。联网案例含初始同步、非法命令拒绝、断开和同服重连；诊断案例按日志/退出码/结构化结果区分真实失败；导出配方区分配置、构建、启动和平台验收。

Issue #7. English4.7 documentation reading gate preceded implementation. Source revision ed1daf0bf001b61586d9930840f2f1394092c079, Windows Godot4.7.2 official.

## Behavior and actual evidence

The multiplayer fixture launches a server, two initial clients and a later client. It validates sender ownership, command bounds and a fixture rate budget, observes three accepted peer IDs, nine rejected requests and three disconnects, and checks late state99 after initial spawn42. Identity/epoch in this fixture is not production account authentication. Logs and engine exit codes are checked separately from reported status. Actual independent explicit and natural executions also pass this task.

Validation replaces the old ConfigFile-only example with seven controlled distinctions: parse failure, missing resource, logged error with exit0, runtime fault with timeout, silent timeout, missing report and rejection of an unrelated failure. The detector succeeds only when the intended symptom is observed; it does not relabel failed operations as successful game behavior.

Export preserves the default preset-edit path without template dependency. Its conditional Windows build path imports a generated fixture, uses the explicit exact-version template, exports executable/PCK and actually launches the artifact to check editor=false and a structured pass. Eleven assertions passed in the extension implementation run. See source fixture and invocation reference for --templates.

Fresh domain command evidence is recorded in the later tool/language evidence record (`extension-implementation.md`, included with that later domain batch); its report also includes this batch's three tasks. Root separately validates the exact staged20-Skill snapshot before submitting this batch. Both original task runs and staged validation remain distinct from historical docs/validation-results.json.

## Review and limits

The independent implementation review found no unresolved networking, validation or export defect. Out-of-band accounts/authentication, production packet abuse, WAN/loss/latency, browser execution, other OS/device exports, signing, console SDKs, managed debugger attachment, visual/audio acceptance and installed-host discovery remain untested. The recipes define their prerequisites and acceptance procedures; this batch does not count them as passed.

Native domain commands use the same checked task engine. ROOT and OUT below represent the absolute local paths resolved in the execution, with fresh OUT directories:

```text
GODOT --headless --path ROOT/skills/godot-multiplayer/assets/examples/minimal --script res://example.gd --log-file OUT/engine.log -- --out OUT
GODOT --headless --path ROOT/skills/godot-validation/assets/examples/minimal --script res://example.gd --log-file OUT/engine.log -- --out OUT
GODOT --headless --path ROOT/skills/godot-export/assets/examples/minimal --script res://example.gd --log-file OUT/engine.log -- --out OUT --templates ROOT/artifacts/tooling/templates
```

Final staged snapshot passes921 structure/schema/local-link checks. All three selected runner cases passed with clean logs and exit0; report artifacts/delivery-pr-runtime/cases/1791880691-153-3284/report.json. The exact staged export fixture also passed all11 assertions, including import, Windows release build and actual executable launch; report artifacts/delivery-pr-runtime/export-build/result.json.
