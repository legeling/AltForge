# CHG-20260924-001 跨端 IPA 安装选项与自定义图标

- 状态：实现完成；2.6.0 发布中，真机验收转 `ISSUE-20260923-001` 跟踪
- 类型：功能 / iOS 与 macOS UX
- 日期：2026-09-24

## 背景与范围

“安装 IPA”菜单此前被设为 Option alternate，正常菜单中不可见。用户希望它与“安装 AltForge”并列，选择 IPA 后可核对名称、包标识符、版本、扩展及图标，再选择原样安装或编辑名称、包标识符及可选图标安装。

`FR-049 -> DES-034 -> TEST-048 -> T-047`。macOS Server 增加独立 IPA 入口、身份编辑和图片裁切；iOS 导入 IPA 时也能从照片选取、裁切图标并与名称、包标识符一起提交。两端复用相同的临时 App 图标写入器与既有签名安装链。不改跨端协议、数据库或 Windows 服务。

## 验证与风险

- 自动化：菜单不再依赖 Option；本地解包仅一次且编辑在 provisioning 前；Swift/Xcode macOS 构建及本地化目录检查。
- 真机：原样安装、修改名称、修改包标识符多开、失败及取消后的清理与设备显示仍待验收。
- IPA 来源不可信，沿用现有 AltSign ZIP 路径校验；修改包标识符可能影响第三方 App 登录、共享数据和通知。临时副本只在本次安装生命周期保留；源 IPA 不变。
- 图标预览只承诺可读取的包内独立 PNG/JPEG；无法解析仅存于 `Assets.car` 的图标时使用通用占位图。macOS 自选图标接受宽、高均为 180–4096 像素、文件不超过 20 MiB 的 PNG/JPEG，允许非正方形图片拖动、缩放并裁成方形；iOS 使用系统照片选择器内置的方形裁切，统一转为 PNG。临时主 App 写入 1024、120、180、152 像素图标文件及 iPhone/iPad primary icon 引用；真实主屏幕显示需设备验证。
- 回滚：恢复旧菜单行为和安装器直接解包路径，无持久数据迁移。

## 本地结果（2026-09-24）

macOS 图标 fixture 已覆盖非正方形裁切/缩放、方形输出、四种图标尺寸、元数据与临时目录边界；macOS Debug build、共享编辑器的 iOS SDK 类型检查、Swift 语法、版本契约、仓库契约、发布隐私测试、本地化 JSON 和 plist 检查通过。本机未安装 iOS 26.5 平台，无法在本机运行 iOS target build / 模拟器测试；下方 hosted 预检已补足。真机上的裁切 UI、主屏幕图标、双开、刷新与后台安装仍需用户验收。没有使用真实 Apple ID、证书或设备执行签名安装。

提交 `70215e5f` 的手动 Release 预检 [run 35985608497](https://github.com/legeling/AltForge/actions/runs/35985608497) 成功：iOS Simulator 定向 XCTest（含 `testIPAIconEditorUpdatesTemporaryAppOnly`）、unsigned iOS IPA、macOS Universal DMG、macOS 裁切 fixture 和 Windows ZIP 均通过。分支预检没有创建 Release；标签流水线与下载校验仍需单独执行。真机验收仍在 `ISSUE-20260923-001`，不把 CI 视为设备安装证明。
