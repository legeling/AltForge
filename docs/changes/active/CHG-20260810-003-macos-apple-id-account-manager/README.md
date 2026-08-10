# CHG-20260810-003：macOS Apple ID 账号管理

- 状态：In progress
- 日期：2026-08-10
- 类型：UX / Security / Authentication / Localization

## 背景

当前 AltForge Server 使用紧凑的 `NSAlert` 输入 Apple ID 和密码，每次安装都要重新输入，不支持账号历史、记住密码、密码显隐或 Caps Lock 提醒。原提示还固定声称凭据不会保存，无法承载用户明确授权后的本机 Keychain 保存能力。

## 范围

- 使用独立 AppKit 认证窗口替换旧 `NSAlert` accessory view。
- 使用同一视觉体系的独立双重认证窗口替换旧验证码 `NSAlert`，仅接受六位数字并支持直接粘贴。
- 可编辑账号选择器显示最近成功认证的账号，并提供忘记账号按钮。
- 提供“记住密码”复选框；只有用户勾选且 Apple 认证成功后才保存密码。
- 使用 secure/plain 双文本框和眼睛图标切换密码显隐；显示实时 Caps Lock 提醒。
- 使用现有 KeychainAccess package，将 versioned 账号 archive 限制为本机、最多八个账号和 64 KiB。
- 同步英文、简体中文、README、requirements、design、verification 和 repository contract。

## 非范围

- 不缓存 2FA code、Apple session、anisette data、certificate 或其他签名材料；验证码仅在当前 Apple verification callback 生命周期中使用。
- 不改变 Apple API、团队选择、设备注册、签名、安装协议或 Windows 认证窗口。
- 不把账号或密码同步到 iCloud，不实现自有账号服务。

## 追踪

- Requirement：`FR-029`、`AC-019`
- Design：`DES-016`
- Verification：`TEST-028`、Suite H
- Task：`T-018`

## 安全、复杂度与失败行为

账号与可选密码保存在 `afterFirstUnlockThisDeviceOnly` Keychain service 的单个 archive 中，一次 update 同时替换最近顺序和密码选择，不存在明文 fallback。输入、archive 大小和账号数量均有上限；读取和更新为 `O(accounts + bytes)`，账号最多八个。损坏或不可访问的 Keychain 不阻止手工认证，只显示无敏感详情提示；保存失败不改变认证和安装结果，也不输出账号或密码。

Caps Lock 使用窗口 modal 生命周期内唯一 local event monitor，窗口退出时通过 `defer` 释放。认证和 UI 不新增网络请求、重试、后台队列或常驻进程。

## 验证计划

- repository、release metadata、version、JSON/PBX/Swift build 检查。
- AltServer macOS Debug build，确认 KeychainAccess 已链接且 window controller 可编译。
- 脱敏手工矩阵：空历史、单/多账号、记住/不记住、选择/忘记、显隐、Caps Lock、取消、认证失败、2FA、损坏 archive。
- 检查 UserDefaults、日志、错误和发布产物不包含凭据。

## 当前验证结果

- repository contract、release metadata、version、localization JSON、project PBX 与 diff whitespace 检查通过。
- AltServer macOS Debug 无签名构建通过，确认账号窗口、双重认证窗口与 KeychainAccess target linkage 可编译。
- 使用注入的脱敏内存账号进行了独立窗口截图检查；账号下拉、忘记按钮、密码掩码、眼睛按钮、记住密码、六位验证码输入和操作按钮布局正常。
- 真实 Apple 认证、2FA、Keychain 系统交互及设备安装矩阵仍待脱敏人工验证，因此 change 保持 `In progress`。

## 回滚

恢复 AppDelegate 的旧 `NSAlert` 表单和原安装方法签名，移除两个新 Swift 文件及 AltServer 的 KeychainAccess product dependency。新的 Keychain service 与旧数据无共享；若回滚后需要彻底清理，应由后续受控迁移显式删除，不在回滚中静默移除用户钥匙串数据。

## 残余风险

- Apple 真实认证、2FA 与安装仍需要脱敏测试账号和真实设备手工验证。
- Keychain 权限、锁定状态与系统提示在不同 macOS 环境可能不同，build/static 不能替代实际交互。
