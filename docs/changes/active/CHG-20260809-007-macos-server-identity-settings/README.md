# CHG-20260809-007：macOS Server 身份、菜单与设置

- 状态：Implemented（实机/UI smoke 待执行）
- 日期：2026-08-09
- 类型：Product identity / UX / Localization / Maintenance

## 背景

本地 DMG 试装发现 About、菜单和错误仍把桌面端显示为上游 AltServer，版权只显示原作者，设备子菜单不显示 USB/Wi-Fi 连接方式，“View Releases”也没有执行版本比较。桌面端虽然已有英文与简体中文资源，但缺少可发现的设置入口和语言选择。

## 范围

- 对外统一使用 `AltForge Server`；保留内部 target、executable、协议、历史数据目录与兼容通知中的 `AltServer`。
- About 显示 AltForge contributors、AltStore/pymobiledevice3 communities、上游版权与 AGPL v3.0，不突出个人感谢。
- 设备菜单显示名称、USB/Wi-Fi 标签和对应系统图标；USB 与 Wi-Fi 同时可用时优先显示 USB。
- 实现有 10 秒超时、无重试的 GitHub Latest Release 检查；只比较版本并打开经过 HTTPS/host 校验的 Release 页面，不自动替换 App。
- 把旧邮件插件入口改成仅在检测到遗留插件时出现的明确清理操作。
- 增加原生设置窗口，提供跟随系统、English、简体中文和登录时启动；语言切换写入 App 自有偏好并在重启后生效。
- 明确验证 App 图标和菜单栏 template 图标资源。
- 同步审计 Windows 对外名称、版权、更新菜单和设备连接标签，避免同一 Release 中出现 `AltForge AltServer`/`View Releases` 等旧文案。

## 非范围

- 重命名 Xcode target、Mach-O executable、Bonjour/安装协议、旧数据目录或兼容通知。
- Sparkle 自动下载/安装、Developer ID 签名和 notarization。
- 把非英语/简体中文的历史翻译批量机器改写。

## 追踪

- Requirement：`FR-026`、`FR-027`、`AC-017`
- Design：`DES-014`
- Verification：`TEST-026`
- Task：`T-016`

## 性能与失败行为

设备连接标签从一次有界 USB identifier 集合生成，菜单刷新为 `O(devices)` 时间与空间，不对每个菜单项重复扫描设备。检查更新只发出一个 GitHub API 请求，10 秒超时、零重试；网络、HTTP、JSON 或 URL 校验失败时提供明确的手工 Releases 入口。

## 回滚

恢复 About/menu/settings 和本地化资源即可；内部协议与数据标识未变，不需要迁移。语言偏好可在设置中切回跟随系统，或删除 App 偏好后恢复默认。

## 验证计划

- JSON/XML/PBX/Swift parse 与 repository contract。
- AltServer arm64 Release build；检查 Info.plist、string catalogs、App/menu icon 和 DMG bundle 名称。
- 无设备、USB、Wi-Fi、USB+Wi-Fi 菜单矩阵。
- 跟随系统、English、简体中文重启矩阵。
- 更新可用、已最新、404/离线、恶意/无效 Release URL 失败矩阵。
- About、设置窗口和菜单截图检查。

## 当前验证结果

- repository/version/release metadata contracts、JSON/XML/PBX/Swift parse 与 `git diff --check` 通过。
- Xcode 26.6 完成 AltServer Universal Release build 和 AltStore iOS Simulator Debug build。
- 本地 `2.4.0 (3)` preview DMG 通过 `hdiutil verify`、只读挂载、Applications symlink、arm64/x86_64 架构和 ad-hoc deep/strict signature 检查。
- 挂载后的 bundle 对外名称为 `AltForge Server`，英文与简体中文资源均存在；版权同时保留 AltForge contributors 与 AltStore/AltServer 上游归属。
- App 图标各槽位尺寸、菜单栏 19/38 px template 图标、USB/Wi-Fi 标签、设置入口和更新 URL 防护已由 repository contract 覆盖。
- Windows 静态 contract 确认产品名为 `AltForge Server`、保留上游版权、更新菜单使用 `Check for Updates...`，并在设备名后标注 USB/Wi-Fi；Windows hosted build 仍由下一次 Draft Release 验证。
- 未启动 preview App，避免与用户当前运行的同 bundle identifier 旧版冲突；真实菜单、语言重启和设备连接状态保留为手工 smoke test。

## 残余风险

- 当前开发机没有可自动化使用的脱敏 iOS 设备，USB/Wi-Fi 实机菜单状态仍需用户复测。
- 首个公开 Release 前 latest endpoint 会返回 404，应显示可恢复错误而不是伪造“已最新”。
- Developer ID 与 notarization 仍由独立 issue 跟踪。
