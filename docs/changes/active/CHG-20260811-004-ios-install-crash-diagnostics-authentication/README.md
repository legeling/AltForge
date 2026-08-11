# CHG-20260811-004：修复 iOS 安装中断崩溃与认证说明

## 背景

用户在认证或导入第三方 IPA 后切换到“我的 App”时，应用会直接退出，应用内错误日志为空；认证页仍保留旧版整页青色视觉、过大的垂直留白和不够准确的工作原理说明。

首个替换构建完成真机试用后，用户再次报告两个 P0 回归：浅色模式下设置页仍有固定白色文字而不可读；第三方 IPA 安装中仍会退出，重新进入“我的 App”继续退出，而且错误日志为空。代码复核确认第三方 IPA 完成回调在“无结果且无错误”时会触发 `Result` convenience initializer 的 `preconditionFailure`，AltSign 对不可信 `Info.plist` 的字符串、字典、数组元素也存在未完整验证类型就调用方法或下标的异常路径。

本机 Simulator 的系统崩溃报告已经把重复崩溃定位到 `SettingsViewController.tableView(_:willDisplay:forRowAt:)`：设置页为动态改色递归遍历 cell 层级时触发未识别 selector。该异常发生在 AppManager 操作链之外，所以原有 `LoggedError` 不会记录它。

第二轮真机的 6 份系统报告中，最新两份 19:49 崩溃均为 `MyAppsViewController.viewIsAppearing(_:) -> update() -> UICollectionView.reconfigureItems(at:)` 触发 UIKit 内部断言和 `SIGABRT`。页面先 `reloadData()`、随后立即用动态 no-updates section 的旧 index path 执行 reconfigure；安装失败改变 fetched-results 状态后，该 index path 不再稳定。应用内错误日志无法捕获 Objective-C 断言，因此恢复记录只能说明进程退出时的最后操作阶段，不能替代系统 crash report。

## 范围

- 删除设置 cell 的高风险递归改色回调，改用系统语义色和已有 outlet 配色。
- 把设置 Storyboard 中残留的固定白色文字和 tint 改成 `label`/`secondaryLabel` 系统语义色；认证导航栏也使用动态背景、标题和品牌 tint，不在运行时递归遍历 UIKit 私有层级。
- 第三方 IPA 完成回调不再通过可触发 `preconditionFailure` 的可选值构造 `Result`；缺失结果转成可记录、可展示的普通安装错误。
- AltSign 在读取 IPA `Info.plist` 的名称、bundle ID、版本、最低系统、设备族和图标元数据前验证实际 plist 类型，畸形可选字段降级或忽略而不是触发 Objective-C 异常。
- “我的 App”出现时不再在 `reloadData()` 后 reconfigure 动态 index path；更新状态先计算再 reload，后续只直接更新已经可见的 no-updates cell，不改变 collection structure。
- 验证阶段缺失 prepared app 时返回 `invalidApp`，不再泄漏无上下文的 `invalidParameters (1008)`。
- 发布 IPA 不再携带维护者机器的静态设备或 Server 标识；AltForge Server 在针对目标设备签名时注入运行所需值，发布校验会拒绝包含这两项的产物。
- 同版本真机阻断修复通过 tag CI 重建全部平台资产；现有公开 Release 原位覆盖 IPA、桌面端、metadata 和 checksum 后重新下载校验，不删除 Release，也不允许只替换 IPA。
- Release Apple job 动态创建并清理任务专属 Simulator，不再依赖 hosted runner 是否预置名为 iPhone 17 Pro 的 device；缺少 runtime/device type 时在测试前明确失败。
- 安装/刷新操作开始时只持久化有界、脱敏的操作摘要，正常完成后删除；下次启动发现未完成摘要时补写一条可见错误日志。
- pending operation 使用 Application Support 下的原子 JSON journal，UserDefaults 仅作为存储不可用时的兼容 fallback；前台 session 额外保留一条 current/interrupted checkpoint，只有没有更具体的 pending operation 时才生成一条意外退出日志。
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

操作恢复记录最多保留 20 条，每条最多 16 个事件、detail 最多 120 字符。append 为 `O(k + e)`，`k <= 20`、`e <= 16`；每次更新只原子重写一份上限为常数的小型 JSON。前台 session 只保留 current 与 interrupted 两条固定大小记录。持久化数据只包含操作类型、应用名、bundle ID、客户端诊断编号、时间、预定义 UI checkpoint、USB/Wi-Fi/本机类别和团队类别，不包含 Apple ID、密码、验证码、团队 ID、Server 名称/ID、证书/profile、设备 ID 或 IPA/下载路径。错误记录仍通过单个 Core Data background context 写入，不修改 schema/Server Protocol，不新增网络请求、端口、长期进程或无界缓存。

## 验证计划

