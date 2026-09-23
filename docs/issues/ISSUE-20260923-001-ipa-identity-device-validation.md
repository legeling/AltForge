# ISSUE-20260923-001: IPA 身份编辑真机验收

- Priority: P1
- Status: Open; implementation published in v2.5.1, physical-device acceptance pending
- Related: `FR-047`, `DES-032`, `TEST-046`, `T-045`, `CHG-20260923-001`

## 风险

CI 已验证 iOS 模拟器上的临时 `.app` 信息改写、扩展 ID、本地化名称和缓存替换，但没有用真实设备、Apple 开发者账号和可合法测试的 IPA 验证并排安装、主屏幕名称、App ID/profile 注册和后续刷新。改包名还可能影响第三方 App 的登录、共享数据、Keychain 和推送，这些能力不能从 plist 测试推断。

## 验收

1. 在脱敏真机环境中，直接安装一份 IPA；再改为不同包名和名称安装第二份，确认两份均能打开、出现在“我的 App”，并能分别刷新。
2. 保持包名不变给其中一份已管理应用改名，确认主屏幕、“我的 App”和下次刷新后的名称一致，另一份不受影响。
3. 覆盖带扩展 IPA、离线/旧版 Server、安装中锁屏后恢复，以及改名重装失败时旧缓存和已安装 App 保留。
4. 记录 iOS、macOS/Windows Server 版本和脱敏诊断；不要提交 IPA、Apple ID、设备标识、证书或 profile。

完成上述验收后再关闭此 Issue。回滚时保持旧管理记录和缓存，停用编辑入口即可；已安装的不同包名副本需要用户自行管理，不自动删除。
