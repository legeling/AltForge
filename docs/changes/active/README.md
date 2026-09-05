<p align="center">
  <img src="../../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Active Changes

正在实施的新需求、bugfix、重构和流程变化放在本目录。每个 change 使用独立目录，并包含背景、影响、追踪链、tasks、验证计划和收敛清单。

## 当前变更

| ID | 标题 | 状态 |
|---|---|---|
| [`CHG-20260809-002`](CHG-20260809-002-windows-altserver-monorepo/README.md) | 将 Windows AltServer 纳入单仓库交付 | In progress |
| [`CHG-20260809-007`](CHG-20260809-007-macos-server-identity-settings/README.md) | macOS Server 身份、菜单与设置 | In progress |
| [`CHG-20260810-002`](CHG-20260810-002-macos-menu-icon-scale/README.md) | 放大 macOS 菜单栏图标 | Implemented / menu bar smoke pending |
| [`CHG-20260810-001`](CHG-20260810-001-macos-inline-settings-menu/README.md) | macOS 菜单内联设置与安装图标修复 | In progress / live settings smoke |
| [`CHG-20260810-003`](CHG-20260810-003-macos-apple-id-account-manager/README.md) | macOS Apple ID 账号管理 | In progress |
| [`CHG-20260810-004`](CHG-20260810-004-resilient-macos-installation/README.md) | macOS 可见安装进度与可靠 Release 下载 | In progress |
| [`CHG-20260810-005`](CHG-20260810-005-ios-app-group-migration-fallback/README.md) | iOS App Group 迁移降级修复 | In progress |
| [`CHG-20260811-004`](CHG-20260811-004-ios-install-crash-diagnostics-authentication/README.md) | iOS 安装中断崩溃、恢复日志与认证说明 | In progress / device E2E pending |
| [`CHG-20260811-006`](CHG-20260811-006-ios-theme-color-selection/README.md) | iOS 主题色选择与默认品牌色 | Release build passed / visual matrix pending |
| [`CHG-20260812-001`](CHG-20260812-001-preserve-healthkit-capability/README.md) | 重签名时保留 HealthKit 能力 | In progress / device verification pending |
| [`CHG-20260904-001`](CHG-20260904-001-apple-authentication-response/README.md) | 修复 Apple 认证响应格式失败 | Released in v2.4.4 / real login unresolved |
| [`CHG-20260904-002`](CHG-20260904-002-user-facing-error-copy/README.md) | 统一错误码与用户提示 | Released in v2.4.2 / device UI validation pending |
| [`CHG-20260904-003`](CHG-20260904-003-macos-direct-update-download/README.md) | macOS 检查更新直接下载并打开安装器 | Released in v2.4.3 / manual update UI pending |

已完成工作不得继续留在这里；完成 converge 后移动到 `completed/YYYY/MM/`，被放弃或替代时移动到 `legacy/YYYY/MM/`。
