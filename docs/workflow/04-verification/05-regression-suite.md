# Regression Suite

## Suite A：快速逻辑回归

触发：Source、error model、URL normalization、纯 Swift/ObjC helper 变化。

```sh
xcodebuild test \
  -workspace AltStore.xcworkspace \
  -scheme AltStore \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=latest" \
  CODE_SIGNING_ALLOWED=NO
```

## Suite B：跨目标构建

触发：project settings、Shared、AltStoreCore、localization、dependency、submodule 变化。

```sh
xcodebuild build \
  -workspace AltStore.xcworkspace \
  -scheme AltStore \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO

xcodebuild build \
  -workspace AltStore.xcworkspace \
  -scheme AltServer \
  -configuration Debug \
  -destination "generic/platform=macOS" \
  CODE_SIGNING_ALLOWED=NO
```

主导航变化执行 `TEST-032`：在 simulator 确认底栏依次只有浏览、来源、我的 App、设置，默认进入浏览；只有官方 AltForge source 时必须切换到无分区标题的专用空布局，只显示可进入软件源页的空状态，不得让“新增和更新/类别/精选”透过占位页。“管理软件源”触控区域不得小于 44pt，并且必须回到软件源列表根页面，而不是停留在上次打开的详情层级；切换主题后图标和按钮立即使用新主题。加入含多个 App、类别和 featuredApps 的 fixture 后确认恢复内容布局且三个聚合区域出现，再检查 source 详情中的资讯区域仍可访问。

iOS 品牌或设置变化执行 `TEST-033`：静态检查四个 SF Symbols、官方 source/app tint override、metadata 色值、无 `ALTVersion` 和本仓库 URL；解析设置 storyboard/XIB 并拒绝控件级固定白/黑色、白色滚动条和强制深色导航栏。应用图标页必须列出标准、珊瑚、冰霜、纸白、霓虹、蓝图、钛金属、光学玻璃和陶瓷珐琅九款图标；切换时显示单行进度、保留滚动和返回交互，不得禁用或 reload 整个 collection，completion 后只更新旧/新两行及勾选。构建后分别在深色与浅色 simulator 检查来源/自身 App 卡片、设置主页、主题选择、应用图标、许可证、刷新记录、错误日志和兼容账号页面，并确认构建版本、AltForge Contributors、Riley Testut、Caroline Moore、“侧载”术语及简体中文不截断。

iOS 公开身份变化执行 `TEST-034`：静态检查 `CFBundleDisplayName`、`CFBundleName`、Debug/Release `EXECUTABLE_NAME`、AltTests host，以及所有 iOS storyboard/XIB 用户属性和 string catalog 显示值。构建后检查 Info.plist 的 executable 与实际 Mach-O 文件均为 AltForge；保留内部 `AltStore.app`/module/协议和明确允许的 AltStore PAL、AltStore 2.0、第三方 source、上游致谢、旧证书兼容名称。系统问题报告标题由真机或受控 crash 手工确认，不在用户设备上主动制造崩溃。

