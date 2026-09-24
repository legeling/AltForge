# ISSUE-20260923-001: IPA 身份编辑真机验收

- Priority: P1
- Status: Open; identity editing published in v2.5.1 and icon editing in v2.6.0, physical-device acceptance pending
- Related: `FR-047`, `DES-032`, `TEST-046`, `T-045`, `CHG-20260923-001`; `FR-049`, `DES-034`, `TEST-048`, `T-047`, `CHG-20260924-001`

## 风险

CI 已验证 iOS 模拟器上的临时 `.app` 信息改写、扩展 ID、本地化名称和缓存替换，但没有用真实设备、Apple 开发者账号和可合法测试的 IPA 验证并排安装、主屏幕名称、App ID/profile 注册和后续刷新。改包名还可能影响第三方 App 的登录、共享数据、Keychain 和推送，这些能力不能从 plist 测试推断。

v2.6.0 增加 macOS 与 iOS 导入时自选并裁切图标，仍需在真机核对主屏幕图标、刷新后保留图标，以及 iOS 锁屏/切后台后的安装记录。模拟器的 plist/图像测试不能证明 SpringBoard 的实际选择结果。

## 验收

1. 在脱敏真机环境中，直接安装一份 IPA；再改为不同包名和名称安装第二份，确认两份均能打开、出现在“我的 App”，并能分别刷新。
2. 保持包名不变给其中一份已管理应用改名，确认主屏幕、“我的 App”和下次刷新后的名称一致，另一份不受影响。
3. 覆盖带扩展 IPA、离线/旧版 Server、安装中锁屏后恢复，以及改名重装失败时旧缓存和已安装 App 保留。
4. 分别从 macOS PNG/JPEG 文件和 iOS 照片选择非正方形图片并裁切，确认两份不同包名的主屏幕图标、AltForge 列表图标及刷新后的图标各自正确；核对取消与非法图像后原 IPA 和已安装 App 不受影响。
5. 记录 iOS、macOS/Windows Server 版本和脱敏诊断；不要提交 IPA、Apple ID、设备标识、证书或 profile。

完成上述验收后再关闭此 Issue。回滚时保持旧管理记录和缓存，停用编辑入口即可；已安装的不同包名副本需要用户自行管理，不自动删除。
