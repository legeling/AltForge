# CHG-20260809-006：macOS DMG 与本地安装验证

- 状态：Completed
- 日期：2026-08-09
- 类型：Release / Packaging / Documentation

## 背景

现有 tag workflow 只发布 `AltServer.app` ZIP，无法提供用户熟悉的 DMG 拖拽安装流程，也没有从本地 Release build 到首次启动的可重复验证说明。维护者希望在不创建公开 tag 的前提下先在当前 Mac 试装。

## 范围

- 建立 CI 与本地共用的 DMG 打包脚本，包含 Applications 快捷方式与 image verify。
- 将 macOS Release asset、metadata contract、checksum 和文档从 ZIP 统一为 DMG。
- 支持只对 staging 副本执行本地 ad-hoc 签名，不修改 Xcode 输出。
- 补充构建、安装、首次启动、真机 smoke 和清理步骤。
- 本机生成并挂载验证当前架构 DMG，保留一个供用户试装的忽略产物。

## 非范围

- Developer ID 证书、hardened runtime、notarization、Sparkle 自动更新。
- 自动覆盖 `/Applications/AltServer.app` 或启动/停止用户已有 AltServer。
- 以本机 ad-hoc 结果替代 Universal CI、另一台 Mac Gatekeeper 或真实 iOS 设备验证。

## 追踪

- Requirement：`FR-025`、`AC-016`
- Design：`DES-013`
- Verification：`TEST-025`、Regression Suite G
- Task：`T-015`

## 复杂度与资源

打包需要读取和复制一次 App bundle，再写入一次压缩映像，时间与 I/O 为 `O(app bytes)`；峰值磁盘约为 App、staging 副本、DerivedData 和 DMG 之和。脚本不启动常驻进程，使用任务专属临时目录并以 trap 清理。

## 回滚

删除 DMG 脚本并把 workflow、metadata contract 和文档资产名恢复为 ZIP 即可；不得删除或替换已公开 Release 的同名资产。当前 change 不修改用户已安装应用和数据。

## 验证计划

- `bash -n Scripts/package_macos_dmg.sh`
- Ruby release metadata 与 repository policy contracts
- macOS AltServer Release build
- DMG 创建、`hdiutil verify`、只读挂载、Applications symlink、bundle identifier、版本、架构和 ad-hoc signature 验证
- 验证后推出挂载并清理 DerivedData；只保留用户明确需要试装的 DMG

## 当前验证结果

- Xcode 26.6 在 Apple Silicon 上完成 AltServer arm64 Release build，版本 `2.4.0 (1)`。
- 本地 staging 副本完成 ad-hoc deep sign 与 strict verification。
- 生成的 DMG 通过 `hdiutil verify`；只读挂载后确认存在 `AltServer.app` 与 `/Applications` symlink。
- bundle identifier 为 `com.legeling.AltForge.AltServer`，主 executable 为 arm64，版本为 `2.4.0 (1)`。
- 验证挂载已推出，DerivedData 与 staging 已清理；只保留 `build/local/AltForge-AltServer-macOS.dmg` 供用户试装。
- 桌面身份与设置改进后的 preview 重新构建为 `AltForge Server.app`，版本 `2.4.0 (3)`；DMG 再次通过 image、symlink、bundle、arm64/x86_64 和 strict ad-hoc signature 检查。
- 正式 `v2.4.0 (8)` Universal DMG 由 GitHub macOS runner 产出，artifact verifier 和发布后独立下载复验均通过。

## 残余风险

- 公开产物仍未 Developer ID 签名和 notarize，Gatekeeper 体验不能由本地 ad-hoc build 代表。
- 真实 iPhone/iPad 安装仍需要脱敏 Apple ID 和设备 smoke test。