iOS 安装崩溃、恢复日志或认证页面变化执行 `TEST-035`：先检查脱敏系统 crash report 的异常类型和首个业务栈帧，再运行 repository contract、`Scripts/test_ldid_architecture_compatibility.sh`、Watch 目录移除/签名 detail 清理/畸形 plist XCTest、catalog JSON 解析、Settings/Authentication storyboard/XIB XML 解析和 iOS/macOS build。手工导入 UI 必须以同一个有界 `Progress` 显示 0...100% 总进度和读取/下载、解包、检查扩展、查找 Server、认证、profile、签名、发送、设备安装阶段；在含 0/1/5 个 extension 的 fixture 中分别验证无提示、列出数量/名称、超过四项的有界摘要，并覆盖取消、推荐剔除和保留签名三条路径。剔除后仅工作副本的 extension 与 manifest `PlugIns/` 路径消失，保留后 extension 继续进入 profile/signing；中英文必须同时披露功能损失和免费账号限额风险。ldid 回归必须对 Xcode watchOS SDK 生成的最小 `arm64_32` Mach-O 完成签名，并证明未知 CPU type、nil entitlement 和非法路径返回可捕获错误而不是 `SIGSEGV`；synthetic app 必须证明签名前只从副本删除顶层 `Watch/`，重复删除幂等。Server fixture 必须交错触发在途 progress 和 terminal completion，确认同一 framed connection 没有并发发送、pending progress 被终态覆盖且终态只回调一次；iOS 客户端须拒绝 NaN/负进度并接受 `>= 1.0` 的完成值。静态检查不得残留固定白色设置文字、运行时递归改色、在 `viewIsAppearing` reload 后对动态 no-updates index path 调用 `reconfigureItems`，或在 flow-layout 尺寸计算中 dequeue supplementary view。在同一 Simulator 的深浅色模式至少执行 6 轮“设置 -> 我的 App -> 设置”切换，并在安装失败后额外执行 10 轮“我的 App”往返，覆盖 no-updates section 为 0/1 item 和有/无 App IDs footer；确认正文可读、进程不变且没有新 crash report。另覆盖 operation 无 success/error 和 prepared app 缺失路径，必须返回普通错误而不是 precondition。遗留 operation record 最多保留 20 条，每条最多 16 个阶段、单条 detail 最多 120 字符并通过原子 journal 落盘；连续签名和设备安装事件只替换各自最后一个 checkpoint，失败日志显示诊断编号、最后非终态阶段、最新脱敏签名对象或连接类别/百分比和相对耗时轨迹。fixture 必须证明不记录凭据、UDID、团队或 Server ID、证书/profile 和绝对路径。真实 IPA 的签名、发送、设备完成、进度关闭、`InstalledApp` 保存、重启可见性、失败日志和清理由 Suite E 完成，Simulator 结果不得替代设备 E2E。

iOS 主题色变化执行 `TEST-036`：先运行偏好 round-trip XCTest、repository contract、raw metadata tint 绕过扫描、Swift parse、Storyboard/XIB XML 和两个 string catalog JSON 检查，再构建 iOS Simulator target。新安装必须默认锻造红；依次切换锻造红、海洋蓝、靛蓝和玫瑰红，确认色板、checkmark、导航、标签栏、徽标、官方来源/应用/资讯卡片、应用详情和权限确认立即更新，重启后保持，非法 raw value 回退锻造红。四个主题都要在浅色与深色模式确认语义背景、正文、输入框和按钮可读；第三方 source/app 声明的 tint 不得被全局主题覆盖，红/绿/黄只能出现在删除、失败、成功、有效期和警告等状态表达中。

## Suite C：Unicode archive

触发：AltSign ZIP、application name、resign、download/install path 变化。

- 运行 `TEST-003`、`TEST-005`、`TEST-006`、`TEST-007`。
- round trip 后用 ZIP reader 验证 bit 11。
- 删除临时目录并确认无 handle/process 遗留。

在这些测试进入仓库前，Suite C 仍是残余风险，不能标记为 automated。

## Suite D：Release dry run

触发：release workflow、metadata script、bundle ID、minimum OS、source URL 变化。

- 运行 `ruby Scripts/check_release_version.rb`，确认根版本与三平台产品版本一致。
- 运行 `ruby Scripts/test_release_metadata.rb` 和 `ruby Scripts/test_repository_contract.rb`。
- 在临时 artifact 目录准备最小 IPA、macOS DMG 和 Windows ZIP。
- 运行 metadata script。
- 解析 `apps.json` 与三个远程配置 JSON，复算全部 size/hash，验证历史不超过 20 条。
- 解析 `developerdisks.json`，校验 version 1 schema、HTTPS 和允许 host；扫描 Classic 控制端点，确认没有回退到上游 CDN、staging bucket 或上游 OAuth callback。
- 验证遗留 Mail plug-in manager 无网络 URL，默认 Patreon 配置在发起请求前 fail closed，release build settings 未定义 `MARKETPLACE`。
- 验证 Classic 启动不调度 Fediverse operation、source 刷新不查询上游 CloudKit，交互 UI 固定关闭。
- 不创建 tag、不发布 Release。

## Suite E：真实设备

触发：Apple API、provisioning、signing、device install、JIT、最低系统变化。

