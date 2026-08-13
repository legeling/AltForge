# ISSUE-20260811-002：iOS 第三方 IPA 安装与恢复日志真机回归待验证

## 优先级与状态

- 优先级：P0
- 状态：Open
- 关联：`FR-036`、`DES-022`、`TEST-035`、`T-024`、`CHG-20260811-004`

## 背景

用户报告第三方 IPA 安装进行到中途后 AltForge 退出，随后打开“我的 App”持续退出，应用内错误日志为空。首轮替换构建真机复测仍可复现，并同时暴露浅色设置页固定白字不可读。第二轮代码复核除已移除的 `willDisplay` 动态改色回调外，又确认第三方 IPA completion 的无结果 `preconditionFailure`、不可信 plist 类型访问以及 UserDefaults 落盘时机都可能让进程在写入 `LoggedError` 前终止；对应修复正在验证。

2026-08-11 19:49 的两份 build 11 真机报告进一步确认“我的 App”持续退出是独立的 UIKit assertion：`viewIsAppearing` 在 `reloadData()` 后立即对动态 no-updates section 调用 `reconfigureItems(at:)`，安装失败后的数据源状态使 index path 失效。该路径已改为只更新可见 cell；这也解释了为什么应用内日志只有 interrupted operation，而没有 UIKit 崩溃根因。

Simulator 不能执行 Apple 账号团队签名、provisioning、设备发送或 installation proxy，因此不能据此确认第三方 IPA 已经成功安装。首轮 Release 已通过 AltForge Server 写入配对真机，但它不包含第二轮修复；验证过程中不得记录账号、设备标识、证书、profile 或 IPA 路径。

2026-08-12 的 build 15 真机复测已通过“我的 App”页面，但同一第三方 IPA 在签名阶段触发 `EXC_BAD_ACCESS / SIGSEGV`。脱敏系统报告把首个业务栈定位到 `ldid::Allocate`：未映射 CPU type 没有架构名称，空指针被隐式转换为 `std::string`。结合 IPA 类型，缺失映射最符合 Apple Watch `arm64_32`；本地补丁已补齐该 CPU type，并让其他未知 CPU type 返回可捕获错误。最小 watchOS Mach-O 签名回归和完整 iOS Release build 已通过，但同一 IPA 的真机安装仍未完成，因此 issue 保持 Open。

build 17 已能把同一微信 IPA 安装到设备且不再退出，证明签名崩溃路径已经跨过；但 AltForge 内的进度仍不结束，退出后“我的 App”没有写入该应用。根因是 macOS Server 同时从 KVO progress 和 device completion 两条路径向同一连接发送 framed response，terminal `1.0` 可能与在途 progress 竞争而丢失。当前修复将两类响应串行化，并记录最新安装百分比；只有 build 18 真机确认进度结束且重启后应用仍在“我的 App”，本 issue 才能关闭。

## 上游证据

最后核对：2026-08-11。

- [AltStore #1642](https://github.com/altstoreio/AltStore/issues/1642) 已于 2025-08-15关闭，报告 iOS 26 安装 IPA 时把 `NSNumber` 当作字符串调用 `componentsSeparatedByString:`；该证据与本地“不可信 plist 可选字段必须先做类型检查”的修复路径直接对应。
- [AltStore #1674](https://github.com/altstoreio/AltStore/issues/1674) 仍为 Open，报告 AltStore Classic 在 iOS 26.1 安装 IPA 时退出，最后更新 2026-04-24。
- [AltStore #1010](https://github.com/altstoreio/AltStore/issues/1010) 仍为 Open，报告失败 IPA 既未清理也未显示在 UI 中，最后更新 2023-08-02。

上游状态不替代本地真机回归；本 issue 只有满足下述失败可见性、恢复幂等性和资源清理条件后才能关闭。

完整主题报告见 [`upstream/topics/02-ipa-signing-and-packaging.md`](upstream/topics/02-ipa-signing-and-packaging.md) 与 [`upstream/topics/08-ios-runtime-ui-and-localization.md`](upstream/topics/08-ios-runtime-ui-and-localization.md)。

## 完成条件

1. 使用脱敏测试 Apple ID 和已解锁真机，从文件导入一个结构有效且来源可信的第三方 IPA。
2. 覆盖 USB 和 Wi-Fi 中至少一种安装路径，记录签名、发送、安装完成及“我的 App”展示结果，不记录凭据、UDID、Team ID、证书或本地路径。
3. 覆盖可控失败：断开 Server 或设备连接，确认应用不退出、错误日志显示失败标题、错误域/代码、诊断编号、最后阶段、USB/Wi-Fi 类别、相对耗时轨迹和可操作建议；复制报告不出现账号、UDID、团队/Server ID、证书/profile 或路径。
4. 在 operation 进行时受控终止测试构建并重新启动，确认只出现一条有界脱敏恢复日志且同一记录不会重复出现。
5. 验证失败后没有半安装 App、遗留备份、无限进度、重复队列或未释放的临时文件；重试可以正常开始。
6. 用畸形可选 plist 字段 fixture 和“operation 无结果结束”fixture 验证两条路径都返回普通错误而不终止进程；浅色与深色模式下设置主页、主题、应用图标、许可证、刷新记录、错误日志、兼容账号和认证页面所有正文均可读，应用图标切换后勾选立即更新。
7. 安装失败后连续进入“我的 App”至少 10 次，覆盖 0/1 个 no-updates item 与标签切换动画；不得出现 `reconfigureItems` assertion，系统 crash report 数量不得增加。
8. 安装成功时确认 Server 的 progress/terminal response 串行且 terminal 只发送一次；设备主屏幕出现应用后，客户端进度必须结束，重启 AltForge 后“我的 App”仍存在对应记录并可刷新。
9. 导入含 App Extensions 的 IPA 时显示数量、有界名称列表和双语风险说明；分别选择剔除与保留签名，确认只影响工作副本，选择与实际 profile/signing 对象一致。
10. 从 IPA 导入到安装结束持续显示 0...100% 总进度、App 名称、当前阶段和有界详情；深浅色、中英文和 Dynamic Type 下不遮挡“我的 App”内容，完成/失败/取消后清理 observation 并恢复导入按钮。

## 回滚与风险

恢复记录使用原子 JSON journal 和固定两条 session checkpoint，不改变数据库 schema、Server Protocol 或签名流程。若设备回归发现误报，可以只撤回 session checkpoint，保留 operation journal、输入类型验证和 Core Data context 修复。设备验证完成前，替换构建只保持 Draft，不公开发布，也不把 `TEST-035` 标为 Automated 或完成。
