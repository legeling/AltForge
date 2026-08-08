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

- CI：`.github/workflows/ci.yml`
- Release：`.github/workflows/release.yml`
- Metadata：`Scripts/generate_release_metadata.rb`
- 预期产物：`AltForge.ipa`、`AltForge-AltServer-macOS.zip`、`apps.json`、`SHA256SUMS.txt`

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