- 解析本机 `.ips`，确认崩溃调用栈来自设置 cell 的 `willDisplay` 回调。
- repository contract 覆盖危险回调移除、temporary object ID 保护、恢复记录上限、认证品牌和中英文说明。
- repository contract 覆盖 20/16/120 上限、诊断字段、关键阶段、复制报告和敏感字段禁止项。
- 构建 iOS Simulator target，并在相同 Simulator 反复执行“设置 -> 我的 App -> 设置”切换。
- 模拟遗留未完成操作记录后重启，确认错误日志出现一次且记录被消费。
- 构造包含错误 plist 类型的最小 `.app` fixture，确认 `ALTApplication` 不抛异常且对可选元数据安全降级。
- 让第三方 IPA 外层 operation 无结果结束，确认返回普通失败、不会触发 precondition，且下一次启动能从原子 journal 或前台 checkpoint 恢复一条日志。
- 在浅色与深色模式检查设置、认证和错误日志，不得存在固定白色文字覆盖浅色系统背景。
- 在 no-updates section 为 0/1 item、安装失败刚改变 fetched results、标签切换动画进行中三种状态重复进入“我的 App”，不得调用 stale index path reconfigure 或产生 UIKit assertion。
- 第三方 IPA 的真实签名、设备发送与安装仍需在解锁真机上验证；Simulator 只能验证 UI、数据库和恢复路径。

## 已执行验证

- 2026-08-11：检查本机 6 份重复系统崩溃报告，最新一份的 `lastExceptionBacktrace` 均指向 `SettingsViewController.tableView(_:willDisplay:forRowAt:)` 第 752 行，并位于 `UITabBarController` 切换布局阶段。
- 2026-08-11：`ruby Scripts/test_repository_contract.rb` 通过，覆盖危险回调移除、operation record 上限、temporary object ID 防护、恢复入口、团队选择顺序以及英文/简体中文认证文案。
- 2026-08-11：两个 string catalog 通过 JSON 解析，Authentication storyboard 通过 `xmllint --noout`。
- 2026-08-11：AltStore Debug 在 generic iOS Simulator、关闭签名的构建通过；同一 iOS 26.5 Simulator 连续执行 6 轮“设置 -> 我的 App”往返后进程 PID 保持不变，未生成新的系统崩溃报告。
- 2026-08-11：工作原理页面在简体中文 Simulator 中展示四步完整说明。登录页视觉和恢复日志的完整运行时路径仍需连通 AltForge Server；第三方 IPA 必须在解锁真机上验证。
- 2026-08-11：新增有界诊断链后 repository contract、全部 iOS string catalog JSON、相关 storyboard XML、15 个受影响 Swift 文件的前端语法解析和 `git diff --check` 通过。新的完整 `xcodebuild` 尝试被执行沙箱阻止访问 CoreSimulatorService/Xcode 用户缓存，未把该次尝试记为构建通过；构建临时目录已清理。
- 2026-08-11：第二轮真机反馈确认首个替换构建仍存在浅色模式不可读、第三方 IPA 退出和空日志，先前“已修复”的结论撤回；定位到固定白色 Storyboard 资源、无结果 `preconditionFailure` 和不可信 plist 类型访问三个代码风险。已新增语义色静态门禁、畸形 plist XCTest fixture、原子 operation journal 与前台 checkpoint；完整 build 和真机复测仍待完成。
- 2026-08-11：使用隔离的 DerivedData 和本地依赖缓存完成无签名 `Release-iphoneos` generic device build 与 `Release` macOS `arm64/x86_64` build；本地 IPA 结构、bundle identifier、版本和 executable 检查通过。当前代码的第三方 IPA 真机安装与恢复日志仍未验证，不能仅凭构建结果宣称 P0 已关闭。
- 2026-08-11：从配对真机只读导出 19:49:00 与 19:49:02 两份 build 11 系统报告；两份 `lastExceptionBacktrace` 都定位到 `MyAppsViewController.update()` 的 `reconfigureItems(at:)`，异常类型为 UIKit assertion / `SIGABRT`。已移除该结构变更路径并加入 repository contract；新改动仍需重新完成 Release build 和真机往返验证。
- 2026-08-11：移除 stale index-path reconfigure 并收敛 prepared-app 错误后，repository/release metadata/version contract、两份 Swift frontend parse、`git diff --check` 与完整无签名 `Release-iphoneos` generic device build 通过。build 11 真机报告已复制到任务临时目录分析，未提交设备标识或原始报告。
- 2026-08-11：首次同 tag CI 因 hosted runner 没有预创建匹配名称的 Simulator 在测试前失败，公开资产未改动；取消剩余 job 后改为动态创建/清理 Simulator。第二次 run `31492541706` 的四个 jobs 全部通过，公开九项资产原位覆盖并重新下载校验；Release IPA 为 `2.4.0 (13)`，真机回归待用户执行。

## 当前状态

第二轮修复正在验证，change 保持 active。真实第三方 IPA 签名、发送、安装及失败日志可见性由 `ISSUE-20260811-002` 跟踪；在浅色真机视觉、畸形 fixture、无结果完成、意外终止恢复和第三方 IPA 真机回归完成前，不宣称安装链路已经修复，也不公开新的替换 Release。经维护者明确授权，可先由 tag workflow 生成 Draft 和校验和供设备验证。

## 回滚

恢复设置资源、AppManager 原错误关联方式和旧认证资源即可。回滚版本会忽略 Application Support 中的诊断 JSON；不改变 Core Data schema、bundle ID、签名协议或 Server Protocol。AltSign 回滚必须先恢复 nested repo commit，再更新 superproject gitlink，不能留下 dirty submodule。