- 使用脱敏测试账户与设备。
- 执行 `TEST-002` 和受影响路径。
- 不将凭据、UDID 或 profile 保存为 artifact。
- 重签后的 Info.plist 仍含 App Group metadata 但系统不授予 container 时，首次启动必须保留沙盒数据库与 Apps 目录并进入主界面；获得有效 container 的相邻路径仍需完成一次迁移。

## Suite G：macOS DMG

触发：macOS build setting、AltServer bundle、DMG 打包脚本或 release asset 变化。

- 运行 `bash -n Scripts/package_macos_dmg.sh` 与 repository contract。
- 运行 `bash -n Scripts/verify_apple_release_artifacts.sh`；tag workflow 在 Apple runner 上用实际版本和 build number 执行该脚本。
- 使用独立 DerivedData 构建 Release AltServer，并通过脚本生成新的输出路径；本地与 CI Release 都使用 `--ad-hoc-sign` 密封 DMG 内的 staging App，不修改原构建输出。
- 执行 `hdiutil verify`，只读挂载后检查 `AltForge Server.app`、Applications symlink、`.DS_Store`、bundle identifier、版本和目标架构；首次 Finder 内容区域约为 520 × 300 pt，工具栏、状态栏和路径栏隐藏，两个 88 pt 图标位置稳定且无接近全屏的大块空白。
- CI verifier 同时检查 IPA Payload/identity/version、DMG 的 arm64+x86_64 架构和当前 non-Developer-ID policy；App 必须通过 `codesign --verify --deep --strict` 且保持 ad-hoc/no Team ID/no Authority，linker-only 或无效嵌套签名必须 fail closed。publish job 在创建 Draft 前执行 checksum manifest verification。
- 验证后推出本次挂载、清理 DerivedData 与 staging；保留 DMG 仅限用户需要试装时。
- 本地 ad-hoc 签名不得替代 Developer ID、notarization 或另一台 Mac 的 Gatekeeper 验证。

## Suite H：macOS 菜单与设置

触发：AltForge Server 公开名称、About/版权、状态菜单、设备发现、检查更新、图标、设置或 macOS 本地化变化。

