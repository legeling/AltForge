<p align="center">
  <img src="../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Release Records

## 发布模型

- AltForge 的独立版本序列从 `2.4.0` 开始，按语义版本递增；上游版本只作为 provenance 记录，不参与本仓库版本排序。
- 只有与根目录 `VERSION` 完全一致的纯数字 `vX.Y.Z` tag 才触发 GitHub Actions Release workflow；branch push 与 pull request 不触发构建。
- `VERSION` 统一 iOS、macOS 和 Windows 产品版本；CI build number 使用 GitHub run number，不与产品版本混用。
- 产物：`AltForge.ipa`、`AltForge-AltServer-macOS.dmg`、`AltForge-AltServer-Windows.zip`、`apps.json`、`flags.json`、`sources.json`、`recommended-sources.json`、`developerdisks.json`、`SHA256SUMS.txt`。
- workflow 只创建 Draft Release；维护者核对版本、文件列表、checksum、安装说明与已知风险后才能在 GitHub UI 人工发布。Draft 不改变 `releases/latest`。
- `apps.json` 当前版本使用 tag 固定 IPA URL，并从上一正式 source 保留最多 19 个旧版本；总版本数上限为 20。
- IPA 是 unsigned build，由 AltServer 在安装时针对用户/设备签名。
- `developerdisks.json` 只是经审核的第三方下载索引，不表示 AltForge 拥有或镜像其中的 Apple/社区文件；修改条目必须检查 schema、HTTPS、host 和来源许可证/可信度。
- macOS DMG 当前未 Developer ID 签名或 notarize；本地 ad-hoc 试装结果不能替代公开分发验证。

首个正式 Release 公开前，`releases/latest/download/*.json` 与官方 IPA URL 返回 404 属于预期状态；不得把 Draft 当作用户可下载安装的正式版本。

## 记录规则

每个正式 AltForge release 增加 `v<version>.md`，至少记录：tag/commit、用户可见变化、兼容性、migration、产物 hash、实际验证、已知问题和回滚/升级说明。

本基线未根据本地 inherited tags 推断已正式发布的 AltForge 版本；首次 release 后补具体记录。
