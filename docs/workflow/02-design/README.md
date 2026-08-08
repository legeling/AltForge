# System Design

## 设计原则

- 保留 AltStore 的客户端/服务器分工：iOS 端负责用户流程和应用状态，macOS 端负责需要桌面环境或设备服务的安装工作。
- 对通用兼容修复优先修改其真实所有者，例如 archive 与签名逻辑属于 AltSign，而不是在 UI 层绕过。
- Shared 中的协议和错误模型是跨进程契约；修改时必须同时验证两端。
- Core Data、Keychain、UserDefaults 和临时文件各有明确边界，禁止用全局缓存复制长期状态。

## 系统边界

```text
GitHub Release / third-party source
               |
               v
       AltForge iOS app
        |  AppManager + Operations
        |  Network.framework / server protocol
        v
       AltServer macOS
        |  AltSign + Apple Developer services
        |  libimobiledevice / device services
        v
       iPhone / iPad
```

## 设计项

### `DES-001` iOS 工作流编排

`AltStore/Managing Apps/AppManager.swift` 组织认证、下载、刷新和安装所需 Operation。Operation 通过显式 dependency 串联，避免 UI 直接访问 Apple API 或设备层。

核心流程由 `DownloadAppOperation`、`ResignAppOperation`、`FindServerOperation`、`SendAppOperation` 和 `InstallAppOperation` 等组成。Operation context 持有单次请求需要的数据，完成后释放临时资源。

### `DES-002` Server discovery 与传输

AltForge 使用 `Network.framework` 和 `Shared/Connections` 发现 AltServer，优先匹配嵌入的 server ID，失败时可选择其他可用服务。`Shared/Server Protocol/ServerProtocol.swift` 定义请求类型、版本和 Codable payload。

IPA 是大对象，传输和落盘应避免重复复制；协议变更必须保持版本兼容或返回明确的 incompatible server 错误。

### `DES-003` AltServer 安装职责

`AltServer/Devices/ALTDeviceManager+Installation.swift` 负责：

1. 获取 anisette data 并认证 Apple ID。
2. 选择开发团队、注册设备和获取证书。
3. 下载或读取 IPA，解压应用 bundle。
4. 为主应用和 extensions 注册 App ID、更新 capabilities、获取 profiles。
5. 使用 AltSign 重签并通过设备服务安装。
6. 把结构化错误返回客户端或 macOS UI。

团队选择在客户端认证和 AltServer 安装两条路径中保持一致：先匹配已保存的 team identifier；没有匹配时依次选择个人、组织、免费团队。团队列表规模很小，现有实现最多进行三次线性扫描，时间复杂度仍为 `O(n)`，不引入额外缓存或跨账户状态。

外部调用必须有失败出口；下载文件、解压目录、证书和连接必须按单次任务生命周期释放。

### `DES-004` 数据边界

- Core Data：source、store app、installed app、App ID、team、refresh attempt、logged error 等长期关系数据。
- Keychain：账户、证书或其他敏感值；不得迁移到普通 plist、日志或 source JSON。
- UserDefaults：非敏感偏好与轻量状态。
- 临时目录：下载 IPA、解压 bundle、重签输出；成功或失败后清理。
- App Group：AltForge、Widget 与 AltBackup 之间的受控共享数据。

### `DES-005` Unicode IPA 兼容

Unicode 处理分两层：

- Apple App ID description：只发送 ASCII 字母、数字和普通空格，trim 后为空则使用 `App`；这不修改 `CFBundleDisplayName`。
- ZIP entry：优先读取 UTF-8 flag，再验证 Info-ZIP Unicode Path extra field；对没有正确标志的历史包，使用无损的 GB18030/GBK、Big5、Shift-JIS、EUC-KR 和 DOS fallback。输出 ZIP 一律写 UTF-8 filename flag。

每个 entry 的 filename 与 extra field 按 ZIP 字段上限分配，处理复杂度为 `O(entries + filename bytes)`，不建立随 archive 无界增长的缓存。解压前拒绝绝对路径和 `..` component。

