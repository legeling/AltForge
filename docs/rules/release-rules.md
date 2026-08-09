# Release Rules

## 发布前

- AltForge 从 `2.4.0` 开始独立使用语义版本：兼容修复递增 patch，兼容新功能递增 minor，不兼容的产品、数据或协议变化递增 major。
- 上游 AltStore、AltServer 或依赖的版本/revision 只作为来源基线记录；同步上游不自动继承其版本号，也不得倒退 AltForge 已发布版本。
- 自动构建和 Draft Release 创建只能由纯数字 `vX.Y.Z` tag 触发；普通 branch push 与 pull request 不触发 workflow。
- 根目录 `VERSION` 是产品版本唯一来源，tag 必须严格等于 `v$(cat VERSION)`；iOS、macOS 与 Windows 产品版本必须同步，CI build number 独立使用 GitHub run number。
- Release 必须对应明确版本/tag、completed changes、已解决/已知 issues 和可复现构建配置。
- 核对 Classic/Marketplace 形态、bundle/version、最低系统、entitlement、submodule gitlink 和 dependency lockfile。
- 运行 release 所需 build/test、artifact smoke test 和 checksum 验证；签名、notarization、真实设备安装等未执行项必须明确披露。
- 标签 workflow 只能创建 Draft Release。维护者必须下载 Draft 资产、执行 checksum 复核并审阅安装说明与已知风险，之后才可人工公开发布。
- Apple job 必须在上传前验证 IPA Payload、DMG image/Applications link、bundle identity、版本/build number、arm64+x86_64 架构和当前签名策略；publish job 必须在创建 Draft 前重新执行 `SHA256SUMS.txt` 校验。
- Release notes 只描述实际交付行为，区分新功能、修复、兼容限制、升级/回滚步骤和已知风险。

## 产物

- 当前仓库预期产物为 `AltForge.ipa`、`AltForge-AltServer-macOS.dmg`、`AltForge-AltServer-Windows.zip`、`apps.json`、`flags.json`、`sources.json`、`recommended-sources.json` 和 `SHA256SUMS.txt`；实际 workflow 变化时同步 README、verification 和本文件。
- 产物应来自同一 tag/commit，记录构建环境与 checksum，不手工替换 release 中的同名文件而不更新记录。
- `apps.json` 每个版本必须使用对应 tag 的不可漂移 IPA URL，最多保留当前版本和 19 个历史版本。读取上一 source 时必须校验 source/bundle identity、去重并对格式错误 fail closed。
- 远程配置使用仓库中的 `Release/*.json` 安全默认值；修改 trusted/blocked source 或 feature flag 必须按代码变更审查，不得直接引用上游产品配置。
- 未签名 IPA、未 Developer ID 签名或未公证 macOS DMG 必须准确标注，不能暗示本地 ad-hoc 签名可直接生产分发。
- Artifact 不得包含开发凭据、profile、证书、DerivedData、调试日志或第三方私有测试包。

## 权限与回滚

- 创建/推送 tag、触发发布、上传或删除 artifact、修改 source feed 均需要用户明确授权。
- 发布失败时停止后续步骤，保留可诊断日志并清理临时凭据/产物；禁止对同一 tag 静默换包。
- 已发布版本需要撤回时，记录原因、影响、替代版本和用户操作；Git 历史与 release 页面处理必须可审计。
- 发布后新增 `docs/releases/vx.y.z.md`，同步 change/issue 状态并验证下载链接与 checksum。
