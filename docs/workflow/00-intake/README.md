# Project Intake

## 背景

AltForge 是 AltStore Classic 的维护型派生项目。上游代码提供成熟的 iOS 侧载、Apple Developer 服务交互、AltServer 设备通信和应用刷新能力，但长期存在国际化、Unicode IPA、诊断、系统兼容和发布可复现性方面的缺口。

项目的价值不是重新实现一套侧载系统，而是在保留上游架构和同步能力的前提下，持续修复影响真实安装流程的问题，并提供可验证、可发布的维护版本。

## 目标用户

- 希望在受支持的 iPhone 或 iPad 上通过个人 Apple ID 安装 IPA 的最终用户。
- 使用中文或安装包含 Unicode 名称、资源文件和路径的应用的国际用户。
- 需要构建、诊断、维护或向上游回馈修复的贡献者。
- 负责生成 GitHub Release、校验产物和维护 AltStore source 的发布维护者。

## 核心场景

1. 用户在 macOS 或 Windows 上运行 AltServer，把 AltForge 安装到已连接设备。
2. 用户在 AltForge 中选择或下载 IPA，应用通过局域网把包发送给 AltServer。
3. AltServer 使用用户 Apple ID 对应的开发团队、证书和 provisioning profile 重签并安装应用。
4. AltForge 在应用过期前刷新签名，并展示来源、更新、App ID、权限和错误信息。
5. 维护者通过 CI 构建未签名 IPA、macOS/Windows AltServer、source JSON 和校验和，并用版本标签发布。

## 项目目标

- `GOAL-001` 保持核心安装、签名、刷新链路可靠且可诊断。
- `GOAL-002` 让 Unicode 应用名、IPA 内部 Unicode 文件名和非英语工作流成为受支持场景。
- `GOAL-003` 保持与上游 AltStore 的架构相容，降低同步修复的成本。
- `GOAL-004` 建立可重复的构建、测试、发布和文档收敛流程。
- `GOAL-005` 在不降低安全边界的前提下改善兼容性和使用体验。

## 非目标

- 不绕过 Apple 的账户、证书、App ID 数量或签名有效期限制。
- 当前不提供已签名的 Windows MSI/MSIX；Windows AltServer 以完整便携 ZIP 交付。
- 当前不承诺 macOS Developer ID 签名或 Apple notarization。
- 当前发布物是 AltStore Classic 形态，不承诺 Marketplace/PAL 分发能力。
- 不在主仓库重新实现密码学、Apple Developer 协议或设备通信底层；优先维护现有 AltSign 与 libimobiledevice 集成。

## 约束

- Apple Developer API、设备服务和系统版本会变化，部分流程只能通过真实账户和设备验证。
- Apple 目标编译需要 Xcode、CocoaPods、Swift Package 依赖和递归 submodule；Windows 目标需要 Visual Studio C++、PowerShell 和 vcpkg。
- 用户凭据、证书、anisette data、设备标识和日志中的个人信息必须按敏感数据处理。
- 上游同步与本地品牌、bundle identifier、source URL、localization 改动可能产生冲突。
- 发布构建目前允许 `CODE_SIGNING_ALLOWED=NO`，产物安装时再由 AltServer 完成设备相关签名。

## 成功标准

- 高优先级需求均存在 `FR -> DES -> TEST -> T` 追踪链。
- CI 能在受控超时内构建 iOS Simulator、macOS 和 Windows 目标，并运行关键自动化测试。
- 包含中文显示名和中文资源文件名的 IPA 有可重复的回归 fixture。
- 发布标签能生成结构正确、带 SHA-256 的预期产物。
- 新发现的限制和技术债不再只存在于 Issue 或聊天中。

## 待确认

- `[待确认]` macOS Developer ID 签名与 notarization 的目标版本和凭据管理方案。
- `[待确认]` Windows 安装器的代码签名、安装格式和凭据管理方案。

当前工具链口径已确认：使用 Xcode 26，项目保持 Swift 5.0 language mode；未来迁移 Swift 6 language mode 时另建 change。
