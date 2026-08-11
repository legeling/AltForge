# CHG-20260810-003：macOS Apple ID 账号管理

- 状态：In progress
- 日期：2026-08-10
- 类型：UX / Security / Authentication / Localization

## 背景

当前 AltForge Server 使用紧凑的 `NSAlert` 输入 Apple ID 和密码，每次安装都要重新输入，不支持账号历史、记住密码、密码显隐或 Caps Lock 提醒。原提示还固定声称凭据不会保存，无法承载用户明确授权后的本机 Keychain 保存能力。

`Dependencies/AltSign/Package.swift` 还遗留了 Marketplace 专用的 `MARKETPLACE` 编译条件。该条件会让 `GSAContext` 的 SRP 密钥生成、校验和服务端验证直接返回 `nil`/`false`；Classic AltForge Server 因此在发出第一个 Apple 认证请求前必然报 authentication handshake failure。

## 范围

- 使用独立 AppKit 认证窗口替换旧 `NSAlert` accessory view。
- 使用同一视觉体系的独立双重认证窗口替换旧验证码 `NSAlert`，仅接受六位数字并支持直接粘贴。
- 可编辑账号选择器显示最近成功认证的账号，并提供忘记账号按钮。
- 账号通过团队查询后记录最后确认的免费、个人开发者或组织/企业类型，仅在自定义账号选择器右侧显示已确认类型；未知类型不显示占位标识，也不把历史账号误称为持久登录会话。
- 提供“记住密码”复选框；只有用户勾选且 Apple 认证成功后才保存密码。
- 使用 secure/plain 双文本框和眼睛图标切换密码显隐；显示实时 Caps Lock 提醒。
- 点击继续后保持登录窗口与输入状态；认证失败以内联双语错误恢复编辑和重试，仅在取得 Apple account/session 后关闭。
- 保留 macOS 原生最小化按钮，允许用户在输入或认证期间将账号窗口收进 Dock；窗口不提供会破坏固定表单布局的缩放按钮。
- 移除 AltSign target 的 `MARKETPLACE` 编译条件，恢复 Classic Apple ID 登录需要的现有 SRP 实现，并通过 repository contract 防止回归。
- 证书管理只允许复用或经明确确认替换 AltForge/旧 AltStore 创建的开发证书，禁止回退选择任意 Xcode 证书；新证书以 AltForge 命名。
- 使用现有 KeychainAccess package，将 versioned 账号 archive 限制为本机、最多八个账号和 64 KiB。
- 每次打开认证窗口只读取一次账号 archive；账号切换复用窗口生命周期内的有界快照，窗口结束后立即释放，避免一次性“允许”授权被连续读取再次触发。
- 同步英文、简体中文、README、requirements、design、verification 和 repository contract。

## 非范围

- 不缓存 2FA code、Apple session、anisette data、certificate 或其他签名材料；验证码仅在当前 Apple verification callback 生命周期中使用。
- 不改变 Apple API 端点与协议、团队优先级、设备注册、签名算法、安装协议或 Windows 认证窗口。
- 不把账号或密码同步到 iCloud，不实现自有账号服务。

## 追踪

- Requirement：`FR-029`、`FR-030`、`AC-019`、`AC-020`
- Design：`DES-016`
- Verification：`TEST-028`、`TEST-029`、Suite H
- Task：`T-018`

## 安全、复杂度与失败行为

账号与可选密码保存在 `afterFirstUnlockThisDeviceOnly` Keychain service 的单个 archive 中，一次 update 同时替换最近顺序和密码选择，不存在明文 fallback。输入、archive 大小和账号数量均有上限；读取和更新为 `O(accounts + bytes)`，账号最多八个。认证窗口用一次 Keychain 读取取得同一 archive 的账号与可选密码，账号下拉切换只做最多八项的内存查找；modal 结束后丢弃快照和表单值。Swift 不保证内存即时覆写，因此快照不得提升为应用级缓存。损坏或不可访问的 Keychain 不阻止手工认证，只显示无敏感详情提示；保存失败不改变认证和安装结果，也不输出账号或密码。

Caps Lock 使用窗口 modal 生命周期内唯一 local event monitor，窗口退出时通过 `defer` 释放。认证和 UI 不新增额外网络端点、自动重试、后台队列或常驻进程；只有用户再次点击继续才发起下一次认证。

