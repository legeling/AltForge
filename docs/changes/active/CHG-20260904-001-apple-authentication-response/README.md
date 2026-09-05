# CHG-20260904-001：修复 Apple 认证响应格式失败

- 状态：Released in v2.4.4 / real login unresolved
- 日期：2026-09-04
- 类型：Bugfix / Authentication / Dependency

## 背景

用户使用同一 AltForge 客户端安装 Duolingo 与微信时，均在“正在认证 Apple ID”阶段失败，错误为 `NSCocoaErrorDomain 3840`，操作尚未进入 IPA 读取。最初运行的 AltForge Server 2.4.0 仍发送 2019 年 Xcode 11 client version `3594.4.19`；升级到已修复该身份与基础错误映射的 AltForge Server 2.4.3 后，登录仍在约 2.5 秒内以认证响应不可读失败。这证明 IPA 不是故障源，也证明旧客户端身份不是本次持续失败的完整根因。

上游 AltStore #1747 记录了相同 3840 错误，其解析器实际收到以 `<html>` 开头的响应；2026-09-04 又有多名用户集中复现。上游 #1772 证明旧 `X-MMe-Client-Info` 会造成独立的 2FA 循环，但明确指出 `X-Xcode-Version` 与 User-Agent 不是该问题的决定字段。SideStore #1446 进一步捕获到 `init`、`complete` 均成功后，Apple 的 `apptokens` 请求返回 HTML 503；这与当前“所有 App 均在认证阶段失败”的现象高度一致，但 AltForge 2.4.3 尚未保留认证子步骤和 HTTP 状态，不能把该上游样本当作本次请求的确定证据。

## 范围

- AltForge Server 的 AOSKit、XPC 和 Mail plug-in anisette 路径统一使用 Xcode 27 beta 6 身份，同时保留当前 Mac model、系统版本和 build。
- Xcode 产品版本 `27.0 (27A5252f)` 与认证 bundle version `25183.54.10` 由 AltSign 单点定义；认证、2FA 和 Developer Services 请求不再分别硬编码 Xcode 11.2。
- GSA 登录的 `User-Agent` 从当前系统读取 CFNetwork 与 Darwin 版本，不再伪装成 macOS Mojave 的 2018 网络栈。
- iOS、macOS 与 Windows 产品版本统一进入 `2.4.2`，标签流水线构建同一 commit 的三平台产物。
- AltSign 解析 Apple GSA 响应失败时返回 `authenticationHandshakeFailed (3020)`，不再把底层 property-list 3840 当作 IPA 格式错误直接展示。
- 所有认证响应 plist 解析统一经过单一 helper；失败只附带固定集合中的认证步骤、HTTP 状态码和 MIME type，覆盖 GSA 原始响应、解密后的 SRP/app-token payload 与 trusted-device 2FA 响应。
- 用户提示区分 HTTP 429、HTTP 5xx、HTML 与其他畸形响应；5xx 明确说明是服务端故障，不是 IPA 或密码错误，详情显示认证步骤和 HTTP 状态码。
- 解析失败不记录响应正文，不修改或持久化 Apple ID、密码、验证码、token 或 anisette 数据。
- 不修改 SRP 算法、Apple endpoint、认证次数、Server Protocol、IPA 处理或签名 entitlement。

## 映射

