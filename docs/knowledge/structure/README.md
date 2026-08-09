<p align="center">
  <img src="../../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# System Structure

## 仓库结构

| 路径 | 所有权与职责 |
|---|---|
| `AltStore/` | iOS 主应用、UI、AppManager 与 Operation 工作流 |
| `AltServer/` | macOS 菜单应用、Apple 认证、设备连接、签名安装与 JIT 协调 |
| `AltStoreCore/` | Core Data models、source/app domain、Keychain、共享 UI/utility |
| `Shared/` | client/server protocol、connections、跨进程错误与共享常量 |
| `AltBackup/` | 应用 container/app group 备份恢复 helper |
| `AltWidget/` | WidgetKit timeline 与 installed app snapshot |
| `AltJIT/` | macOS 命令行工具与 developer disk/JIT 操作 |
| `AltDaemon/` | daemon request handling 与 XPC bridge |
| `AltXPC/` | macOS XPC service |
| `AltPlugin/` | 历史 Mail/plugin integration |
| `AltMarketplace/` | MarketplaceKit extension；当前 Classic release 不嵌入 |
| `AltTests/` | XCTest，当前主要覆盖错误传输与 source ID |
| `Dependencies/` | Git submodules 和 vendored native dependencies |
| `Pods/` | 锁定的 CocoaPods integration |
| `.github/workflows/` | CI 与 tag release automation |
| `Scripts/` | 发布 metadata 等可重复工具 |

## Target 关系

```text
AltStore
  -> AltStoreCore
  -> Shared
  -> AltSign
  -> AltWidgetExtension / AltBackup (embedded helpers)

AltServer
  -> Shared
  -> AltSign
  -> libimobiledevice / libplist / libusbmuxd
  -> Sparkle / STPrivilegedTask

AltTests
  -> AltStore
  -> AltStoreCore
  -> AltSign
```

具体 target dependency 以 `AltStore.xcodeproj/project.pbxproj` 为准；本图只表达稳定边界，不替代构建配置。

## 集成关系

### Apple 服务

AltSign 封装 Apple Developer API、certificate、App ID、capability 与 provisioning profile。AltStore/AltServer 不应复制请求签名或认证协议。

### 设备服务

AltServer 通过 libimobiledevice 系列依赖和系统设备服务发现设备、安装 application、准备 developer disk 与处理 JIT。

### Client/Server

`Shared/Server Protocol` 定义 wire model；`ConnectionManager`、`NetworkConnection`、AltServer wired/wireless handlers 实现传输。修改 Codable 字段时必须验证旧 server/client 失败行为。

### 持久化

`DatabaseManager` 持有 Core Data persistent container。Widget 与 Backup 通过 app group 访问经允许的数据或文件；Keychain 保存敏感状态。

### 发布

GitHub Actions 从 workspace 构建产品，`Scripts/generate_release_metadata.rb` 根据实际 artifact 生成 source JSON 与 checksums。

## Submodule 规则

- 修改 submodule 前先检查 nested repository 的 branch、remote 和 dirty state。
- 通用改动先在 nested repo 提交并推送，再在 superproject 更新 gitlink。
- `.gitmodules` URL 必须能让新的 recursive clone 获取目标 commit。
- 不在 superproject commit 中隐藏未提交的 nested changes。

## 数据流边界

- 大型 IPA：source/download -> 临时文件 -> archive extraction -> resigned output -> network/device install。
- 元数据：source JSON -> decoder -> Core Data background context -> UI snapshots。
- 敏感数据：用户输入/系统认证 -> memory/Keychain -> Apple request；不进入 source JSON、docs 或普通日志。
- 错误：底层 Error -> ALTServerError/CodableError -> client log/UI。
