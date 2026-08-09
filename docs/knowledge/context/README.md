<p align="center">
  <img src="../../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Project Context

## 项目身份

AltForge 是 `altstoreio/AltStore` 的 AGPL-3.0 派生项目，当前主线是 AltStore Classic 形态。项目保留上游历史目录和 target 名称，因此代码中仍大量使用 `AltStore`、`AltServer`、`ALT*` 命名；对外产品名、bundle identifier 和官方 source 则使用 AltForge。

## 角色

- **设备用户**：在 iOS/iPadOS 上运行 AltForge，管理侧载应用。
- **AltServer 用户**：在 macOS 上运行 AltServer，并提供 Apple ID 与设备连接。
- **贡献者**：修改 app、server、core、shared 或 submodule，并维护追踪文档。
- **发布维护者**：创建版本标签、检查 CI/Release、验证下载产物。
- **上游维护者**：AltStore/AltSign 的外部项目维护者；AltForge 应尽量提交可复用修复。

## 核心术语

| 术语 | 含义 |
|---|---|
| IPA | 包含 `Payload/<App>.app` 的 iOS 应用 archive |
| Resign | 使用当前开发团队证书和 provisioning profile 重签应用及 extensions |
| Refresh | 在签名到期前重新完成 provisioning、签名和安装 |
| App ID | Apple Developer 服务中的 bundle identifier 注册对象，不等同于桌面显示名 |
| Anisette data | Apple 认证流程需要的设备/客户端上下文，按敏感数据处理 |
| Source | AltStore JSON feed，描述 app、version、download URL、权限和元数据 |
| Source ID | 对 source URL 规范化后的稳定标识，用于去重和关联 |
| Active app | 当前占用免费开发账户活动应用槽位、需要定期刷新的应用 |
| AltSign | 签名、Apple Developer API、application model 与 ZIP 处理 submodule |
| Classic | 通过 AltServer 和 Apple ID 侧载的 AltStore 形态，不是 Marketplace/PAL 分发 |

## 核心实体

- `Source`：source URL、identifier、name 与 apps 集合。
- `StoreApp` / `AppVersion`：可发现应用与版本元数据。
- `InstalledApp` / `InstalledExtension`：设备已安装状态、版本、到期信息和关系。
- `Team` / `AppID`：Apple Developer team 与已注册 identifiers。
- `RefreshAttempt`：刷新结果与诊断历史。
- `ALTApplication`：从 `.app` bundle 读取 name、bundle ID、version、entitlements、extensions 的 AltSign model。
- `ServerRequest`：iOS 与 AltServer 之间的 install、refresh、anisette、JIT 等请求。

## 长期边界

- AltForge 不替用户持有云端 Apple ID 服务；认证发生在现有 Apple/AltServer 流程中。
- AltForge 不承诺任何 IPA 的合法来源，用户与发布者负责分发权限。
- 项目兼容修复不得降低 entitlement、source permission 或签名完整性校验。
- GitHub Release 是官方二进制与 source metadata 的发布点，但不是设备签名服务。

## 品牌与兼容约定

- 对外文案使用 `AltForge`。
- 根目录 `README.md` 为英文入口，`README.zh-CN.md` 为简体中文入口；两份文档互相提供语言切换，并同步维护相同的项目事实、限制和操作流程。
- 代码类型和历史文件名在没有必要时保留 `AltStore`/`ALT`，避免大规模上游冲突。
- 官方 bundle identifier 使用 `com.legeling.AltForge` 系列。
- 官方 source URL 使用 `https://github.com/legeling/AltForge/releases/latest/download/apps.json`。
- 通用 submodule 修复保存在 `legeling/AltSign`，并保留 `rileytestut/AltSign` 为 upstream remote。
