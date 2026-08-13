# 上游 Issue 主题报告

这里按维护责任和验证门禁拆分 `altstoreio/AltStore` 的全部 645 个开放 Issue。每个文件都包含该主题的范围、合并依据、AltForge 处置和完整条目清单。

| 顺序 | 主题 | 数量 | 主要处置 |
|---:|---|---:|---|
| 1 | [Apple 认证、2FA、团队与 Provisioning](01-apple-authentication-and-teams.md) | 95 | `tracked-merged` |
| 2 | [IPA、签名、归档路径与扩展](02-ipa-signing-and-packaging.md) | 81 | `tracked-merged` |
| 3 | [设备发现、USB、Wi-Fi 与 Server 连接](03-device-discovery-and-connectivity.md) | 34 | `tracked-merged` |
| 4 | [刷新、停用、备份与应用生命周期](04-refresh-backup-and-lifecycle.md) | 49 | `tracked-merged` |
| 5 | [AltJIT、Developer Disk、隧道与进程选择](05-altjit-runtime.md) | 55 | `tracked-merged` |
| 6 | [macOS/Windows 桌面分发与安装器](06-desktop-distribution.md) | 50 | `tracked-merged` |
| 7 | [源码构建与开发环境](07-build-and-development.md) | 6 | `tracked-merged` |
| 8 | [iOS 运行时、崩溃、UI 与本地化](08-ios-runtime-ui-and-localization.md) | 59 | `tracked-merged` |
| 9 | [Source、下载、网络与远程配置](09-sources-downloads-and-network.md) | 71 | `covered-by-existing-requirements` |
| 10 | [未进入当前路线的功能建议](10-unplanned-feature-requests.md) | 52 | `not-currently-planned` |
| 11 | [Marketplace、PAL 与替代市场](11-marketplace-and-pal.md) | 23 | `out-of-scope` |
| 12 | [越狱、AltDaemon 与旁路安装环境](12-jailbreak-and-altdaemon.md) | 17 | `out-of-scope` |
| 13 | [Apple TV 与 tvOS](13-apple-tv-and-tvos.md) | 4 | `out-of-scope` |
| 14 | [Linux 与远程 AltServer](14-linux-server.md) | 3 | `out-of-scope` |
| 15 | [证据不足、空内容与无法行动条目](15-insufficient-evidence.md) | 46 | `insufficient-actionable-evidence` |

主题总数必须与 [`altstore-open-issue-audit.json`](../altstore-open-issue-audit.json) 的 `count` 一致。审计方法和处置规则分别见 [`METHODOLOGY.md`](../METHODOLOGY.md) 与 [`SCOPE-AND-DISPOSITION.md`](../SCOPE-AND-DISPOSITION.md)。
