# CHG-20260811-004：修复 iOS 安装中断崩溃与认证说明

## 背景

用户在认证或导入第三方 IPA 后切换到“我的 App”时，应用会直接退出，应用内错误日志为空；认证页仍保留旧版整页青色视觉、过大的垂直留白和不够准确的工作原理说明。

首个替换构建完成真机试用后，用户再次报告两个 P0 回归：浅色模式下设置页仍有固定白色文字而不可读；第三方 IPA 安装中仍会退出，重新进入“我的 App”继续退出，而且错误日志为空。代码复核确认第三方 IPA 完成回调在“无结果且无错误”时会触发 `Result` convenience initializer 的 `preconditionFailure`，AltSign 对不可信 `Info.plist` 的字符串、字典、数组元素也存在未完整验证类型就调用方法或下标的异常路径。

本机 Simulator 的系统崩溃报告已经把重复崩溃定位到 `SettingsViewController.tableView(_:willDisplay:forRowAt:)`：设置页为动态改色递归遍历 cell 层级时触发未识别 selector。该异常发生在 AppManager 操作链之外，所以原有 `LoggedError` 不会记录它。

第二轮真机的 6 份系统报告中，最新两份 19:49 崩溃均为 `MyAppsViewController.viewIsAppearing(_:) -> update() -> UICollectionView.reconfigureItems(at:)` 触发 UIKit 内部断言和 `SIGABRT`。页面先 `reloadData()`、随后立即用动态 no-updates section 的旧 index path 执行 reconfigure；安装失败改变 fetched-results 状态后，该 index path 不再稳定。应用内错误日志无法捕获 Objective-C 断言，因此恢复记录只能说明进程退出时的最后操作阶段，不能替代系统 crash report。

build 13 真机报告确认移除 reconfigure 后仍有第二个独立 UIKit 断言：`MyAppsViewController.referenceSizeForFooterInSection` 为测量已安装应用 footer，直接调用数据源方法并从 collection view 复用池 dequeue supplementary view；该对象并未作为本次 UIKit 请求的结果返回，新版 UIKit 在 `_updateVisibleCellsNow` 检查复用池时以 `SIGABRT` 退出。修复改用独立 XIB prototype 测量，真实 data source callback 才允许 dequeue。继续核对上游后发现 `AppIDsViewController.referenceSizeForHeaderInSection` 仍保留完全相同的越权 dequeue，已同步移植上游 `832e9fab`，避免用户从“我的 App”进入 App ID 列表后再次触发同类断言。

build 15 已不再在“我的 App”退出，但同一第三方 IPA 在“正在签名 App”阶段中断。对应真机系统报告为 `EXC_BAD_ACCESS / SIGSEGV`，触发线程从 `_platform_strlen` 进入 `std::string(char const *)` 和 `ldid::Allocate`。报告可以确认 ldid 遇到了未映射 CPU type，并把 progress 架构名称留为 `NULL`，随后隐式构造 `std::string` 而崩溃；结合大型 iOS App 常见的 Watch 嵌套程序，缺失映射最符合 Apple Watch `arm64_32`，但仍需用同一 IPA 真机复测确认。设备安装实际尚未开始。

