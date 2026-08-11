# ISSUE-20260811-002：iOS 第三方 IPA 安装与恢复日志真机回归待验证

## 优先级与状态

- 优先级：P0
- 状态：Open
- 关联：`FR-036`、`DES-022`、`TEST-035`、`T-024`、`CHG-20260811-004`

## 背景

用户报告第三方 IPA 安装进行到中途后 AltForge 退出，随后打开“我的 App”持续退出，应用内错误日志为空。Simulator 系统报告已把重复 UI 崩溃定位到设置页的 `willDisplay` 动态改色回调；该回调已经移除，跨 Core Data context 的错误关联和异常退出恢复记录也已加固。

Simulator 不能执行 Apple 账号团队签名、provisioning、设备发送或 installation proxy，因此不能据此确认第三方 IPA 已经成功安装。当前连接的真机处于锁定状态，本次没有读取账号、设备标识、证书、profile 或 IPA 路径，也没有继续重试认证。

## 完成条件

1. 使用脱敏测试 Apple ID 和已解锁真机，从文件导入一个结构有效且来源可信的第三方 IPA。
2. 覆盖 USB 和 Wi-Fi 中至少一种安装路径，记录签名、发送、安装完成及“我的 App”展示结果，不记录凭据、UDID、Team ID、证书或本地路径。
3. 覆盖可控失败：断开 Server 或设备连接，确认应用不退出、错误日志显示失败标题、错误域/代码、诊断编号、最后阶段、USB/Wi-Fi 类别、相对耗时轨迹和可操作建议；复制报告不出现账号、UDID、团队/Server ID、证书/profile 或路径。
4. 在 operation 进行时受控终止测试构建并重新启动，确认只出现一条有界脱敏恢复日志且同一记录不会重复出现。
5. 验证失败后没有半安装 App、遗留备份、无限进度、重复队列或未释放的临时文件；重试可以正常开始。

## 回滚与风险

恢复记录使用独立 UserDefaults key，不改变数据库 schema、Server Protocol 或签名实现。若设备回归发现误报，可以只撤回恢复日志入口，保留已确认的 UI 崩溃和 Core Data context 修复。设备验证完成前，不覆盖现有 Release，也不把 `TEST-035` 标为 Automated 或完成。
