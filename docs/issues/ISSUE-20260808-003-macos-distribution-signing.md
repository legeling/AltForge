# ISSUE-20260808-003：macOS release 未签名且未 notarize

- 状态：Open / 待确认
- 优先级：P1
- 发现日期：2026-08-08

## 问题

Release workflow 以 `CODE_SIGNING_ALLOWED=NO` 构建并压缩 AltServer。用户可能需要通过 Finder context menu 绕过 Gatekeeper 提示，无法提供生产级安装体验。

## 风险

- 用户难以区分正常 Gatekeeper 提示与被篡改产物。
- 后续 Sparkle 自动更新需要稳定签名身份和 feed 安全策略。

## 解决标准

决定是否支持 Developer ID + notarization；若支持，凭据使用 GitHub Actions secrets/OIDC compatible storage，验证 stapling 与签名，不在日志中输出 secret。
