<p align="center">
  <img src="../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Issue Register

本目录跟踪项目风险、阻塞项、技术债及其解决状态。GitHub Issue 用于公开协作，本目录保存会影响设计、验证和交付的稳定摘要与已解决决策。

## 上游 Issue 文档库

[`upstream/`](upstream/) 保存对 `altstoreio/AltStore` 全部 645 个开放 Issue 的审计。正文已经拆为审计方法、范围与处置规则、15 份主题报告、完整逐条附录和机器可读数据；本页只索引 AltForge 自己的长期风险，不承载上游分析正文。

## Open

| ID | 标题 | 优先级 | 状态 | 关联 |
|---|---|---:|---|---|
| [`ISSUE-20260808-001`](ISSUE-20260808-001-unicode-regression-tests.md) | Unicode IPA 修复缺少持久自动化测试 | P1 | Open | `FR-004`, `FR-005`, `T-001` |
| [`ISSUE-20260808-003`](ISSUE-20260808-003-macos-distribution-signing.md) | macOS release 未签名且未 notarize | P1 | Open / 待确认 | `DES-010` |
| [`ISSUE-20260808-005`](ISSUE-20260808-005-clean-build-reproducibility.md) | 干净 checkout 的本地完整构建尚未验证 | P1 | Open | `FR-014`, `T-002` |
| [`ISSUE-20260808-006`](ISSUE-20260808-006-altsign-classic-baseline.md) | AltSign submodule 仍基于 Marketplace 配置 | P0 | Open | `FR-001`, `FR-002`, `T-011` |
| [`ISSUE-20260808-007`](ISSUE-20260808-007-zh-error-test-spacing.md) | 简体中文环境下错误描述测试存在空格假设 | P1 | Open | `FR-011`, `TEST-010`, `T-006` |
| [`ISSUE-20260809-001`](ISSUE-20260809-001-windows-build-device-validation.md) | Windows 构建与真实设备验证待完成 | P1 | Open | `FR-018`, `FR-019`, `T-012` |
| [`ISSUE-20260811-001`](ISSUE-20260811-001-macos-install-progress-device-regression.md) | macOS 安装进度真机回归待验证 | P0 | Open | `FR-031`, `TEST-030`, `T-019` |
| [`ISSUE-20260811-002`](ISSUE-20260811-002-ios-third-party-install-device-validation.md) | iOS 第三方 IPA 安装与恢复日志真机回归待验证 | P0 | Open | `FR-036`, `TEST-035`, `T-024` |
| [`ISSUE-20260811-003`](ISSUE-20260811-003-apple-authentication-team-compatibility.md) | Apple 认证、2FA 与团队类型兼容尚未完成实测 | P1 | Open | `FR-029`, `FR-030`, `TEST-028`, `TEST-029`, `T-018` |
| [`ISSUE-20260811-004`](ISSUE-20260811-004-altjit-runtime-compatibility.md) | AltJIT 依赖与新系统运行时兼容缺少验证 | P1 | Open | `FR-012`, `TEST-014`, `T-009` |
| [`ISSUE-20260811-005`](ISSUE-20260811-005-device-discovery-connectivity.md) | 设备发现与 AltServer 连接缺少跨平台实机矩阵 | P1 | Open | `DES-002`, `TEST-019`, `TEST-026`, `TEST-030`, `T-012`, `T-016`, `T-019` |
| [`ISSUE-20260811-006`](ISSUE-20260811-006-refresh-backup-lifecycle.md) | 刷新、停用、备份与失败清理缺少完整回归 | P1 | Open | `FR-008`, `TEST-015`, `TEST-017`, `T-008`, `T-010` |
| [`ISSUE-20260904-001`](ISSUE-20260904-001-apple-authentication-live-validation.md) | Apple 认证与设备安装覆盖缺口 | P0 | macOS 登录已确认；完整安装/平台矩阵待补齐 | `FR-041`, `TEST-040`, `T-040`, `CHG-20260905-002` |
| [`ISSUE-20260905-003`](ISSUE-20260905-003-ios-installed-app-tracking.md) | 已装 App 未进入管理列表、进度不可见与锁屏中断 | P0 | v2.4.6 已发布 / 设备验收待完成 | `FR-044`, `FR-045`, `TEST-043`, `TEST-044`, `CHG-20260905-003` |
| [ISSUE-20260905-004](ISSUE-20260905-004-source-permissions.md) | 官方更新源漏声明本地网络权限，触发 201 | P1 | v2.4.7 已发布 / 真机更新待确认 | `FR-046`, `TEST-045`, `T-044`, `CHG-20260905-004` |

## Resolved

| ID | 标题 | 优先级 | 状态 | 关联 |
|---|---|---:|---|---|
| [`ISSUE-20260808-002`](ISSUE-20260808-002-swift-version-baseline.md) | Swift 6 文档口径与 Swift 5 build setting 不一致 | P2 | Resolved | `NFR-003`, `CHG-20260809-001` |
| [`ISSUE-20260808-004`](ISSUE-20260808-004-windows-scope.md) | Windows AltServer 范围决策 | P2 | Resolved | `CHG-20260809-002` |

## 状态规则

- `Open`：仍影响计划或交付。
- `Blocked`：连续确认无法推进且依赖外部输入。
- `Resolved`：修复已验证，并同步 requirements/design/verification/change。
- `Accepted`：风险被明确接受，有 owner 与复查条件。
