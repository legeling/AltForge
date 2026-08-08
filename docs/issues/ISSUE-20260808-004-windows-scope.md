# ISSUE-20260808-004：Windows AltServer 范围未确定

- 状态：Open / 待确认
- 优先级：P2
- 发现日期：2026-08-08

## 问题

大量历史 Unicode/path Issue 发生在 Windows AltServer，但当前仓库没有 Windows build target，Release 也只生成 macOS server。

## 候选方案

- 继续明确排除：成本最低，但无法解决 Windows 用户路径/code-page 问题。
- 引入独立 Windows 项目/上游二进制：覆盖更广，但会新增工具链、发布和安全维护成本。
- 与外部项目协作：避免重复实现，但需要明确兼容与信任边界。

当前推荐：在没有维护资源和可构建源码方案前继续明确排除，不把 Windows 支持写成已交付能力。
