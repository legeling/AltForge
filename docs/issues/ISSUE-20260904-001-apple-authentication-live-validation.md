# ISSUE-20260904-001：Apple 新认证身份缺少真实账号与设备验证

- 状态：In progress
- 优先级：P0
- 影响：所有需要重新认证 Apple ID 的安装与刷新
- 关联：`FR-041`、`DES-027`、`TEST-040`、`T-040`、`CHG-20260904-001`

## 证据

- 2026-09-04 用户安装 Duolingo 与微信均在认证阶段失败，错误为 `NSCocoaErrorDomain 3840`，尚未读取 IPA。
- 运行环境是 macOS 26.5.2；首次报告时正在运行的 AltForge Server 为 2.4.0，源码发送旧 Xcode client version `3594.4.19`。
- [`altstoreio/AltStore#1747`](https://github.com/altstoreio/AltStore/issues/1747) 的同类错误明确显示响应以 `<html>` 开头，并在 2026-09-04 出现新增集中报告。
- [`altstoreio/AltStore#1772`](https://github.com/altstoreio/AltStore/issues/1772) 使用登录 harness 确认旧 `X-MMe-Client-Info` 会导致 2FA 循环；该报告明确说明 stock `X-Xcode-Version` 与 User-Agent 不是决定字段。
- `v2.4.2` 候选实现固定经该 harness 验证的 Xcode bundle version `25183.54.10`，Mac model、macOS version/build、CFNetwork 与 Darwin 继续从运行环境读取；上游 #1713 的广泛依赖变更和 #1770 的 VM/外部 ADI 方案未合入。
- `v2.4.2 (20)` 已通过 GitHub hosted Apple/Windows build、定向 XCTest、产物 identity/checksum 与 latest URL 回读并公开发布；这些证据仍不包含真实 Apple 账号或设备安装。
- 2026-09-04 用户在已安装并运行的 `v2.4.3 (21)` 上继续复现：认证约 2.5 秒后返回 3020 对应的“Apple 认证服务返回无法读取的数据”。因此旧身份不是持续故障的完整根因，且所有 IPA 共用的 Apple 登录前置步骤仍不可用。
- [`SideStore/SideStore#1446`](https://github.com/SideStore/SideStore/issues/1446) 的脱敏日志显示相同时间窗口内 GSA `init`/`complete` 成功，但 `apptokens` 返回 HTML 503。该模式与本次现象高度吻合；在 AltForge 发布带 operation/status/MIME 元数据的构建前仍只能视为强证据，不是本次请求的确证。

## 临时规避

- 2026-09-05 已发布 `v2.4.4 (22)`，包含阶段化诊断、脱敏、双重认证 HTTP 校验和真实 parser fixture。13 项 hosted XCTest、三平台构建和下载校验通过；仍需用户在新版复测实际登录。本次失败是否为 503 仍未证实，不能从现有日志排除账号、认证数据或网络因素。

- 不反复尝试不同 IPA；该故障发生在认证阶段，与 IPA 内容无关。
- 当前不要连续点击“继续”；如果 Apple 返回 429 或 5xx，反复提交不会修复服务端响应，还可能触发临时限流。
- 可以确认设备与 Mac 时间自动同步，并临时排除 VPN、代理或 DNS 拦截；这些操作不能修复 Apple 端持续返回的 5xx/HTML 响应。
- 不在 Issue、截图或日志中提供 Apple ID、密码、验证码、UDID、token 或 anisette headers。

## 完成条件

- macOS 与 iOS target 使用新身份完成构建。
- 专用测试 Apple ID 在真实设备完成登录、2FA、团队和证书查询。
- 至少一个普通测试 IPA 进入读取、签名和安装阶段；Apple 返回畸形内容时用户看到 3020 握手失败且日志不含响应正文。
- 失败详情能区分 `init`、`complete`、`apptokens`、解密 payload 与 2FA，并显示安全的 HTTP 状态码/MIME type；HTML/503 正文、headers 和凭据不得保存。
- 新 AltForge Server 交付后重新验证用户报告路径，再将本 Issue 标记为 Resolved。
