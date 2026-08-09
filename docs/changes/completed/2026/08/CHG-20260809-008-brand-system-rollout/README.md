# CHG-20260809-008：统一品牌系统全面替换

## 背景

默认平台图标已经切换到 AltForge，但仓库仍包含可被打包或展示的上游 AltStore 主题图标，多个文档入口也没有统一品牌头图。本变更将已确认的 AltForge `A` 图形扩展到完整的可选图标、平台资源和长期 README 入口。

## 范围

- 保留已确认的 AltForge 默认图标和完整字标。
- 增加基于同一几何结构的 AltForge Coral 可选图标。
- 移除不再对外提供的 Classic、Gradient、Modern、Promo 和 Recessed 上游主题目录及预览。
- 收敛 iOS alternate icon 声明、预览和 Icon Composer 资源。
- 为根目录、Windows、Release 和 `docs/` 下长期 README 索引统一品牌头图；历史 change 记录保持不可变。
- 扩展可重复运行的跨平台品牌资源生成脚本。

## 追踪

| 类型 | ID | 内容 |
|---|---|---|
| Requirement | `FR-BRAND-003` | 所有可选和默认产品图标必须使用 AltForge 品牌，不得打包上游主题图标。 |
| Requirement | `FR-BRAND-004` | 所有长期 README 入口必须使用统一 AltForge 字标。 |
| Design | `DES-BRAND-002` | 品牌源图集中存放，平台尺寸和容器由有界脚本生成。 |
| Test | `TEST-BRAND-002` | 校验图标清单、manifest、尺寸、README 链接及受影响 Apple 构建。 |

## 复杂度与资源

图标生成只遍历固定输出清单，时间与空间复杂度为 `O(total output pixels)`。没有无界并发、缓存或后台服务；Image Gen 只用于生成单个 Coral 源图，其余平台输出使用本地固定尺寸生成。

## 实施

- iOS 默认与 Coral alternate icon 使用项目自有 PNG 和单层 Icon Composer 配置。
- iOS icon picker 只展示 AltForge 与 AltForge Coral，不再暴露上游主题分类或促销图标。
- Widget fallback、锁屏小组件名称和描述使用 AltForge identity。
- `Scripts/generate_brand_assets.rb` 同时生成 iOS、macOS、Windows、Widget 和预览资源。
- 24 个长期 README 入口使用统一字标；历史 change 内容不因品牌迭代被改写。

## 验证

- 品牌生成器、Ruby syntax、受影响 JSON 与 Plist 解析、PNG 尺寸/alpha 和 Widget fallback 尺寸检查通过。
- 仓库静态检查确认 Classic、Gradient、Modern、Promo、Recessed、Japan 和 Brazil 上游图标目录及引用均已移除。
- 24 个长期 README 的品牌头图和相对图片路径检查通过；根中英文、Windows 和 docs 入口通过 GitHub Markdown API 渲染。
- iOS `AltStore` generic Simulator build 在关闭签名后通过，包含 alternate icon、Widget 和 asset catalog 编译。
- macOS AppIcon/MenuBar asset catalog 通过独立 `actool` 编译。完整 `AltServer` build 已执行，但被本任务之外的 `SettingsWindowController.swift:81` private type 可见性错误阻断。
- Windows MSBuild 与 Apple/Windows 真实设备显示未在当前 macOS 环境执行。

## 残余风险

- Coral alternate icon 尚未在真实设备的系统 mask、dark/tinted appearance 和最小图标尺寸下人工检查。
- macOS 完整构建需在并行的 Server identity/settings 改动修复编译错误后重新执行。
- Windows ICO 仍沿用已验证的默认 AltForge master，本轮没有 Windows runner 或通知区域实机截图。

## 回滚

本变更不修改 schema、协议、identifier 或用户数据。回滚时恢复图标 catalog、plist 声明、README 头图和生成器即可。
