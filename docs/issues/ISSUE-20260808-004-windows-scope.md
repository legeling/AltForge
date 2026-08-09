# ISSUE-20260808-004：Windows AltServer 范围决策

- 状态：Resolved
- 优先级：P2
- 发现日期：2026-08-08

## 问题

大量历史 Unicode/path Issue 发生在 Windows AltServer，但当前仓库没有 Windows build target，Release 也只生成 macOS server。

## 候选方案

- 继续明确排除：成本最低，但无法解决 Windows 用户路径/code-page 问题。
- 引入独立 Windows 项目/上游二进制：覆盖更广，但会新增工具链、发布和安全维护成本。
- 与外部项目协作：避免重复实现，但需要明确兼容与信任边界。

## 决议

2026-08-09 决定把官方 `AltServer-Windows` 1.7.4 源码作为 `AltServer-Windows/` 快照纳入同一仓库，不使用额外产品分支或根级 submodule。Windows 以 unsigned portable ZIP 进入 CI/Release；固定源码依赖由有界脚本恢复，Apple 软件仍由用户从 Apple 官网安装。

Windows runner 和真实设备验证继续由 `ISSUE-20260809-001` 跟踪。关联：`CHG-20260809-002`、`FR-018`、`FR-019`、`DES-011`、`T-012`。
