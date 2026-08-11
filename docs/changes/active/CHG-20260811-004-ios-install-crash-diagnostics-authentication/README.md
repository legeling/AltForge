# CHG-20260811-004：修复 iOS 安装中断崩溃与认证说明

## 背景

用户在认证或导入第三方 IPA 后切换到“我的 App”时，应用会直接退出，应用内错误日志为空；认证页仍保留旧版整页青色视觉、过大的垂直留白和不够准确的工作原理说明。

本机 Simulator 的系统崩溃报告已经把重复崩溃定位到 `SettingsViewController.tableView(_:willDisplay:forRowAt:)`：设置页为动态改色递归遍历 cell 层级时触发未识别 selector。该异常发生在 AppManager 操作链之外，所以原有 `LoggedError` 不会记录它。

## 范围

- 删除设置 cell 的高风险递归改色回调，改用系统语义色和已有 outlet 配色。
- 安装/刷新操作开始时只持久化有界、脱敏的操作摘要，正常完成后删除；下次启动发现未完成摘要时补写一条可见错误日志。
- 为每次操作记录随机客户端诊断编号和最多 16 个关键阶段；失败日志持久化最后阶段与相对耗时轨迹，并可从错误菜单一次复制诊断报告。
- 错误日志跨 Core Data context 关联对象时只使用永久 object ID 和 `existingObject(with:)`，否则退化为值快照。
- StoreApp 安装成功后安全解析目标 context 中的关系，不对 temporary object ID 调用 `object(with:)`。
- 认证页改用系统分组背景、语义文字色和品牌强调色，收紧说明区域间距；登录说明明确 Apple developer team 会从账号返回的团队中自动选择并在设置中显示。
- “工作原理”同时说明 USB/Wi-Fi、Apple 团队签名、免费账号七天有效期和刷新条件。

## 映射

- Requirement：`FR-036`
- Design：`DES-022`
- Verification：`TEST-035`
- Task：`T-024`

## 复杂度与资源

操作恢复记录最多保留 20 条，每条最多 16 个事件、detail 最多 120 字符。append 为 `O(k + e)`，`k <= 20`、`e <= 16`；持久化数据只包含操作类型、应用名、bundle ID、客户端诊断编号、时间、阶段、USB/Wi-Fi/本机类别和团队类别，不包含 Apple ID、密码、验证码、团队 ID、Server 名称/ID、证书/profile、设备 ID 或 IPA/下载路径。错误记录仍通过单个 Core Data background context 写入，不修改 schema/Server Protocol，不新增网络请求、端口、长期进程或无界缓存。

## 验证计划

- 解析本机 `.ips`，确认崩溃调用栈来自设置 cell 的 `willDisplay` 回调。
- repository contract 覆盖危险回调移除、temporary object ID 保护、恢复记录上限、认证品牌和中英文说明。
- repository contract 覆盖 20/16/120 上限、诊断字段、关键阶段、复制报告和敏感字段禁止项。
- 构建 iOS Simulator target，并在相同 Simulator 反复执行“设置 -> 我的 App -> 设置”切换。
- 模拟遗留未完成操作记录后重启，确认错误日志出现一次且记录被消费。
- 第三方 IPA 的真实签名、设备发送与安装仍需在解锁真机上验证；Simulator 只能验证 UI、数据库和恢复路径。

## 已执行验证

- 2026-08-11：检查本机 6 份重复系统崩溃报告，最新一份的 `lastExceptionBacktrace` 均指向 `SettingsViewController.tableView(_:willDisplay:forRowAt:)` 第 752 行，并位于 `UITabBarController` 切换布局阶段。
- 2026-08-11：`ruby Scripts/test_repository_contract.rb` 通过，覆盖危险回调移除、operation record 上限、temporary object ID 防护、恢复入口、团队选择顺序以及英文/简体中文认证文案。
- 2026-08-11：两个 string catalog 通过 JSON 解析，Authentication storyboard 通过 `xmllint --noout`。
- 2026-08-11：AltStore Debug 在 generic iOS Simulator、关闭签名的构建通过；同一 iOS 26.5 Simulator 连续执行 6 轮“设置 -> 我的 App”往返后进程 PID 保持不变，未生成新的系统崩溃报告。
- 2026-08-11：工作原理页面在简体中文 Simulator 中展示四步完整说明。登录页视觉和恢复日志的完整运行时路径仍需连通 AltForge Server；第三方 IPA 必须在解锁真机上验证。
- 2026-08-11：新增有界诊断链后 repository contract、全部 iOS string catalog JSON、相关 storyboard XML、15 个受影响 Swift 文件的前端语法解析和 `git diff --check` 通过。新的完整 `xcodebuild` 尝试被执行沙箱阻止访问 CoreSimulatorService/Xcode 用户缓存，未把该次尝试记为构建通过；构建临时目录已清理。

## 当前状态

实现和既有 Simulator 崩溃回归已经通过，新增诊断链仍需完成本 change 的命令行 build 与 runtime fixture，change 保持 active。真实第三方 IPA 签名、发送、安装及失败日志可见性由 `ISSUE-20260811-002` 跟踪；在该 P0 设备回归完成前不宣称安装链路已经完全修复，也不触发 Release。

## 回滚

恢复设置回调、AppManager 原错误关联方式和旧认证资源即可。恢复记录使用独立 UserDefaults key，回滚版本会忽略它；不改变 Core Data schema、bundle ID、签名协议或 Server Protocol。
