# Requirements

## 用户角色

| 角色 | 主要目标 |
|---|---|
| 最终用户 | 安装、刷新、更新和管理侧载应用，获得可理解的错误信息 |
| 国际用户 | 使用本地化界面并安装包含 Unicode 元数据与资源路径的 IPA |
| 贡献者 | 在不破坏上游结构的情况下实现修复并验证影响范围 |
| 发布维护者 | 生成可追溯、可校验、可供 AltServer 使用的发布产物 |

## 功能需求

### 安装与签名

- `FR-001` 用户必须能通过 macOS AltServer 将 AltForge 安装到受支持的 iOS/iPadOS 设备。
- `FR-002` 用户必须能在 AltForge 中选择或下载 IPA，并通过可用 AltServer 完成认证、App ID 注册、provisioning、重签和设备安装。
- `FR-003` 安装链路必须保留应用 bundle identifier、权限、extension 和版本约束所需的信息，并对不兼容或无效包返回明确错误。
- `FR-004` App ID 注册名称必须满足 Apple 服务的 ASCII 限制，但不得因此修改设备桌面上的 Unicode 显示名。
- `FR-017` 认证返回多个开发团队时，有已保存团队信息的客户端流程必须优先复用；其余情况按个人、组织、免费团队的顺序选择，不能因只有组织团队而中止安装。

### Unicode 与本地化

- `FR-005` 解压和重建 IPA 时必须正确处理标准 UTF-8 ZIP 文件名、Info-ZIP Unicode Path 字段以及常见的旧式东亚编码文件名。
- `FR-006` 简体中文必须可作为应用语言使用，并兼容 iOS per-app language switching。
- `FR-007` 用户可见的新增文本必须进入项目既有的 string catalog 或本地化资源，不得在业务代码中另建第二套本地化机制。

### 刷新、来源与更新

- `FR-008` AltForge 必须跟踪已安装应用与签名到期信息，并在用户触发或系统允许时刷新活动应用。
- `FR-009` 用户必须能添加、读取和更新兼容的 AltStore source，并按稳定 source ID 去重。
- `FR-010` 官方 AltForge source 必须指向本仓库 GitHub Release 的 `apps.json` 与 IPA。

### 诊断与可选能力

- `FR-011` 客户端与 AltServer 间的失败必须保留错误域、错误码、失败原因和可用恢复建议，同时清理不可序列化或敏感字段。
- `FR-012` 在受支持系统和设备上，用户可请求为侧载应用启用 JIT；不满足前置条件时必须返回明确错误。
- `FR-013` 备份、Widget、Daemon、XPC、Plugin 和 Marketplace 目标必须保持其既有模块边界，不得成为核心安装链路的隐式依赖。

### 构建与发布

- `FR-014` 维护者必须能从递归 submodule、CocoaPods lockfile 和 Swift package resolution 构建 iOS 与 macOS 目标。
- `FR-015` 版本标签必须生成 `AltForge.ipa`、`AltForge-AltServer-macOS.zip`、`AltForge-AltServer-Windows.zip`、`apps.json` 和 `SHA256SUMS.txt`。
- `FR-016` 发布 source 的版本、build、最低系统、下载 URL、大小和 SHA-256 必须与实际 IPA 一致。
- `FR-018` 维护者必须能从同一仓库内的固定上游源码和固定依赖构建 Windows AltServer；Windows 服务必须从本仓库官方 source 下载 `com.legeling.AltForge`。
- `FR-019` Windows Release ZIP 必须包含可执行文件及其运行时 DLL，且不得包含 Apple ID、证书、anisette data、设备标识或 Apple 软件安装包。

## 非功能需求

