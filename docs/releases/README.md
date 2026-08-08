# Release Records

## 发布模型

- `v*` semantic version tag 触发 GitHub Actions Release workflow。
- 产物：`AltForge.ipa`、`AltForge-AltServer-macOS.zip`、`apps.json`、`SHA256SUMS.txt`。
- IPA 是 unsigned build，由 AltServer 在安装时针对用户/设备签名。
- macOS app 当前未 Developer ID 签名或 notarize。

## 记录规则

每个正式 AltForge release 增加 `v<version>.md`，至少记录：tag/commit、用户可见变化、兼容性、migration、产物 hash、实际验证、已知问题和回滚/升级说明。

本基线未根据本地 inherited tags 推断已正式发布的 AltForge 版本；首次 release 后补具体记录。
