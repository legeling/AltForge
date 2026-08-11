# ISSUE-20260808-003：macOS release 未签名且未 notarize

- 状态：Open / 待确认
- 优先级：P1
- 发现日期：2026-08-08

## 问题

Release workflow 以 `CODE_SIGNING_ALLOWED=NO` 构建并压缩 AltServer。Xcode 可能给主 Mach-O 添加无 Team ID/Authority 的 linker ad-hoc signature，但这不是 Developer ID 签名，也没有 notarization。用户可能需要通过 Finder context menu 绕过 Gatekeeper 提示，无法提供生产级安装体验。

## 风险

- 用户难以区分正常 Gatekeeper 提示与被篡改产物。
- 每次 ad-hoc/source rebuild 的代码身份可能变化，macOS 钥匙串无法稳定复用既有 ACL，用户即使已保存凭据也可能再次看到系统授权框。
- 后续 Sparkle 自动更新需要稳定签名身份和 feed 安全策略。

## 解决标准

决定是否支持 Developer ID + notarization；若支持，凭据使用 GitHub Actions secrets/OIDC compatible storage，验证 stapling、签名和跨版本 Keychain ACL 稳定性，不在日志中输出 secret。认证 UI 自身只允许一次窗口初始化读取，不能以普通文件或进程级密码缓存规避系统授权。
