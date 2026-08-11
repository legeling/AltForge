# CHG-20260811-006：iOS 主题色选择与默认品牌色

## 背景

iOS 客户端的 `Primary`、`SourceTint` 和部分 storyboard 预览值仍固定为旧绿色，用户无法选择自己的强调色。固定颜色还会让设置、导航、官方来源卡片和 Release metadata 形成不同的视觉真相。

## 范围

- 默认主题色改为与 AltForge 图标一致的“锻造红”；页面背景继续使用 UIKit 语义背景色，不把主题色铺满页面。
- 在设置的“显示”分组加入原生主题色选择页，提供锻造红、海洋蓝、靛蓝和玫瑰红色板，并显示当前勾选状态。
- 主题偏好写入应用 `UserDefaults`，未知或旧值稳定回退到锻造红；选择后立即更新窗口、导航栏、标签栏、徽标和当前设置界面，重启后继续生效。
- 官方 AltForge source/app tint 从当前主题动态解析；Release metadata 使用默认锻造红，第三方 source/app 仍保留自己的 tint。
- 新增英文与简体中文文案、偏好 round-trip XCTest 和 repository contract。

## 映射

- Requirement：`FR-037`
- Design：`DES-023`
- Verification：`TEST-036`
- Task：`T-025`

## 复杂度与资源

主题集合固定为 4 个枚举值。读取、写入、颜色解析和窗口更新均为 `O(1)`；色板渲染最多生成 4 个 24 × 24 point 小图，不引入网络、文件缓存、后台进程、端口、依赖或无界状态。变更不修改 Core Data、Server Protocol、签名与安装链路。

## 验证计划

- 解析 Swift、storyboard、string catalog 和颜色 catalog，并运行 repository/release metadata contract。
- XCTest 覆盖默认值、四个主题 round trip 和未知值回退。
- 构建 iOS Simulator target，分别在浅色/深色模式切换四种主题，确认设置色板、勾选、导航、标签栏、官方来源卡片和重启持久化。
- 真机确认颜色选择不会影响安装、来源自定义 tint 或系统可读性；不得用公开 Release 标签代替预发布验证。

## 回滚

移除主题选择 UI 和动态解析后可恢复固定 `Primary`/`SourceTint`。已经保存的字符串偏好对旧构建无副作用；重新启用时未知值仍回退默认色。

## 已执行验证

- 2026-08-11：`ruby Scripts/test_repository_contract.rb`、`ruby Scripts/test_release_metadata.rb` 和 `ruby Scripts/check_release_version.rb --tag v2.4.0` 通过。
- 2026-08-11：受影响 Swift 文件通过 frontend parse；所有 iOS/AltStoreCore string catalog 和颜色 catalog 通过 JSON 解析，Settings/Main/Authentication storyboard 通过 XML 解析，`git diff --check` 通过。
- 2026-08-11：使用隔离的 DerivedData 和复制的 Swift Package cache 完成无签名 `Release-iphoneos` generic device build；产物成功封装为本地 IPA，并通过 ZIP、bundle identifier、版本和 executable 检查。构建发现并修复诊断 journal 对 `JSONDecoder` 的类型歧义。未打开或操作 Simulator。

## 当前状态

Implemented / full iOS Release build passed; light/dark real-device visual matrix pending。
