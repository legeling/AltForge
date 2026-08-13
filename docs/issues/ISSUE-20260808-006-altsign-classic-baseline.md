# ISSUE-20260808-006：AltSign submodule 仍基于 Marketplace 配置

- 状态：Open
- 优先级：P0
- 发现日期：2026-08-08

## 问题

当前 superproject 固定的 AltSign commit `4b4a585a` 基于其 `marketplace` 分支，`Package.swift` 定义了 `MARKETPLACE`。这会排除 Classic Apple ID 认证所需的部分 GSA/SRP crypto 实现，与本仓库的 Classic 发布目标不一致。

上游 Classic 基线 `db8e0eb` 已包含较新的 Classic crypto/Xcode 26 兼容改动，但与当前 Unicode fork 分支存在分叉，不能只改一个编译宏或直接替换 gitlink。

## 风险

- Classic 登录、证书获取和签名链路可能在真实账户环境失败。
- 直接合并相关上游 PR 会夹带 Pods、硬编码 SDK 路径等无关内容。
- 未推送的 submodule commit 或 dirty submodule 无法被 CI 和其他维护者复现。

## 上游证据

最后核对：2026-08-11。

- [AltStore #1692](https://github.com/altstoreio/AltStore/issues/1692) 仍为 Open，报告 nested plug-in 签名后应用启动崩溃，最后更新 2026-06-29。
- [AltStore #1660](https://github.com/altstoreio/AltStore/issues/1660) 仍为 Open，报告特定 IPA 触发 `ldid` assertion，最后更新 2025-11-06。
- [AltStore #199](https://github.com/altstoreio/AltStore/issues/199) 仍为 Open，报告企业团队被识别为免费团队，最后更新 2026-04-30。

这些问题不证明根因与当前 AltSign gitlink 完全相同，但覆盖了相同的签名格式、嵌套代码和团队能力边界，因此保留为回归输入与实机矩阵依据。

IPA、签名和归档主题的 81 条开放报告与逐条处置见 [`upstream/topics/02-ipa-signing-and-packaging.md`](upstream/topics/02-ipa-signing-and-packaging.md)。

## 解决标准

1. 在 `legeling/AltSign` 创建可追踪的 Classic 分支，以已验证的上游 Classic commit 为基线。
2. 重放 Unicode App ID/ZIP 修复并完成独立 syntax、archive fixture 与构建验证。
3. 使用脱敏测试 Apple ID 和真实设备验证登录、个人/组织/免费团队选择、签名与安装。
4. 先提交并推送 AltSign commit，再更新 AltForge gitlink；失败时回退 gitlink 即可恢复原基线。

本轮未留下 AltSign dirty worktree，也未在缺少真机证据时修改 superproject gitlink。
