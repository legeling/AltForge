# 上游修复评估

- 上游仓库：[`altstoreio/AltStore`](https://github.com/altstoreio/AltStore)
- 核对日期：2026-08-11
- 范围：与本次 iOS 崩溃、Apple 认证、桌面权限和 AltJIT 直接相关的提交与开放 PR

## 已移植

| 上游 | 结论 |
|---|---|
| [`a9636a73` My Apps iOS 18 assertion](https://github.com/altstoreio/AltStore/commit/a9636a73a2a1390e6ebf88efd8610607e5c242e1) | 上游直接提交、无关联 PR。build 13 真机栈与其根因一致，已按 AltForge Storyboard 和品牌适配移植。 |
| [`832e9fab` App IDs iOS 18 assertion](https://github.com/altstoreio/AltStore/commit/832e9faba0f5f6389e567725ea9ac53623c64fa3) | 上游直接提交、无关联 PR。当前分支仍有相同 header 越权 dequeue，已同步移植并加入静态门禁。 |

## 暂不合并

| 上游 | 评估 |
|---|---|
| [PR #1770 macOS 26+ anisette](https://github.com/altstoreio/AltStore/pull/1770) | Open、无 CI check，测试清单未完成；引入约 700 行 VM/网络代码、Linux kernel/initramfs 二进制、首启下载和持久状态。需先完成来源、许可证、签名、公证、超时和真实认证评审。 |
| [PR #1713 authentication handshake](https://github.com/altstoreio/AltStore/pull/1713) | Open、conflicting、无 CI check；关键 SRP 诉求已由 AltSign fork `d775559` 以 Classic 边界实现。PR 还混入生成 Pods、固定 SDK 路径与易失 Apple header，不整体合并。 |
| [PR #1733 hardened-runtime entitlements](https://github.com/altstoreio/AltStore/pull/1733) | Open、无 CI check；新增的 network client/server entitlement 属于 App Sandbox 能力，不能证明未 sandbox Server 的菜单栏或 socket 修复。需 Developer ID、公证、TCC 与实机证据。 |
| [PR #1537 newer pymobiledevice3](https://github.com/altstoreio/AltStore/pull/1537) | 2024 年单行改动；当前 AltForge 已区分 legacy `remote start-tunnel` 与新系统 `lockdown start-tunnel`，退回单一路径会丢失版本兼容。 |
| [PR #280 NSNull installation crash](https://github.com/altstoreio/AltStore/pull/280) | 2020 年遗留、conflicting，并依赖旧 AltSign PR；不能直接套用到当前 installation proxy/AltSign 基线，保留为 fixture 线索。 |

## 合入门禁

开放 PR 的 `MERGEABLE` 只表示 Git 能合并，不表示行为正确。进入 AltForge 前至少需要：定位到当前调用链、最小化补丁、双语错误行为、静态/单元回归、完整平台构建，以及涉及认证、签名、安装、JIT 或 entitlement 时的脱敏真机验证。没有这些证据时只进入 watchlist，不进入发布分支。
