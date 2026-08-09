<p align="center">
  <img src="../../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Reference Index

## 构建入口

- Workspace：`AltStore.xcworkspace`
- Project：`AltStore.xcodeproj`
- iOS scheme：`AltStore`
- macOS scheme：`AltServer`
- Test target：`AltTests`
- Pod definition：`Podfile`、`Podfile.lock`
- Swift packages：`AltStore.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- Submodules：`.gitmodules`

## 常用命令

```sh
git submodule update --init --recursive
pod install --deployment
xcodebuild -resolvePackageDependencies -workspace AltStore.xcworkspace -scheme AltStore
xcodebuild build -workspace AltStore.xcworkspace -scheme AltStore -configuration Debug -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO
xcodebuild test -workspace AltStore.xcworkspace -scheme AltStore -configuration Debug -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=latest" CODE_SIGNING_ALLOWED=NO
xcodebuild build -workspace AltStore.xcworkspace -scheme AltServer -configuration Debug -destination "generic/platform=macOS" CODE_SIGNING_ALLOWED=NO
```

命令会访问外部 package/CocoaPods 服务。CI 中必须使用 job timeout；本地运行前检查是否已有同类 build process，并使用独立 DerivedData 时在任务后清理。

## 核心协议与模型位置

- Client/server wire contract：`Shared/Server Protocol/ServerProtocol.swift`
- Error serialization：`Shared/Server Protocol/CodableError.swift`
- App orchestration：`AltStore/Managing Apps/AppManager.swift`
- Signing preparation：`AltStore/Operations/FetchProvisioningProfilesOperation.swift`
- AltServer installation：`AltServer/Devices/ALTDeviceManager+Installation.swift`
- Source model：`AltStoreCore/Model/Source.swift`
- Persistence：`AltStoreCore/Model/DatabaseManager.swift`
- Archive handling：`Dependencies/AltSign/AltSign/Categories/NSFileManager+Zip.m`
- Apple App ID creation：`Dependencies/AltSign/AltSign/Apple API/ALTAppleAPI.m`

## 发布参考

- Release：`.github/workflows/release.yml`
- Metadata：`Scripts/generate_release_metadata.rb`
- macOS DMG：`Scripts/package_macos_dmg.sh`
- 本地 macOS 验证：`docs/guides/local-macos-validation.md`
- 预期产物：`AltForge.ipa`、`AltForge-AltServer-macOS.dmg`、`AltForge-AltServer-Windows.zip`、`apps.json`、`flags.json`、`sources.json`、`recommended-sources.json`、`developerdisks.json`、`SHA256SUMS.txt`

## 网络端点所有权

| 能力 | 所有者/入口 | 仓库策略 |
|---|---|---|
| 官方 source、远程配置、Developer Disk 索引 | `https://github.com/legeling/AltForge/releases/latest/download/` | 必须由本仓库 Release 发布并进入 checksum |
| macOS 更新检查 | `https://api.github.com/repos/legeling/AltForge/releases/latest` | 仅检查版本，失败时提供仓库 Releases 手工入口 |
| 支持、隐私、FAQ、Issue | `https://github.com/legeling/AltForge` | 必须指向本仓库内容 |
| Developer Disk 文件 | 索引中经审核的第三方 HTTPS URL | 外部兼容依赖；AltForge 不镜像、不声称所有权 |
| Apple Developer/device 服务 | Apple | 核心外部依赖，不可改写 |
| Patreon API | Patreon | 可选；仅在配置自有 OAuth 凭据和 HTTPS callback 后启用 |
| Marketplace/Fediverse 服务 | 未配置 | Classic 固定关闭；历史实现不属于发布运行时依赖 |
| CocoaPods、SwiftPM、submodule | 各依赖项目 | 保留真实来源和许可证；已有 fork 才切换 |
| AltStore/AltSign 上游文档与版权 | 上游仓库 | provenance，不属于运行时控制端点 |

Classic 发布不得访问 `cdn.altstore.io`、AltStore staging bucket、上游 Marketplace/Fediverse/CloudKit 控制面或 Riley Testut 的 OAuth callback。Marketplace 专用 API 源码当前不进入 Classic 发布契约，不能据此宣称 Marketplace 服务可用；未来启用前必须建立自有兼容服务并重新验证。

## Fixture 约定

长期 fixture 应放入后续建立的 `AltTests/Fixtures/` 或 AltSign test target，并满足：

- 体积最小，不包含第三方真实 IPA 或版权不明资源。
- 不包含真实 Apple ID、UDID、certificate、profile、Cookie 或 token。
- archive fixture 明确记录 raw filename bytes、general-purpose flags、extra fields 和预期 path。
- 如需生成二进制 fixture，优先提交确定性生成脚本和 hash，避免难以审计的黑盒文件。

## 外部参考

- Upstream AltStore：`https://github.com/altstoreio/AltStore`
- AltSign upstream：`https://github.com/rileytestut/AltSign`
- AltForge AltSign fork：`https://github.com/legeling/AltSign`
- GitHub Releases：`https://github.com/legeling/AltForge/releases`
