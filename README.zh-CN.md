# AltForge

[English](README.md) | **简体中文**

> 一个持续维护的 AltStore Classic 衍生项目，重点改善侧载可靠性、Unicode 兼容、本地化和长期未修复的问题。

[![Swift 语言模式](https://img.shields.io/badge/Swift_language_mode-5.0-orange.svg)](https://swift.org/)
[![许可证：AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![欢迎 PR](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/legeling/AltForge/pulls)

## 项目简介

AltForge 是 [AltStore](https://github.com/altstoreio/AltStore) 的独立衍生项目。它保留熟悉的 AltStore/AltServer 架构，同时维护上游 Classic 分支尚未提供、或者已经不再维护的兼容性修复和用户体验改进。

AltForge 当前构建为 **AltStore Classic** 应用。`marketplace` 是历史分支名称，不代表发布版本会嵌入 Marketplace extension 或 entitlement。

## AltForge 的主要修改

| 范围 | AltForge 的修改 |
|---|---|
| 产品标识 | 使用 AltForge 品牌、`com.legeling.AltForge` bundle identifier 系列，以及本仓库 GitHub Release 提供的官方 source。 |
| Unicode IPA 安装 | 保留 Unicode 显示名和资源路径，支持 UTF-8、Info-ZIP Unicode Path 元数据，并对常见东亚旧式 ZIP 文件名编码提供有界 fallback。 |
| Apple App ID 兼容 | 只把发送给 Apple 的 App ID description 转为安全 ASCII，不修改应用安装到设备后的 Unicode 显示名。 |
| 简体中文 | 提供简体中文资源，支持 iOS 单 App 语言切换，并保留英文 fallback。 |
| 开发团队 | 客户端和 AltServer 安装链路均支持个人、组织和免费开发团队 fallback。 |
| 维护修复 | 防止已过期应用显示负数天数；macOS 错误详情保留富文本格式并支持选择复制。 |
| 构建与发布 | 提供有超时边界的 CI，以及由版本标签触发的 IPA、macOS AltServer、source metadata 和 checksum 打包流程。 |
| 项目文档 | 在 [`docs/`](docs/README.md) 中维护需求、架构、验证、Issue、变更记录和贡献规则。 |

通用修复会尽量与 AltForge 品牌改动分离，以便在合适时回馈给上游项目。

## 功能

- 通过 Wi-Fi 或已连接设备使用 AltServer 安装、刷新和更新侧载应用。
- 使用个人、组织或免费 Apple 开发团队为应用签名。
- 安装应用名或资源文件名包含中文及其他 Unicode 字符的 IPA。
- 使用英文或简体中文界面，并支持 iOS 单 App 语言切换。
- 添加和更新兼容的 AltStore source，并使用稳定 source identity 去重。
- 保留客户端与 AltServer 间的结构化错误信息，提供更有用的诊断。
- 在满足平台要求时使用项目现有的 Widget、Backup 和 JIT 可选组件。

## 环境要求

### 使用 AltForge

- iOS 或 iPadOS 17.4 及以上版本。
- AltServer 需要 macOS 11 及以上版本。
- 可选的 AltJIT target 需要 macOS 13 及以上版本。
- 一个 Apple ID 和可用的 Apple 开发团队。

### 构建 AltForge

- 安装 Xcode 26 的 macOS。
- CocoaPods。
- 支持递归 submodule 的 Git。
- 项目当前在 Xcode 26 工具链下使用 Swift 5.0 language mode，尚未迁移到 Swift 6 language mode。

## 下载与安装

发布版本可从本仓库的 [GitHub Releases](https://github.com/legeling/AltForge/releases) 下载。一个版本标签预期生成以下文件：

- `AltForge.ipa`：未签名的 AltStore Classic 安装包，由 AltServer 针对所选 Apple ID、开发团队和设备完成签名。
- `AltForge-AltServer-macOS.zip`：macOS AltServer 应用。
- `apps.json`：AltForge 官方 source metadata。
- `SHA256SUMS.txt`：发布产物的 SHA-256 校验和。

不能通过在 iPhone 或 iPad 上直接点击 IPA 完成安装。请先安装 macOS AltServer，连接并信任设备，然后在 AltServer 中选择 **Install AltForge**。AltServer 会请求 Apple 签名流程所需的账户信息。

当前 macOS 压缩包尚未使用 Developer ID 签名或 notarization。macOS 可能要求通过 Finder 右键菜单打开 AltServer。安装前请核对发布页提供的 checksum。

## 从源码构建

```sh
git clone --recurse-submodules https://github.com/legeling/AltForge.git
cd AltForge
git submodule update --init --recursive
pod install --deployment
open AltStore.xcworkspace
```

在 Xcode 中：

1. 为 AltStore、AltWidgetExtension 和 AltBackup targets 选择自己的开发团队。
2. 如果直接从 Xcode 运行 AltForge，在 AltStore 的 Info.plist 中把 `ALTDeviceID` 设置为目标设备 UDID。
3. 可以把 `ALTServerID` 设置为 AltServer 通过 Bonjour 广播的 `serverID`。不设置时，AltForge 仍会尝试其他可用服务器。
4. 选择 AltStore 或 AltServer scheme，并构建所需 target。

可重复使用的命令行构建和测试命令记录在[验证文档](docs/workflow/04-verification/README.md)中。签名、provisioning、设备安装和 JIT 相关改动仍需要制定脱敏的真实设备验证计划。

## 发布流程

Pull Request 和对 `marketplace` 的推送会使用仓库 CI workflow。语义化版本标签会触发 release workflow：

```sh
VERSION=2.3.4
git tag "v${VERSION}"
git push origin "v${VERSION}"
```

该流程会构建未签名 IPA 和 universal macOS AltServer，生成 `apps.json` 与 checksum，然后把产物附加到 GitHub Release。只有发布维护者在完成文档中的质量门禁后才能创建标签和发布版本。

## 项目结构

| 路径 | 职责 |
|---|---|
| `AltStore/` | iOS 用户界面和应用管理流程。 |
| `AltServer/` | macOS 认证、签名准备和设备安装。 |
| `AltStoreCore/` | 共享领域模型、持久化、source 和工具。 |
| `Shared/` | 客户端/服务端协议和共享应用行为。 |
| `Dependencies/AltSign/` | Apple Developer API、签名、应用模型和 IPA/ZIP 处理。 |
| `AltTests/` | 共享行为和应用逻辑的 XCTest。 |
| `docs/` | 需求、设计、验证、Issue、变更、ADR、发布和项目规则。 |

为了减少与上游同步时的无意义冲突，仓库保留历史 `AltStore`、`AltServer` 和 `ALT*` 代码标识；对外产品文案和官方 source identity 使用 AltForge。

## 文档与贡献

请先阅读[文档入口](docs/README.md)和项目级 [Agent/贡献规则](AGENTS.md)。提交约定和工程门禁位于 [`docs/rules/`](docs/rules/README.md)。

当前路线、测试缺口和已知风险分别记录在：

- [当前任务](docs/workflow/05-tasks/README.md)
- [验证与覆盖情况](docs/workflow/04-verification/README.md)
- [Issue 登记表](docs/issues/README.md)
- [变更记录](docs/changes/README.md)

## 已知限制

- 本仓库当前没有 Windows AltServer build target。
- macOS 发布包尚未使用 Developer ID 签名或 notarization。
- Unicode archive 兼容已经通过实现级验证，但持久化 AltSign 自动测试 fixture 和更广泛的真实设备覆盖仍在补充。

## 上游与许可证

AltForge 派生自 [altstoreio/AltStore](https://github.com/altstoreio/AltStore)。仓库保留独立 upstream remote，使兼容修复可以双向同步。AltSign 相关兼容工作维护在 [AltForge AltSign fork](https://github.com/legeling/AltSign)，并持续追踪 [AltSign upstream](https://github.com/rileytestut/AltSign)。

AltForge 使用 [GNU Affero General Public License v3.0](LICENSE) 发布。第三方依赖继续使用各自的许可证。
