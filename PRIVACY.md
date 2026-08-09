# AltForge Privacy

## 简体中文

AltForge 不运营账户服务、分析后端或广告网络。Classic 构建使用空的应用标识初始化 TelemetryDeck，因此 AltForge 不会有意提交产品分析数据。

Apple ID、密码、验证码、证书、描述文件、设备标识和 anisette 数据仅用于 Apple 认证、签名和设备安装流程。这些数据不得提交到仓库、上传到 GitHub Release 或写入普通日志。

AltForge 会直接连接 Apple 开发者与设备服务、本仓库的 GitHub Release 资产、用户添加的 AltStore 兼容软件源，以及项目文档披露的部分兼容性服务。第三方会按照其自己的隐私条款处理请求。在 AltForge 建立独立替代方案前，开发者磁盘兼容 metadata 仍由 AltStore 上游托管。

Classic 构建不运营 Patreon 赞助计划。只有第三方软件源要求赞助权限时才需要关联 Patreon；该兼容流程仍使用既有的 Patreon API 与 AltStore 兼容 OAuth redirect 服务，不需要此功能时请勿关联账户。

GitHub Issue 默认公开。提交日志或截图前，请移除 Apple ID、UDID、证书、描述文件、令牌、Cookie 和私有 IPA 文件。任何影响隐私的行为变化都必须同步更新 Release 说明和本文档。

## English

AltForge does not operate an account service, analytics backend, or advertising network. Classic builds initialize TelemetryDeck with no application identifier, so AltForge does not intentionally submit product analytics.

Apple IDs, passwords, verification codes, certificates, provisioning profiles, device identifiers, and anisette data are used only for the Apple authentication, signing, and device-installation flow. They must not be committed, uploaded to GitHub Releases, or included in ordinary logs.

AltForge connects directly to Apple developer and device services, GitHub Release assets, user-added AltStore-compatible sources, and selected compatibility services documented by the project. Those third parties process requests under their own privacy terms. The current developer-disk compatibility metadata remains hosted by AltStore upstream until AltForge has an independently maintained replacement.

Classic builds do not operate a Patreon campaign. Patreon linking is only needed for third-party sources that require a pledge, and this compatibility path still uses the existing Patreon API and AltStore-compatible OAuth redirect service. Do not link an account when that capability is not needed.

Bug reports are public by default. Remove Apple IDs, UDIDs, certificates, profiles, tokens, cookies, and private IPA files before posting logs or screenshots to GitHub Issues.

Privacy-impacting behavior changes require an updated release note and revision of this document.