- 静态检查 Info.plist、storyboard、string catalogs 和用户可见源码，不允许 About/菜单回退到旧公开名称。
- About 使用较宽且主体水平居中的独立窗口，完整显示可复制/点击的 `https://github.com/legeling/AltForge`，并能打开 Releases、文档和 Issue；URL 和链接按钮悬停时显示 pointing-hand 光标，英文与简体中文下不得截断主要内容。
- 使用内部 AltServer scheme 构建 Release，检查产物为 `AltForge Server.app`、`CFBundleExecutable` 为 `AltForge Server`、`PRODUCT_MODULE_NAME` 仍为 `AltServer`，并检查 `CFBundleDisplayName`、版权、19/38 px template 菜单图标和完整 AppIcon slots。
- 无设备时显示可理解 placeholder；USB、Wi-Fi 与同时连接分别显示正确标签，双连接优先 USB。
- 确认设置项直接位于状态菜单子菜单中且不会打开独立窗口；切换登录启动后显示“已开启/已关闭/需要批准”并与系统登录项一致，macOS 系统提示使用 AltForge Server，签名或注册失败时出现可恢复错误；从历史 `AltServer.app` 开发构建升级时先关闭再开启一次登录项，确认当前 App 路径取代缓存注册；切换跟随系统、English、简体中文后出现重启提示，立即重启后检查菜单、About 和错误文案。
- 确认 Install AltForge 使用安装图标，三个设备子菜单均未被标记成 Recent Documents，也不显示系统注入的时钟图标。
- 更新检查覆盖更新可用、已最新、404/离线、超时、无效 JSON、非 GitHub URL、缺失 DMG、超限 size 和无效 digest。更新可用时主操作直接下载，进度来自 delegate 实际字节，允许取消且重复操作不并发；size/SHA-256 通过后才写入“下载”文件夹并自动打开 DMG。失败可重试或进入 Releases；不得静默替换运行中的 App。
- 遗留邮件插件未安装时入口隐藏；存在时只显示明确的清理文案。
- 无历史账号时可手工输入；成功认证后账号进入最近使用列表，未勾选记住密码时重新选择账号不预填密码。
- 勾选记住密码后只检查本机 Keychain，不检查 UserDefaults、日志或发布产物；忘记账号同时移除可选密码。
- 英文与简体中文的“记住密码”说明都必须预告 macOS 可能请求钥匙串授权，并明确提示应输入 Mac 登录密码而不是 Apple ID 密码；长文案不得被截断。
- 打开认证窗口时账号与可选密码只读取一次 Keychain archive；切换多个账号不触发第二次读取，窗口结束后不保留 credential snapshot 或表单值。ad-hoc Debug 重建后的单次系统授权不冒充 Developer ID 签名行为。
- 密码眼睛按钮在 secure/plain 间无损切换，Caps Lock 开关实时显示/隐藏提示，关闭窗口后 local event monitor 已释放。
- 损坏、超限或不可访问的 Keychain archive fail closed，仍允许手工认证且不显示账号、密码或底层 Keychain 详情。
- 登录窗口底部与操作按钮保持紧凑间距；Caps Lock 或 Keychain 警告显示、隐藏时窗口按可见内容扩缩，不残留隐藏行空白。
- 登录窗口显示原生黄色最小化按钮，可收进 Dock 并恢复；绿色缩放按钮保持隐藏，最小化和恢复不清空输入。
- 输入错误密码、触发认证握手失败或取消验证码：账号窗口在请求期间保持显示，失败后保留账号、密码和记住密码状态，恢复编辑并允许直接重试；错误正文与详情不出现中英混排。
- 检查 `Dependencies/AltSign/Package.swift` 未定义 `MARKETPLACE`；macOS 构建必须编译并链接 AltSign 的 CoreCrypto/SRP 路径，避免 `GSAContext.start()` 在网络请求前固定失败。
- 已验证账号仅在下拉列表右侧显示免费、个人开发者或组织/企业；未知类型不显示占位标识，旧版 archive 可读取并在下次团队查询后更新，标识不表示持久 session。
- 混合证书列表中普通 Xcode/分发证书不得进入 revoke 路径；缓存仅在托管证书序列号一致时复用，替换旧 AltForge/AltStore 证书必须明确确认，取消后证书列表不变。
- 同一设备连续触发安装时只保留一条认证/下载/签名链路并聚焦现有窗口；认证成功后阶段窗口持续可见，进度条左右边距一致，下载显示已下载量/总大小/实时速度/当前线路。手动切换自动、GitHub、配置 CDN 或固定镜像时取消旧 transfer/session 且旧 completion 不得覆盖新线路；自动候选顺序与数量有界，IPA 大小或 SHA-256 不匹配必须失败且释放设备锁、delegate session 和临时文件。
- 快速和限速下载都从 delegate `didWriteData` 收到实际字节；UI 更新有界且最后显示 100%，不能只停在 0% 后跳阶段。installation_proxy 返回带或不带 100% 的 `Complete` 状态都必须触发“安装完成”和通知；完成窗口不按计时器消失，本地化“关闭”按钮和原生标题栏关闭按钮均可关闭窗口，关闭后才释放 UI activity 并允许同一设备再次发起。

## Suite F：Windows AltServer

触发：`AltServer-Windows/`、Windows dependency pin、CI/release workflow 或 Windows artifact contract 变化。

```powershell
.\AltServer-Windows\Scripts\build-release.ps1 -OutputDirectory "$env:TEMP\AltForge-Windows"
```

- 使用固定 revision 恢复依赖，存在不同 checkout 时必须失败而不是覆盖。
- 构建 Win32 Release，并验证 ZIP 至少包含 AltServer、ldid、libimobiledevice、usbmuxd、plist、DNS-SD、cpprestsdk 和 VC runtime。
- 使用 Apple 官网版 iTunes/iCloud 做 `TEST-019`；不得把 Apple 安装包或敏感数据加入 artifact。
- macOS/Linux 上的 XML/YAML/parser 检查不等同于 MSBuild 通过。

## Suite I：静态官网

触发：`website/`、官网设计系统/品牌图、下载 URL、Release metadata、GitHub Actions workflow、仓库 homepage 或 Cloudflare Pages 配置变化。

