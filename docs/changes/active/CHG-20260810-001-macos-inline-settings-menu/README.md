# CHG-20260810-001：macOS 菜单内联设置与安装图标修复

- 状态：In progress（登录启动与语言重启实机 smoke 进行中）
- 日期：2026-08-10
- 类型：UX / Bugfix / Localization

## 背景

实际试用发现，状态菜单中的“设置…”会再打开一个独立窗口，而窗口内的“登录时启动”又与状态菜单已有选项重复。内联后继续实机检查发现，旧版 `LaunchAtLogin` API 在未完整签名的开发构建中会静默注册失败，菜单重新读取后始终显示关闭；语言偏好虽然已保存，但只有重启后生效且 UI 没有提示。Install AltForge、Sideload IPA 和 Enable JIT 的设备子菜单还被错误声明为 macOS Recent Documents 系统菜单，导致系统在命令前显示与安装无关的时钟图标。

## 范围

- 将“设置…”改为无省略号的 `Settings` 子菜单，不再打开独立窗口。
- 把“登录时启动”及跟随系统、English、简体中文语言选择全部放入设置子菜单；登录启动使用系统勾选状态并在标题中明确显示“已开启/已关闭/需要批准”。
- macOS 13+ 使用官方 `SMAppService.mainApp` 注册并读取真实状态；macOS 11/12 保留现有 `LaunchAtLogin` fallback。注册失败必须弹出可恢复错误，需要批准时可直接打开系统登录项设置。
- tag workflow 对 DMG staging App 执行 deep ad-hoc 完整性签名并严格验证嵌套 bundle，使当前无 Developer ID 的发行阶段不再交付无法注册登录项的 linker-only signature；文档继续明确其不代表可信发行身份。
- 语言选择写盘后弹出“立即重启/稍后”提示；立即重启使用单个 0.5 秒延迟的短生命周期 relauncher，先退出旧进程再打开同一 App bundle，避免偏好仍在异步缓存中时退出导致选择丢失。
- 保留原有 `AltForgePreferredLanguage` 与 `AppleLanguages` 偏好格式，语言在下一次启动生效。
- 移除三个设备子菜单的 `recentDocuments` 类型；Install AltForge 使用 `arrow.down.app` template SF Symbol，并以 `square.and.arrow.down` 作为兼容 fallback。
- 为 `Settings` 和 `Check for Updates` 补充 template SF Symbol，分别使用齿轮与刷新图标，保持状态菜单命令的左侧视觉节奏一致。
- 删除不再参与构建的设置窗口控制器及其专用本地化文案。

## 非范围

- 不改变设备发现、签名、安装、JIT、更新检查和桌面协议。
- 不实现运行中热切换语言，也不更改 Windows 通知区域菜单。

## 追踪

- Requirement：`FR-027`
- Design：`DES-014`
- Verification：`TEST-026`、Suite H
- Task：`T-016`

## 性能与失败行为

菜单每次打开只读取一次登录启动状态和一个语言偏好，并更新固定数量菜单项，时间和空间均为 `O(1)`。没有新增网络或长期资源。只有用户确认立即重启时才创建一个有界、0.5 秒后退出的 relauncher；未知语言偏好回退到跟随系统，系统不支持首选安装符号时使用兼容符号。

## 验证计划

- JSON、storyboard XML、PBX project 和 Swift 编译检查。
- repository contract 检查设置窗口已移除、语言偏好仍可持久化并提供重启反馈、登录启动使用现代 ServiceManagement 状态与双语错误/批准文案、设备子菜单不再使用 Recent Documents，以及安装、设置、检查更新入口存在对应图标。
- AltServer Debug build。
- 手工确认设置子菜单层级、登录启动的对勾与三态标题、失败/批准恢复入口、语言重启流程、安装图标和重启后的中英文菜单。

## 当前验证结果

- repository contract 通过，已覆盖 `SMAppService` register/unregister/approval、语言 relauncher 及相关简体中文文案。
- storyboard 通过 `xmllint` 与 `ibtool` 解析；两份 string catalog 通过 JSON 解析，PBX project 通过 `plutil`。
- AltServer macOS Debug build 通过；现有上游 Sendable/deprecation 和缺失旧 Carthage 搜索目录 warnings 不属于本次改动。
- arm64 Debug App 已完成 deep ad-hoc 本地签名并启动供当前手工 smoke；语言立即重启前显式写盘的修复已重新构建，重启后的中英文菜单仍待当前实例确认。
- 本地临时 DMG 使用 release 同一路径完成生成、校验、只读挂载与 `codesign --verify --deep --strict`，随后已推出并清理；真实登录后自动启动仍待安装包 smoke。

## 回滚

恢复 `SettingsWindowController.swift`、PBX 引用和原 storyboard action 即可。偏好键与值未迁移，回滚不会丢失用户已经选择的语言或登录启动设置。

## 残余风险

- 菜单层级和 SF Symbol 的实际视觉效果仍需在构建后的 App 中手工确认。
- `SMAppService` 要求 App bundle 具有完整代码签名；当前 deep ad-hoc 只用于本机 smoke，不能替代 Developer ID、notarization 和另一台 Mac 的登录验证。
- 语言资源不会在当前进程热切换，用户仍需退出并重新打开 App；该行为与现有偏好契约一致。
