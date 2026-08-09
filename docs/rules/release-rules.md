# Release Rules

## 发布前

- Release 必须对应明确版本/tag、completed changes、已解决/已知 issues 和可复现构建配置。
- 核对 Classic/Marketplace 形态、bundle/version、最低系统、entitlement、submodule gitlink 和 dependency lockfile。
- 运行 release 所需 build/test、artifact smoke test 和 checksum 验证；签名、notarization、真实设备安装等未执行项必须明确披露。
- Release notes 只描述实际交付行为，区分新功能、修复、兼容限制、升级/回滚步骤和已知风险。

## 产物

- 当前仓库预期产物为 `AltForge.ipa`、macOS AltServer archive、Windows AltServer archive、`apps.json` 和 `SHA256SUMS.txt`；实际 workflow 变化时同步 README、verification 和本文件。
- 产物应来自同一 tag/commit，记录构建环境与 checksum，不手工替换 release 中的同名文件而不更新记录。
- 未签名 IPA、未 Developer ID 签名或未公证 macOS app 必须准确标注，不能暗示可直接生产分发。
- Artifact 不得包含开发凭据、profile、证书、DerivedData、调试日志或第三方私有测试包。

## 权限与回滚

- 创建/推送 tag、触发发布、上传或删除 artifact、修改 source feed 均需要用户明确授权。
- 发布失败时停止后续步骤，保留可诊断日志并清理临时凭据/产物；禁止对同一 tag 静默换包。
- 已发布版本需要撤回时，记录原因、影响、替代版本和用户操作；Git 历史与 release 页面处理必须可审计。
- 发布后新增 `docs/releases/vx.y.z.md`，同步 change/issue 状态并验证下载链接与 checksum。