- Requirement：`FR-041`、`AC-030`
- Design：`DES-027`
- Verification：`TEST-040`
- Task：`T-040`
- Issue：`ISSUE-20260904-001`
- Upstream：[`altstoreio/AltStore#1747`](https://github.com/altstoreio/AltStore/issues/1747)、[`altstoreio/AltStore#1772`](https://github.com/altstoreio/AltStore/issues/1772)

## 复杂度与资源

客户端描述构造、认证步骤分类和错误映射均为每次认证的 `O(1)` 操作，不增加请求、重试、缓存、进程或持久数据。认证响应继续一次性读取，只保留三个短字符串/数字字段，不打印、复制或持久化正文。Apple 服务不可用或继续返回非 plist 时立即失败，由用户显式重试，不进行自动或无界重试。

## 验证计划

- repository contract 拒绝 `3594.4.19`，要求现代客户端版本与畸形响应的 3020 映射，并检查不记录响应正文。
- repository contract 要求认证文件只有统一 helper 可以调用 plist response parser，并要求安全保留 operation/status/MIME 元数据。
- XCTest 覆盖 `apptokens + HTTP 503 + text/html` 和 `complete + HTTP 200 + text/html` 的地道中英文提示，确保不误报 IPA 或密码。
- repository contract 同时拒绝 `11.2 (11B41)`，要求所有 `X-Xcode-Version` 与 `X-MMe-Client-Info` 使用同一组 Xcode 27 身份。
- repository contract 拒绝 `CFNetwork/978.0.7 Darwin/18.7.0`，要求 GSA User-Agent 使用当前运行系统版本。
- 构建 macOS AltServer 与 iOS AltStore target，确认根工程和 AltSign fork 同时编译。
- 使用不含凭据的受控请求确认本机到 `GsService2` 的 TLS/HTTP 路径返回 plist Content-Type。
- 使用专用测试 Apple ID 在真实设备完成登录、2FA、团队和证书查询；随后分别安装一个普通测试 IPA 与用户报告的应用，确认流程进入 IPA 读取阶段。

## 当前验证

- `ruby Scripts/test_repository_contract.rb`、root/submodule `git diff --check` 通过。
- macOS 26.5.2 / Xcode 26.6 下，AltServer Debug generic macOS build 通过；iOS AltStore Debug generic Simulator build 通过，两者均编译当前 AltSign fork。生成的 AltSign framework 包含 Xcode 27 beta 6 的 `27.0 (27A5252f)` / `25183.54.10`，且不含 `3594.4.19`。
- `v2.4.2` 预发布批次的 9 项定向 XCTest、unsigned Release-iphoneos build、Universal macOS Release build、IPA/DMG 打包和 Apple 产物校验通过；本地产物版本为 `2.4.2 (999)`，AltSign framework 只命中新身份。
- GitHub Actions run `33858366269` 的 Apple、Windows 与 publish jobs 通过；公开 Release `v2.4.2` 的 IPA/DMG/Windows ZIP、metadata、checksum 和 latest URL 回读通过，CI build number 为 `20`。
- 不含账号数据的受控 GSA 请求只能验证 TLS/HTTP 可达性，不能产生有效认证结论；没有把该探测当作 SRP 登录通过。
- 未执行真实 Apple ID、2FA、团队、证书或设备安装验证；该缺口继续由 `ISSUE-20260904-001` 跟踪。
- 用户在已安装并运行的 `v2.4.3 (21)` 上再次复现认证失败；现有 3020 提示证明基础映射生效，但该版本没有认证子步骤/HTTP 元数据，无法从现有诊断编号反推出具体响应状态。
- 本轮 follow-up 的 repository contract、root/submodule diff check、两份 string catalog JSON/编译、三项认证提示 XCTest、iOS Simulator Debug build 与 Universal macOS Debug build 均通过；HTTP/MIME/operation 字段经序列化后仍保留。
- 上述验证不使用真实 Apple ID，也不能令 Apple 的 503 服务端响应成功；后续审查修复已随 v2.4.4 发布，必须在新构建上复测才能确认用户本次失败的具体子步骤和 HTTP 状态。

## 回滚

恢复 `AnisetteDataManager.swift` 的客户端版本和 AltSign 的响应错误映射即可回滚源码；若新身份被 Apple 再次淘汰，应更新固定版本并重复登录 harness，而不是恢复已确认被拒绝的 Xcode 11 身份。发布前没有数据库、协议或用户数据迁移。

## 残余风险

- Apple GSA 是外部、未公开稳定的服务端协议，当前接受的 client version 未来仍可能变化。
- 上游 `altstoreio/AltStore#1713` 使用 Xcode 26.2 身份但包含大量无关依赖产物且 merge state 为 dirty；`#1770` 处理 macOS 26/27 anisette 生成，仍保留 Xcode 11 身份并引入 VM/外部 ADI 获取，未直接移植。上游 `marketplace` 及 AltSign `master` 当前也没有可直接同步的更新提交。
- 本轮不读取或保存真实凭据，真实账号/2FA/团队/证书 E2E 需要用户在设备上自行输入并确认。
- 认证身份与基础 3020 映射已随 `v2.4.2` 交付，直接更新流程已随 `v2.4.3` 交付；阶段化诊断已随 v2.4.4 发布，仍需用户复测取得实际 HTTP/operation 证据。
