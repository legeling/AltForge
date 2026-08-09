<p align="center">
  <img src="../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Issue Register

本目录跟踪项目风险、阻塞项、技术债及其解决状态。GitHub Issue 用于公开协作，本目录保存会影响设计、验证和交付的稳定摘要与已解决决策。

| ID | 标题 | 优先级 | 状态 | 关联 |
|---|---|---:|---|---|
| [`ISSUE-20260808-001`](ISSUE-20260808-001-unicode-regression-tests.md) | Unicode IPA 修复缺少持久自动化测试 | P1 | Open | `FR-004`, `FR-005`, `T-001` |
| [`ISSUE-20260808-002`](ISSUE-20260808-002-swift-version-baseline.md) | Swift 6 文档口径与 Swift 5 build setting 不一致 | P2 | Resolved | `NFR-003`, `CHG-20260809-001` |
| [`ISSUE-20260808-003`](ISSUE-20260808-003-macos-distribution-signing.md) | macOS release 未签名且未 notarize | P1 | Open / 待确认 | `DES-010` |
| [`ISSUE-20260808-004`](ISSUE-20260808-004-windows-scope.md) | Windows AltServer 范围决策 | P2 | Resolved | `CHG-20260809-002` |
| [`ISSUE-20260808-005`](ISSUE-20260808-005-clean-build-reproducibility.md) | 干净 checkout 的本地完整构建尚未验证 | P1 | Open | `FR-014`, `T-002` |
| [`ISSUE-20260808-006`](ISSUE-20260808-006-altsign-classic-baseline.md) | AltSign submodule 仍基于 Marketplace 配置 | P0 | Open | `FR-001`, `FR-002`, `T-011` |
| [`ISSUE-20260808-007`](ISSUE-20260808-007-zh-error-test-spacing.md) | 简体中文环境下错误描述测试存在空格假设 | P1 | Open | `FR-011`, `TEST-010`, `T-006` |
| [`ISSUE-20260809-001`](ISSUE-20260809-001-windows-build-device-validation.md) | Windows 构建与真实设备验证待完成 | P1 | Open | `FR-018`, `FR-019`, `T-012` |

## 状态规则

- `Open`：仍影响计划或交付。
- `Blocked`：连续确认无法推进且依赖外部输入。
- `Resolved`：修复已验证，并同步 requirements/design/verification/change。
- `Accepted`：风险被明确接受，有 owner 与复查条件。