build 16 补齐 `arm64_32` 后，同一微信 IPA 仍在“正在签名 App”退出，说明前一修复只消除了第一个 native fault。继续审计真实签名调用链发现 `ALTSigner` 的 entitlement 回调直接 `return entitlements.UTF8String`：只要 ldid 发现未进入 provisioning map 的嵌套 bundle，Objective-C `nil` 就会再次以 `NULL` 构造 `std::string`，C++ `catch` 无法捕获由此产生的 `SIGSEGV`。同时 `ALTProgress` 丢弃了 ldid 已提供的 bundle、Mach-O 和架构名称，因此恢复日志只能停在笼统阶段。上游 [AltStore #229](https://github.com/altstoreio/AltStore/issues/229) 明确 Apple Watch companion 重签仍未支持；Classic 路径应从工作副本移除 `Watch/`，而不是尝试用 iPhone 主 App entitlement 签名。

build 17 已在真机完成微信安装且不再退出，但设备主屏幕出现应用后，iOS 端仍保持安装进度，退出 AltForge 后“我的 App”没有该应用。代码审计确认 AltForge Server 的 KVO progress 和最终 completion 会从两条异步路径向同一 `Connection` 写响应；若设备完成时仍有 progress 在途，最终 `1.0` 响应会与其竞争，客户端永远等不到 terminal response，因而不会设置 `refreshedDate`、结束 operation 或保存 `InstalledApp`。修复必须在 Server 使用单一串行发送状态机，而不是在客户端用超时猜测设备是否已安装。

## 范围

- 删除设置 cell 的高风险递归改色回调，改用系统语义色和已有 outlet 配色。
- 把设置 Storyboard 中残留的固定白色文字和 tint 改成 `label`/`secondaryLabel` 系统语义色；认证导航栏也使用动态背景、标题和品牌 tint，不在运行时递归遍历 UIKit 私有层级。
- 设置主页、主题、应用图标、许可证、刷新记录、错误日志和兼容账号页面统一使用系统语义背景、前景、分隔线及滚动条；移除强制深色状态/导航栏，应用图标切换完成后再刷新主题色勾选，并统一使用简体中文术语“侧载”。
- 官方 AltForge source/app/news 及应用详情统一通过动态 `effectiveTintColor` 解析当前主题，不再直接显示 Release metadata 的旧红/绿色；可复用 banner、资讯、来源 header 和详情页监听主题变化。权限确认、补丁、添加来源及通用详情页面改用系统语义色和当前主题，红/绿/黄仅保留给失败、删除、成功、有效期与警告状态。
- “我的 App”和 App ID 卡片的简体中文到期标签使用完整的“剩余有效期”，不再把英文分段布局翻译成缺少谓语的“于”；浏览页明确只聚合第三方 source 的新增和更新、类别与精选 App，官方 source-only 时以可操作空状态替代三个空标题。
- 第三方 IPA 完成回调不再通过可触发 `preconditionFailure` 的可选值构造 `Result`；缺失结果转成可记录、可展示的普通安装错误。
- AltSign 在读取 IPA `Info.plist` 的名称、bundle ID、版本、最低系统、设备族和图标元数据前验证实际 plist 类型，畸形可选字段降级或忽略而不是触发 Objective-C 异常。
- ldid 识别 Apple Watch `arm64_32` CPU type，使用与 ARM slice 一致的对齐并提供非空 progress 名称；其他未知 CPU type 在写回前抛出 `ALTSigner` 可捕获的错误，不再产生空指针崩溃。
- `ALTSigner` 对文件系统路径、嵌套 bundle UTF-8 和 prepared entitlement 逐项判空，失败转 `runtime_error`；不再从 Objective-C `nil` 构造 `std::string`。
- iPhone 重签副本在修改 Info.plist 前移除上游未支持的顶层 `Watch/` companion，原始 IPA 不变；签名器仍能安全识别包内其他 `arm64_32` fixture。
- 把 ldid bundle/Mach-O/architecture checkpoint 以最多四段相对路径写入当前签名事件；连续 checkpoint 原位替换，保留既有 16 阶段历史，拒绝控制字符、父目录和绝对路径前缀。
- AltForge Server 将安装 progress 与 terminal success/failure 收敛到单一串行 response coordinator；普通进度允许合并，terminal 必须覆盖尚未发送的进度并等待在途写入结束后唯一发送，禁止并发写同一 framed connection。
- iOS 安装端验证 progress 为有限非负数，以 `>= 1.0` 识别完成，并把最新连接类别与百分比原位更新到有界诊断轨迹，避免安装回调丢失时仍只显示笼统阶段。
- “我的 App”在手工导入 IPA 时展示固定高度状态带，持续显示 App 名称、总百分比、当前阶段和最新有界 detail；安装结束后释放 KVO 并恢复布局/导入状态。
- 检测到 App Extensions 时列出数量和最多四个名称，要求用户在“剔除扩展（推荐）”与“保留并签名扩展”之间明确选择；双语说明主要功能、扩展功能与免费账号限额取舍。
- Apple Release CI 使用 watchOS SDK 生成最小 `arm64_32` 可执行文件完成真实 ldid 签名，并验证未知 CPU type 安全失败；fixture 和产物使用任务临时目录且退出时清理。
- “我的 App”出现时不再在 `reloadData()` 后 reconfigure 动态 index path；更新状态先计算再 reload，后续只直接更新已经可见的 no-updates cell，不改变 collection structure。
- App IDs footer 从独立 XIB 注册和渲染；布局测量实例化独立 prototype，不得在 flow-layout size delegate 中调用 collection-view data source 方法或 dequeue reusable view。
- App ID 列表 header 同样从独立 XIB 注册和测量，覆盖上游已经确认的第二处 iOS 18 collection-view assertion。
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
- 全量复核 App、Widget、Core、Backup 与 Server 的简体中文，修正点赞、激活状态、软件源、授权项、刷新状态、App ID 限额、遗留品牌及中文语序等机器直译；仓库维护的 13 份 string catalog 由静态门禁检查非空翻译和格式占位符一致性。
- 浏览内容为空时切换到不生成 supplementary header 的专用布局，避免“新增和更新/类别/精选”空分区标题透过空状态；内容重新出现时恢复完整聚合布局。
- 浏览空状态的“管理软件源”使用至少 44pt 的系统按钮并回到软件源列表根页面；空状态图标、按钮和背景监听主题通知即时更新，无障碍朗读忽略装饰图标并把标题标记为 heading。
- 应用图标扩展为九款：标准、珊瑚、冰霜、纸白、霓虹、蓝图以及可选的钛金属、光学玻璃、陶瓷珐琅；图标切换不再锁死并 reload 整个列表，而是即时显示目标行进度，完成后只重配旧/新两行并提供成功或失败触感反馈。

## 映射

- Requirement：`FR-036`
- Design：`DES-022`
- Verification：`TEST-035`
- Task：`T-024`
- Upstream review：[`UPSTREAM-REVIEW.md`](UPSTREAM-REVIEW.md)

## 复杂度与资源

操作恢复记录最多保留 20 条，每条最多 16 个事件、detail 最多 120 字符。append/replace 为 `O(k + e)`，`k <= 20`、`e <= 16`；签名与设备安装的连续 checkpoint 原位替换，只原子重写一份上限为常数的小型 JSON。前台 session 只保留 current 与 interrupted 两条固定大小记录。持久化数据只包含操作类型、应用名、bundle ID、客户端诊断编号、时间、预定义 UI checkpoint、USB/Wi-Fi/本机类别、团队类别、安装百分比，以及清理后的最多四段 bundle 相对路径与 CPU 架构；不包含 Apple ID、密码、验证码、团队 ID、Server 名称/ID、证书/profile、设备 ID 或 IPA/下载绝对路径。Server response coordinator 只保留一个 pending progress、一个 terminal result 和一个在途标记，空间 `O(1)`；progress 高频更新只覆盖 pending 值，不产生无界队列。Watch 检查为 `O(1)` 路径查询，删除成本由 Watch 目录大小线性约束；架构选择为每个 Mach-O slice `O(1)`。错误记录仍通过单个 Core Data background context 写入，不修改 schema/Server Protocol，不新增网络请求、端口、长期进程或无界缓存。

## 验证计划

- 解析本机 `.ips`，确认崩溃调用栈来自设置 cell 的 `willDisplay` 回调。
- repository contract 覆盖危险回调移除、temporary object ID 保护、恢复记录上限、认证品牌和中英文说明。
- repository contract 覆盖 20/16/120 上限、诊断字段、关键阶段、复制报告和敏感字段禁止项。
- 构建 iOS Simulator target，并在相同 Simulator 反复执行“设置 -> 我的 App -> 设置”切换。
- 模拟遗留未完成操作记录后重启，确认错误日志出现一次且记录被消费。
- 构造包含错误 plist 类型的最小 `.app` fixture，确认 `ALTApplication` 不抛异常且对可选元数据安全降级。
- 使用 watchOS SDK 生成最小 `arm64_32` Mach-O，确认 ldid 完成签名并报告正确架构；篡改 CPU type 后确认返回可捕获错误而不是信号崩溃。
- 构造含顶层 `Watch/Companion.app` 的工作副本，确认签名前只删除该副本的 Watch 目录且重复执行幂等；确认绝对输入只留下末四段 bundle/可执行文件/架构，控制字符和父目录不进入日志。
- 静态和 build 门禁确认 entitlement/path 判空、bundle/Mach-O progress handler 以及 Swift 桥接签名均有效；签名 checkpoint 更新不得把认证、准备描述文件等较早阶段挤出 16 事件上限。
- 用可控 connection fixture 交错触发 progress send 与 terminal completion，确认 framed response 不并发、terminal 不丢失且只回调一次；客户端对 `1.0`、大于 `1.0`、NaN 和负数分别完成或安全失败。
- 让第三方 IPA 外层 operation 无结果结束，确认返回普通失败、不会触发 precondition，且下一次启动能从原子 journal 或前台 checkpoint 恢复一条日志。
- 在浅色与深色模式检查设置、认证和错误日志，不得存在固定白色文字覆盖浅色系统背景。
- 在 no-updates section 为 0/1 item、安装失败刚改变 fetched results、标签切换动画进行中三种状态重复进入“我的 App”，不得调用 stale index path reconfigure 或产生 UIKit assertion。
- 静态门禁拒绝 My Apps footer 与 App ID header 的 size delegate 间接 dequeue supplementary view，并检查两者使用独立 prototype 测量。
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
- 2026-08-11：build 13 真机的两份 21:05 系统报告均为 `_UICollectionViewSubviewManager removeAllDequeuedViewsWithEnumerator:` 触发的 UIKit assertion；代码定位到 footer 高度计算期间的越权 dequeue。已移植上游 `a9636a73` 的 iOS 18 修复，用独立 XIB prototype 测量并把 segue 动作移到 controller；repository/release/version contract、Swift parse、XML/JSON 解析和完整无签名 `Release-iphoneos` generic device build 通过，真机复测待执行。
- 2026-08-11：继续核对上游 `classic` 后移植 `832e9fab` 的 App ID header 同类修复，并把两处禁止越权 dequeue 的要求加入 repository contract；repository/release/version contract、Storyboard/XIB XML、string catalog JSON 与完整无签名 `Release-iphoneos` generic device build 通过，真机验证仍待执行。
- 2026-08-12：只读导出 build 15 对应真机系统报告，确认异常为 `EXC_BAD_ACCESS / SIGSEGV`，首个业务栈为 `ldid::Allocate`，并排除当次 Jetsam。补充 `CPU_TYPE_ARM64_32` 架构与未知 CPU 安全失败后，`Scripts/test_ldid_architecture_compatibility.sh` 对真实最小 watchOS `arm64_32` Mach-O 签名及未知 CPU fixture 均通过；repository contract、diff check 与完整无签名 `Release-iphoneos` generic device build 通过。同一微信 IPA 真机安装仍待执行。

- 2026-08-12：build 16 真机反馈确认同一微信 IPA 仍在签名阶段导致进程退出，且旧日志没有签名对象。代码审计定位 `ALTSigner` 第二处 nullable entitlement 到 `std::string` 的信号崩溃路径，并确认上游不支持 Watch companion 重签；已实现工作副本 Watch 移除、所有跨语言字符串判空、脱敏 bundle/架构 checkpoint 和连续签名事件替换。repository contract、ldid architecture compatibility、完整无签名 iOS Simulator build，以及 Watch 移除与签名 detail 脱敏两个定向 XCTest 均通过；真机安装尚未通过。

- 2026-08-12：build 17 真机已完成微信设备安装且没有进程退出，但客户端进度未终止、“我的 App”未保存记录。定位为 Server progress KVO 与 terminal completion 并发写同一 connection 的响应竞争；已实现有界串行 response coordinator、客户端 terminal progress 健壮识别和安装百分比诊断。Repository/release metadata contract、两个 Swift 文件语法解析、macOS AltForge Server Debug build 和 iOS Simulator AltForge Debug build 通过；可控 connection 并发 fixture 与 build 18 真机闭环仍待验证。
- 2026-08-12：手工 IPA 导入新增 0...100% 总进度、App 名称、当前操作阶段和有界详情状态带；含 App Extensions 时显示数量及最多四个名称，并明确提供取消、推荐剔除、保留签名三种选择。Repository/release metadata contract、string catalog JSON、相关 Swift 语法解析、diff check 和完整无签名 iOS Simulator Debug build 通过；含真实 extensions 的双路径签名与设备安装仍待真机验证。
- 2026-08-12：用户反馈设置及应用图标子页仍存在固定白色，撤回此前完整深浅色结论。已把设置主页、主题、应用图标、许可证、刷新记录、错误日志和兼容账号资源迁移到系统语义色，移除白色滚动条/强制深色系统栏，图标变更 completion 后刷新勾选，并统一使用简体中文术语“侧载”。Repository/release metadata contract、控件级固定颜色扫描、三个 storyboard/XIB XML、两个 string catalog JSON、六个相关 Swift 文件语法解析和完整无签名 iOS Simulator Debug build 通过；未启动 Simulator，完整深浅色运行时矩阵仍待执行。
- 2026-08-12：继续审计非主题红/绿后，修复官方 app/source/news 卡片与应用详情直接读取 Release metadata tint 的旁路，并让已加载 banner、资讯、来源 header 和详情在主题通知后重配；权限确认、补丁、添加来源、启动页与通用详情改为系统语义色。Repository/release metadata contract、XML/JSON 解析、`git diff --check` 和完整无签名 Debug iOS Simulator generic build 通过；仅保留删除/失败、成功/有效期和警告语义色，四主题深浅色运行时视觉矩阵仍待执行。
- 2026-08-12：修正“Expires in”分段布局的简体中文为完整“剩余有效期”，同步覆盖“我的 App”、App ID 与无障碍句子；仅有会被浏览过滤的 AltForge 自身时，浏览页以“暂无可浏览的 App”和“管理软件源”替代空的新增/类别/精选标题。Repository/release metadata contract、string catalog JSON、`git diff --check` 和当前 iPhone 17 Pro Simulator Debug build/安装/启动通过；第三方 source 聚合 fixture 待补。
- 2026-08-12：复现浏览空状态与三个空分区标题重叠，改为内容/空状态互斥的 compositional layout，并提高空状态标题及图标在浅色模式下的对比度。Repository/release metadata contract、`git diff --check`、iPhone 17 Pro Simulator Debug build、安装、深浅色截图检查通过；真实第三方 source 从空布局恢复聚合内容仍待 fixture 验证。
- 2026-08-12：继续收敛浏览空状态操作：管理按钮固定为可访问触控高度并明确回到软件源列表根页面，主题切换即时刷新空状态背景、图标和按钮，无障碍层级排除装饰图标。Repository/release metadata contract、相关 Swift 语法解析、string catalog JSON、`git diff --check` 和 iPhone 17 Pro Simulator Debug build 均通过；安装启动后完成深浅色截图检查，标题、正文、按钮及底栏对比度正常。按钮导航由静态契约覆盖，真实点击及第三方 source 内容恢复仍待受控 UI fixture。
- 2026-08-13：应用图标由两款扩展为六款，新增冰霜、纸白、霓虹和蓝图四种基于正式品牌模板的扁平样式及可重复生成脚本；切换交互改为目标行即时进度、旧/新两行局部更新和触感确认，不再锁死或 reload 整个列表。Repository/release metadata contract、四份 Icon Composer JSON、Info/AltIcons plist、string catalog、Swift 语法、1024px RGB 无 alpha 静态检查、`git diff --check` 和 iPhone 17 Pro Simulator Debug build 均通过；`Assets.car` 确认包含五款 alternate icon 的 1024px opaque rendition，六款逐一实际切换手感仍待人工复核。
- 2026-08-13：继续落盘钛金属、光学玻璃和陶瓷珐琅三款非扁平备选，保留 1024px RGB 无 alpha 的权威源图，并由统一品牌脚本复制到 Icon Composer bundle。默认图标仍保持扁平；三款材质风格仅作为用户主动选择的 alternate icon。

## 当前状态

签名崩溃已经由 build 17 真机验证不再复现，安装完成响应竞争已在代码中修复，change 保持 active。后续改进按独立版本序列发布为 `2.4.1`；真实第三方 IPA 的进度关闭、“我的 App”落库和重启持久性仍由 `ISSUE-20260811-002` 在新构建上验证。在同一微信 IPA 完成端到端回归前，不把 P0 标记为完成。

## 回滚

恢复设置资源、AppManager 原错误关联方式和旧认证资源即可。回滚版本会忽略 Application Support 中的诊断 JSON；不改变 Core Data schema、bundle ID、签名协议或 Server Protocol。AltSign 回滚必须先恢复 nested repo commit，再更新 superproject gitlink，不能留下 dirty submodule。