### `DES-006` 本地化

项目继续使用 Xcode string catalog、storyboard localization 和 `NSLocalizedString`。简体中文资源与英文源文案共用现有 key；代码中的品牌字符串和 bundle/source identity 通过 `Bundle`、常量或 model 统一提供，避免散落硬编码。

### `DES-007` Source 与更新

`AltStoreCore/Model/Source.swift` 负责 source URL 和稳定 source ID；query、fragment、scheme、大小写和多余斜杠不应制造重复 source。官方 source 指向 GitHub Release 的 `apps.json`。

### `DES-008` 错误模型

本地 Error 通过 `ALTLocalizedError`、`ALTServerError` 和 `CodableError` 传输。序列化必须保留 domain/code/failure/recovery suggestion，并移除不能安全编码的对象。日志使用 OSLog privacy 标记，敏感字段不得标记为 public。

### `DES-009` 构建依赖

- Workspace：`AltStore.xcworkspace`
- CocoaPods：Sparkle、STPrivilegedTask，使用 `Podfile.lock`
- Swift packages：KeychainAccess、LaunchAtLogin、Nuke、swift-argument-parser、TelemetryDeck，使用 workspace `Package.resolved`
- Submodules：AltSign、Roxas、libimobiledevice、libplist、libusbmuxd、MarkdownAttributedString

构建必须使用递归 submodule，并对网络依赖设置 CI timeout。AltSign 通用修复保存在 `legeling/AltSign` fork；同步上游时需要同时更新 nested commit 与 superproject gitlink。

Classic 版本必须使用未定义 `MARKETPLACE` 且包含 Apple 认证所需 crypto 实现的 AltSign 基线。迁移 AltSign 时先在 fork 分支提交并推送，再更新 superproject gitlink；不得以 dirty submodule 交付。

### `DES-010` 发布流水线

`v*` 标签触发 release workflow：校验语义版本、构建 unsigned iOS app、打包 IPA、构建 universal macOS app、生成 source/checksum、发布 GitHub Release。产物先写入 runner 临时目录，不回写仓库。

## 可选目标与边界

| Target | 责任 | 核心安装依赖 |
|---|---|---|
| AltWidgetExtension | 展示 installed app / expiration snapshot | 否 |
| AltBackup | 备份与恢复 app container/app group 数据 | 否 |
| AltJIT | macOS CLI，准备 developer disk 并启用 JIT | 可选 |
| AltDaemon / AltXPC / AltPlugin | 辅助进程与历史 macOS 集成 | 按构建配置 |
| AltMarketplace | MarketplaceKit extension | 当前 Classic 发布不嵌入 |

## 失败链路

- Source 下载失败：保留原 source，记录可恢复错误，不写入半解析数据。
- Apple 认证或 App ID 失败：停止签名，不生成部分安装成功状态。
- Archive 解码或路径校验失败：关闭 archive/file handle，删除临时输出，返回 file error。
- 设备断连：终止当前请求，保留可用于诊断的结构化错误，不无界重试。
- Release 任一步失败：不创建不完整 GitHub Release；校验和只基于已存在产物生成。

## 方案取舍

| 方案 | 优点 | 代价 | 决策 |
|---|---|---|---|
| 直接等待上游修复 | 同步成本低 | 长期 Issue 无法及时解决 | 不采用为唯一策略 |
| 在 AltForge UI 层改名/重打包 | 改动快 | 破坏显示名，绕过真实所有者 | 不采用 |
| 在 AltSign 修复 App ID 与 ZIP 兼容 | 两端复用、可回馈上游 | 需要维护 submodule fork | 当前采用，见 `ADR-20260808-001` |

## 待确认

- `[待确认]` 是否将整个项目迁移到 Swift 6 language mode；当前 build setting 仍为 Swift 5.0。
- `[待确认]` 是否为 release 增加 Developer ID 签名、notarization 和 Sparkle feed。
- `[待确认]` 是否为 installation protocol 建立独立版本兼容矩阵。
