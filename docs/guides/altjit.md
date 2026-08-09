# AltJIT

## 简体中文

AltJIT 是可选的桌面辅助功能，需要受支持的 macOS 主机、已连接并信任的设备、AltServer，以及 AltServer 错误中列出的依赖。设备和系统支持范围会随 Apple 开发者磁盘与调试服务变化。

### 提交问题前

1. 确认 AltServer 能看到设备，并且目标 iOS App 至少启动过一次。
2. 使用 Wi-Fi 发现时让 Mac 和设备处于同一网络；再用 USB 重试，以区分网络发现问题。
3. 记录 AltForge commit/版本、macOS 与 iOS/iPadOS 版本、设备型号，以及完整错误域和错误码。
4. 从日志与截图中移除 Apple ID、UDID、证书、描述文件、令牌、Cookie 和 anisette 数据。

提交脱敏报告前，请先搜索已有 Issue：

https://github.com/legeling/AltForge/issues

## English

AltJIT is an optional desktop-assisted feature. It requires a supported macOS host, a connected and trusted device, AltServer, and any dependencies named by the error shown by AltServer. Device and OS support varies with Apple's developer-disk and debugging services.

## Before reporting an issue

1. Confirm the device is visible in AltServer and the iOS app has been launched at least once.
2. Keep the Mac and device on the same network when using Wi-Fi discovery; retry with USB to isolate discovery failures.
3. Record the AltForge commit/version, macOS version, iOS/iPadOS version, device model, and the complete error domain/code.
4. Remove Apple IDs, UDIDs, certificates, profiles, tokens, cookies, and anisette data from logs and screenshots.

Search existing issues before opening a sanitized report:

https://github.com/legeling/AltForge/issues