- `NFR-001 Correctness`：兼容性修复不得破坏签名内容、entitlement、provisioning profile 或安装原子性。
- `NFR-002 Security`：Apple ID、密码、证书、private key、anisette data、Cookie、设备 UDID 和生产凭据不得写入仓库、普通日志或发布产物。
- `NFR-003 Compatibility`：当前基线为 iOS 17.4、macOS 11、Windows 10；AltJIT 为 macOS 13。目标变化必须同步 README、build settings、source metadata 和验证矩阵。
- `NFR-004 Performance`：IPA 解压与重建的时间复杂度应为 `O(entries + bytes)`；文件名解码使用单 entry 有界缓冲，不保留整个 archive 的文件名列表。
- `NFR-005 Resource control`：网络请求、CI job、设备操作和并发任务必须有超时或上限；临时下载、解压目录和构建产物必须清理。
- `NFR-006 Maintainability`：优先复用现有 Operation、AltStoreCore model、Shared protocol、AltSign 和 libimobiledevice，不建立重复体系。
- `NFR-007 Upstreamability`：通用修复应与品牌改动分离，便于向 altstoreio/AltStore 或 rileytestut/AltSign 回馈。

## 验收标准

- `AC-001` 给定纯中文 `CFBundleDisplayName`，Apple App ID 注册使用合法 ASCII fallback，安装后的显示名仍为原中文名称。覆盖 `FR-004`。
- `AC-002` 给定包含 `Payload/Test.app/音乐.png` 的 IPA，解压后路径和内容保持一致，重新打包后的 ZIP entry 设置 UTF-8 标志。覆盖 `FR-005`。
- `AC-003` 给定不可解析或路径穿越 ZIP entry，系统拒绝安装并释放 archive/file handle。覆盖 `FR-003`、`NFR-002`。
- `AC-004` 官方 source URL 的 source ID 为 `github.com/legeling/altforge/releases/latest/download/apps.json`。覆盖 `FR-009`、`FR-010`。
- `AC-005` CI 在无代码签名条件下完成 iOS Simulator 与 macOS AltServer 构建，并运行 source identity 测试。覆盖 `FR-014`。
- `AC-006` 语义版本标签生成五类预期产物，校验和与文件内容一致。覆盖 `FR-015`、`FR-016`、`FR-019`。
- `AC-007` 错误经过 client/server 序列化后仍保留语义字段且不包含不可安全传输的对象。覆盖 `FR-011`。
- `AC-008` 新增简体中文文本在系统语言和 per-app language 切换后可正确显示。覆盖 `FR-006`、`FR-007`。
- `AC-009` 给定仅有组织团队的 Apple Developer 账户，客户端和 AltServer 均选择该团队；客户端有已保存团队时仍优先复用。覆盖 `FR-017`。
- `AC-010` Windows CI 在 60 分钟上限内恢复六个固定源码仓库和固定 vcpkg manifest，完成 Win32 Release build，并生成通过必需 DLL 检查的 ZIP。覆盖 `FR-018`、`FR-019`。

## 范围外

- 已签名的 Windows MSI/MSIX、自动更新 feed 和 Apple 软件再分发。
- 绕过 Apple 的账号限制或长期签名机制。
- 在没有凭据方案前承诺 macOS 公证和自动更新渠道。
- 对所有历史编码进行无歧义猜测；旧式无编码标志 ZIP 只能提供受控兼容 fallback。

## 追踪摘要

| Requirement | Design | Verification | Task |
|---|---|---|---|
| `FR-001`, `FR-002`, `FR-003`, `FR-017` | `DES-001`, `DES-002`, `DES-003` | `TEST-001`, `TEST-002`, `TEST-004`, `TEST-016` | `T-003`, `T-010` |
| `FR-004`, `FR-005` | `DES-005` | `TEST-003`, `TEST-005`, `TEST-006`, `TEST-007` | `T-001` |
| `FR-006`, `FR-007` | `DES-006` | `TEST-008` | `T-004` |
| `FR-008` | `DES-001`, `DES-002`, `DES-003` | `TEST-015` | `T-008` |
| `FR-009`, `FR-010` | `DES-007` | `TEST-009` | `T-005` |
| `FR-011` | `DES-008` | `TEST-010` | `T-006` |
| `FR-012` | `DES-003` | `TEST-014` | `T-009` |
| `FR-013` | `DES-004`, `DES-009` | `TEST-011`, `TEST-012` | `T-002` |
| `FR-014` | `DES-009` | `TEST-011`, `TEST-012` | `T-002` |
| `FR-015`, `FR-016` | `DES-010` | `TEST-013` | `T-007` |
| `FR-018`, `FR-019` | `DES-011` | `TEST-018`, `TEST-019` | `T-012` |
