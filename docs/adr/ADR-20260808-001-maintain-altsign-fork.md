# ADR-20260808-001：维护 AltSign fork

- 状态：Accepted
- 日期：2026-08-08

## Context

Unicode App ID 和 ZIP filename 问题属于 AltSign 的 Apple API/application archive 边界。只在 AltForge UI 或安装 Operation 中改名、重打包会复制逻辑，且 AltServer 与 iOS 端可能行为不一致。上游相关 Issue 长期未收敛。

## Decision

在 `legeling/AltSign` fork 的 `marketplace` branch 维护通用修复；AltForge `.gitmodules` 指向该 fork，nested repo 保留 `rileytestut/AltSign` 为 upstream。superproject 通过 gitlink 固定已验证 commit。

## Consequences

正面：

- 修复位于真实所有者，AltForge/AltServer 可复用。
- 通用 patch 更容易回馈上游。
- recursive clone 能获取固定 commit。

代价：

- 每次上游同步要处理 nested history、fork branch 和 superproject gitlink。
- AltSign 需要自己的测试和 CI，否则底层回归只能由 superproject 间接发现。

## Revisit

当上游合并等价修复且有覆盖测试时，可以把 `.gitmodules` 切回上游，并通过新的 ADR/change 记录迁移。
