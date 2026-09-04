# ISSUE-20260904-001：Apple 新认证身份缺少真实账号与设备验证

- 状态：In progress
- 优先级：P0
- 影响：所有需要重新认证 Apple ID 的安装与刷新
- 关联：`FR-041`、`DES-027`、`TEST-040`、`T-040`、`CHG-20260904-001`

## 证据

- 2026-09-04 用户安装 Duolingo 与微信均在认证阶段失败，错误为 `NSCocoaErrorDomain 3840`，尚未读取 IPA。
- 运行环境是 macOS 26.5.2；正在运行的 AltForge Server 为 2.4.0，源码发送旧 Xcode client version `3594.4.19`。
- [`altstoreio/AltStore#1747`](https://github.com/altstoreio/AltStore/issues/1747) 的同类错误明确显示响应以 `<html>` 开头，并在 2026-09-04 出现新增集中报告。
- [`altstoreio/AltStore#1772`](https://github.com/altstoreio/AltStore/issues/1772) 使用登录 harness 确认 Apple 已拒绝旧 Xcode 11 身份，现代且内部一致的 model/macOS/build/client tuple 可完成 token 签发。
- `v2.4.2` 候选实现固定经该 harness 验证的 Xcode bundle version `25183.54.10`，Mac model、macOS version/build、CFNetwork 与 Darwin 继续从运行环境读取；上游 #1713 的广泛依赖变更和 #1770 的 VM/外部 ADI 方案未合入。
- `v2.4.2 (20)` 已通过 GitHub hosted Apple/Windows build、定向 XCTest、产物 identity/checksum 与 latest URL 回读并公开发布；这些证据仍不包含真实 Apple 账号或设备安装。

## 临时规避

- 不反复尝试不同 IPA；该故障发生在认证阶段，与 IPA 内容无关。
- 可以确认设备与 Mac 时间自动同步，并临时排除 VPN、代理或 DNS 拦截，但这些操作不能修复已经被 Apple 拒绝的旧客户端身份。
- 不在 Issue、截图或日志中提供 Apple ID、密码、验证码、UDID、token 或 anisette headers。

## 完成条件

- macOS 与 iOS target 使用新身份完成构建。
- 专用测试 Apple ID 在真实设备完成登录、2FA、团队和证书查询。
- 至少一个普通测试 IPA 进入读取、签名和安装阶段；Apple 返回畸形内容时用户看到 3020 握手失败且日志不含响应正文。
- 新 AltForge Server 交付后重新验证用户报告路径，再将本 Issue 标记为 Resolved。