每次点击继续最多启动一个认证/安装链路；请求期间禁用重复提交、取消和关闭，完成后在主线程恢复或结束窗口。认证前失败不触发全局错误弹窗，不清空账号、密码或 consent；AltSign 的 30 个用户可见错误与 recovery key 在 AltServer 主 catalog 中补齐简体中文。Classic 构建不再定义 `MARKETPLACE`，因此 `GSAContext.start()`、SRP M1/M2 校验和 app-token checksum 使用 AltSign 已有的 CoreCrypto 路径；不新增密码学实现。认证成功后的团队、证书、签名和安装失败仍按既有全局错误流程处理。

团队类型在 `fetchTeam` 成功后写入同一个有界 Keychain archive；旧版 archive 没有该可选字段时省略类型，下次成功查询后原位升级，不需要迁移或清空密码。类型只是最后一次 Apple 团队查询结果，不保存 session/token，也不保证当前仍处于登录状态。

证书查询仅包含 `IOS_DEVELOPMENT`。本机缓存必须能以服务端 `machineIdentifier` 解密且序列号与 AltForge/旧 AltStore 证书一致才会复用；否则只可在明确展示证书与团队影响后替换该托管证书。普通 Xcode、分发和其他证书永不作为自动撤销 fallback。时间复杂度为 `O(certificates)`，Apple 返回的有界证书列表不额外常驻。

## 验证计划

- repository、release metadata、version、JSON/PBX/Swift build 检查。
- repository contract 检查账号列表与密码只通过一个 credential snapshot 读取，账号切换不再次访问 Keychain，modal 结束释放快照。
- AltServer macOS Debug build，确认 KeychainAccess 已链接且 window controller 可编译。
- 脱敏手工矩阵：空历史、单/多账号、记住/不记住、选择/忘记、显隐、Caps Lock、取消、认证失败、2FA、损坏 archive。
- 检查 UserDefaults、日志、错误和发布产物不包含凭据。

## 当前验证结果

- repository contract、release metadata、version、localization JSON、project PBX 与 diff whitespace 检查通过。
- AltServer macOS Debug 无签名构建通过，确认账号窗口、双重认证窗口与 KeychainAccess target linkage 可编译。
- 使用注入的脱敏内存账号进行了独立窗口截图检查；账号下拉、忘记按钮、密码掩码、眼睛按钮、记住密码、六位验证码输入和操作按钮布局正常。
- 登录窗口按最末可见操作行计算内容高度，不再让隐藏的 Caps Lock 或 Keychain 警告行在底部保留空白；警告出现时仍会按需扩展。
- 认证窗口已改为异步提交：请求中显示进度且不关闭，失败后保留输入并显示内联本地化错误；repository contract 覆盖全部 AltSign 错误 key 的简体中文翻译。
- 已确认失败根因是 AltSign package 错误定义 `MARKETPLACE`，导致 SRP 函数固定失败；已移除该条件并新增静态回归门禁，macOS Debug 构建覆盖真实 CoreCrypto 编译路径。
- 账号 archive 已兼容增加团队类型，只有选择器显示已确认类型；证书路径移除 `certificates.first` fallback，只允许明确替换 AltForge/旧 AltStore 证书。
- 账号窗口改为一次性读取 credential snapshot，账号选择不再发起第二次 Keychain 读取；repository contract、Swift 5 macOS Debug build 和 diff whitespace 检查通过。
- 真实 Apple 认证、2FA、Keychain 系统交互及设备安装矩阵仍待脱敏人工验证，因此 change 保持 `In progress`。

## 回滚

恢复 AppDelegate 的旧 `NSAlert` 表单和原安装方法签名，移除两个新 Swift 文件及 AltServer 的 KeychainAccess product dependency。新的 Keychain service 与旧数据无共享；若回滚后需要彻底清理，应由后续受控迁移显式删除，不在回滚中静默移除用户钥匙串数据。

## 残余风险

- Apple 真实认证、2FA 与安装仍需要脱敏测试账号和真实设备手工验证。
- Keychain 权限、锁定状态与系统提示在不同 macOS 环境可能不同，build/static 不能替代实际交互。
- 本地 ad-hoc/无签名 Debug 构建没有稳定的发布者身份，重新构建后仍可能出现一次 macOS 钥匙串授权；彻底消除跨版本重复授权依赖 Developer ID 签名与 notarization，继续由 `ISSUE-20260808-003` 跟踪。
