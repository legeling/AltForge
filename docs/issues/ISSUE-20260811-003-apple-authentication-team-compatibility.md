# ISSUE-20260811-003：Apple 认证、2FA 与团队类型兼容尚未完成实测

- 状态：Open
- 优先级：P1
- 发现日期：2026-08-11
- 关联：`FR-029`、`FR-030`、`DES-016`、`TEST-028`、`TEST-029`、`T-018`、`CHG-20260810-003`

## 问题

AltForge Server 已实现保存账号、Keychain 密码读取、六位 2FA、认证失败后保留输入、团队类型显示和托管证书保护，但这些路径尚未用脱敏的免费、个人、组织和企业团队完成真实 Apple Developer 服务矩阵。Apple 服务响应和各类团队能力会变化，静态 contract 与 mock UI 不能证明生产认证可用。

## 上游证据

最后核对：2026-08-11。

- [AltStore #199](https://github.com/altstoreio/AltStore/issues/199) 为 Open，企业账号被识别为免费账号，最后更新 2026-04-30。
- [AltStore #1728](https://github.com/altstoreio/AltStore/issues/1728) 为 Open，企业账号登录返回 `-22322`，创建于 2026-03-15。
- [AltStore #1737](https://github.com/altstoreio/AltStore/issues/1737) 为 Open，报告 iOS 26.4 下 2FA code 缺失或替代流程失效，最后更新 2026-07-10。
- [AltStore #635](https://github.com/altstoreio/AltStore/issues/635) 为 Open，报告登录响应格式错误，最后更新 2026-06-18。
- [AltStore #1751](https://github.com/altstoreio/AltStore/issues/1751) 为 Open，报告 iOS 27 环境无法取得 anisette `machineID`，最后更新 2026-08-11。

这些报告覆盖认证数据、2FA、anisette 和团队分类的不同层次，不能合并为单一根因，也不能仅靠一个普通个人账号宣布全部解决。

该主题的 95 条开放报告、逐条处置与完整本地映射见 [`upstream/topics/01-apple-authentication-and-teams.md`](upstream/topics/01-apple-authentication-and-teams.md)。

## 风险

- 用户可能在输入正确凭据后仍被模糊错误阻塞，或无法进入 2FA。
- 企业/组织账号可能被错误降级，造成错误的 App ID、证书或有效期策略。
- Keychain 重试或失败恢复若处理不当，可能重复请求系统授权或丢失用户刚输入的内容。

## 临时规避

保留失败后的账号和密码输入并展示原始错误域/代码的本地化摘要；不得要求用户关闭 2FA、提供账号密码、导出 Cookie 或绕过 Apple 安全验证。团队类型未确认时不显示推测标签，也不自动撤销未知来源证书。

## 关闭条件

1. 使用专用脱敏测试账号覆盖免费与付费个人团队；组织/企业账号不可用时必须保留明确的设备验证缺口。
2. 覆盖正常登录、六位 2FA、错误密码、取消 Keychain 读取、网络超时和服务返回格式错误；失败后窗口保持可编辑且不泄露凭据。
3. 登录成功后显示由 Apple 返回的真实团队类型，并验证免费/个人/组织/企业策略不会互相误用。
4. 验证 Keychain 每次动作只触发预期读取，账号删除同步清理本应用保存的凭据引用，日志不包含账号、密码、Cookie 或 anisette 数据。
5. 将结果写回 `TEST-028`、`TEST-029` 与 `CHG-20260810-003`，并记录实际覆盖和未覆盖团队类型。

## 回滚

认证 UI 和团队 metadata 不改变 Server Protocol 或数据库 schema。若真实服务验证发现回归，可撤回账号复用和团队标签显示，恢复单次登录输入；不得通过明文存储或关闭 2FA 规避问题。
