# 本地 macOS DMG 验证

本指南用于在不创建 tag、不触发 GitHub Actions、也不接触真实发布凭据的情况下，验证 macOS AltServer 的构建、DMG 打包、挂载和首次启动。它不能替代 Developer ID 签名、Apple notarization 或真实 iPhone/iPad 安装测试。

## 前置条件

- macOS 与 Xcode 26；仓库当前 workflow 使用 Xcode 26.6。
- CocoaPods 1.16.2，并已执行 `pod install --deployment`。
- 完整 submodule：`git submodule update --init --recursive`。
- 构建前确认没有需要保留的 `xcodebuild`，并为 DerivedData 和 DMG 预留足够磁盘空间。

## 一键式本地构建与打包

在仓库根目录运行：

```sh
version="$(tr -d '[:space:]' < VERSION)"
derived_data="${TMPDIR:-/tmp}/AltForge-LocalDMG-DerivedData"

xcodebuild build \
  -workspace AltStore.xcworkspace \
  -scheme AltServer \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$derived_data" \
  MARKETING_VERSION="$version" \
  CURRENT_PROJECT_VERSION=1 \
  ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO

Scripts/package_macos_dmg.sh \
  --app "$derived_data/Build/Products/Release/AltServer.app" \
  --output "build/local/AltForge-AltServer-macOS.dmg" \
  --ad-hoc-sign
```

`--ad-hoc-sign` 只修改 DMG 内的临时副本并密封完整 App bundle，方便当前 Mac 启动和验证登录项；它不提供 Developer ID 身份或 notarization。打包脚本的时间和磁盘成本均与 App bundle 总字节数近似线性，临时 staging 在结束或失败时自动清理。

验证结束后删除本次创建的 DerivedData；不要按进程名称终止其他构建：

```sh
find "${TMPDIR:-/tmp}/AltForge-LocalDMG-DerivedData" -depth -delete
```

## 安装与首次启动

1. 双击 `build/local/AltForge-AltServer-macOS.dmg`，或运行 `open build/local/AltForge-AltServer-macOS.dmg`。
2. 把 `AltForge Server.app` 拖到 DMG 内的 `Applications` 快捷方式。
3. 在 Finder 的 Applications 中找到 AltForge Server，首次启动使用右键菜单中的“打开”。不要全局关闭 Gatekeeper。
4. 如果旧版 `/Applications/AltServer.app` 已存在，先退出正在运行的旧版，再由 Finder 手动移除；不要在测试脚本里静默覆盖用户安装。
5. 启动成功后，AltForge Server 应出现在菜单栏。选择 **检查更新** 应从本仓库 GitHub Releases 检查最新版本，而不是访问上游下载站点。

## 功能验证清单

- DMG 能正常挂载，包含 `AltForge Server.app` 和指向 `/Applications` 的快捷方式。
- `AltForge Server.app` 的 bundle identifier 为 `com.legeling.AltForge.AltServer`，版本与根目录 `VERSION` 一致。
- 菜单栏进程可启动和正常退出，没有重复实例或遗留挂载点。
- 连接并信任 iPhone/iPad 后，**Install AltForge** 能进入设备与 Apple ID 流程。
- 使用脱敏测试账号做真机验证；不得保存 Apple ID、密码、UDID、证书、profile、Cookie 或 anisette data。
- iOS 端安装完成后检查英文与简体中文切换、首次 source 加载、刷新和错误提示。

## 发布前仍需验证

本地构建默认只生成当前 Mac 架构；本地与 tag workflow 都会对 DMG 内的 App bundle 做 deep ad-hoc 完整性签名。tag workflow 生成 `arm64 + x86_64` Universal DMG，但仍没有 Developer ID 身份和 notarization。发布 Draft 前还必须验证 Universal 架构、完整签名密封、`SHA256SUMS.txt`、Windows ZIP、IPA metadata 和一台脱敏真实设备。只有 Draft 人工审核通过后才能公开 Release。

卸载时先从菜单栏退出 AltForge Server，再由 Finder 删除 `/Applications/AltForge Server.app`。如果 DMG 仍已挂载，请在 Finder 中推出，不要强制终止无关磁盘或用户进程。