- 运行 `ruby Scripts/test_website.rb`，检查 HTML 可解析、英中 key 完整、平台下载使用本仓库 `releases/latest`、无第三方下载/分析 host、单一 hero 与资产来源、仓库归属入口、workflow fail-closed，以及 CSP、focus、dark mode、reduced-motion 与 44px target 契约。
- 启动任务专属静态服务器；以真实浏览器检查 320、375、768、1024、1440px，并分别覆盖浅色、深色、English、简体中文。检查首屏只有一个主导 AltForge 标记且露出下一段，标题/版本/下载/源码无遮挡；继续检查平台列表、安装步骤、FAQ 与 footer，无横向滚动、文字截断、重叠或不可操作控件。
- 模拟 latest Release API 不可访问，确认通用“最新”和全部下载链接仍可用；模拟 macOS、Windows 与其他平台，确认首要 CTA 分别为 DMG、ZIP 与 latest Release，且对应平台只显示一个推荐状态。
- 部署后检查 Pages production URL 返回 200、安全响应头生效、latest Release API 当前版本可显示，三个下载 URL 仍由 GitHub Release 响应；确认线上 HTML/CSS/JS/hero 与本地预期一致，不得把 IPA/DMG/ZIP 上传到 Pages。
- 检查 GitHub repository homepage 指向生产官网；workflow 必须在未设置启用变量时只验证不部署，启用后只从 `marketplace` 上传 `website/`，凭据只来自 repository Secrets。
- 验证后停止本次静态服务器和浏览器，清理任务截图与临时缓存；只有用户要求试用时保留单个服务器并报告端口。

## Suite J：Apple 认证响应兼容

触发：AltServer anisette client identity、AltSign GSA 请求/解析、认证错误映射或 Apple 系统版本变化。

- 运行 repository contract，确认 `X-MMe-Client-Info` 不含已拒绝的 Xcode 11 client version，当前 Mac model、macOS version/build 与现代 client version 组成内部一致的描述。
- 用 synthetic plist 覆盖正常 `Response/Status`、以 `<html>` 开头的正文、空内容和缺失 `Status`；畸形输入必须返回 `authenticationHandshakeFailed (3020)`，不得在日志、fixture 或 error userInfo 保存响应正文。
- 构建 AltServer 与 AltStore target，确认 Server 生产者、Server Protocol 编解码和 iOS AltSign 消费者同时兼容；本变更不修改 machine ID、OTP、routing info、SRP 算法或协议 schema。
- 用专用测试 Apple ID 在真实设备完成登录、2FA、团队和证书查询，再安装最小测试 IPA。账号、密码、验证码、UDID、token、certificate、profile 和 anisette headers 不进入命令输出或验证文档。
- Apple endpoint 使用既有系统 URLSession 超时和显式用户重试；失败时不得自动无界重试。真实账号门禁未完成前保持 `ISSUE-20260904-001` Open。

## Suite K：错误码与用户提示

触发：错误 enum/domain、provider、错误序列化、Toast/Alert/通知展示或 string catalog 变化。

- 运行 AltTests 中的 user-facing presentation 测试，枚举全部已知 provider code 和既有业务 fixture；标题、原因、恢复建议必须非空。
- 运行 repository contract，检查 Apple/Windows code 数值、共享展示入口、简体中文 key、进程输出隔离和认证 3020 映射。
- 构建 iOS AltStore 与 macOS AltServer，确认共享 Swift、Objective-C provider、AltSign submodule 与两份 catalog 同时编译。
- 使用简体中文检查 Apple ID 错误、IPA 损坏、Server 断连和未知错误四类代表界面；主提示不得出现 domain、源码路径、命令输出或与阶段无关的“格式错误”。
- Windows 变更至少执行源码/contract 检查；只有 Windows runner 完成 MSBuild 后才能声明 Windows 构建通过。

## 命令登记规则

- tag-driven Release workflow 是自动构建命令的真相来源，本文件解释本地预检和触发条件。
- destination 或 Xcode 版本变化时同时更新 workflow、README 和 reference。
- 失败结果记录首个根因与未执行的后续 suite，不保存大型完整日志到 `docs/`。
