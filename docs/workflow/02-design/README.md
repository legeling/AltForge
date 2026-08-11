<p align="center">
  <img src="../../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# System Design

## 设计原则

- 保留 AltStore 的客户端/服务器分工：iOS 端负责用户流程和应用状态，macOS 端负责需要桌面环境或设备服务的安装工作。
- 对通用兼容修复优先修改其真实所有者，例如 archive 与签名逻辑属于 AltSign，而不是在 UI 层绕过。
- Shared 中的协议和错误模型是跨进程契约；修改时必须同时验证两端。
- Core Data、Keychain、UserDefaults 和临时文件各有明确边界，禁止用全局缓存复制长期状态。

## 系统边界

```text
GitHub Release / third-party source
               |
               v
       AltForge iOS app
        |  AppManager + Operations
        |  Network.framework / server protocol
        v
       AltServer macOS / Windows
        |  AltSign + Apple Developer services
        |  libimobiledevice / device services
        v
       iPhone / iPad
```

## 设计项

### `DES-001` iOS 工作流编排

`AltStore/Managing Apps/AppManager.swift` 组织认证、下载、刷新和安装所需 Operation。Operation 通过显式 dependency 串联，避免 UI 直接访问 Apple API 或设备层。

核心流程由 `DownloadAppOperation`、`ResignAppOperation`、`FindServerOperation`、`SendAppOperation` 和 `InstallAppOperation` 等组成。Operation context 持有单次请求需要的数据，完成后释放临时资源。

### `DES-002` Server discovery 与传输

AltForge 使用 `Network.framework` 和 `Shared/Connections` 发现 AltServer，优先匹配嵌入的 server ID，失败时可选择其他可用服务。`Shared/Server Protocol/ServerProtocol.swift` 定义请求类型、版本和 Codable payload。

IPA 是大对象，传输和落盘应避免重复复制；协议变更必须保持版本兼容或返回明确的 incompatible server 错误。

### `DES-003` AltServer 安装职责

`AltServer/Devices/ALTDeviceManager+Installation.swift` 负责：

1. 获取 anisette data 并认证 Apple ID。
2. 选择开发团队、注册设备和获取证书。
3. 下载或读取 IPA，解压应用 bundle。
4. 为主应用和 extensions 注册 App ID、更新 capabilities、获取 profiles。
5. 使用 AltSign 重签并通过设备服务安装。
6. 把结构化错误返回客户端或 macOS UI。

团队选择在客户端认证和 AltServer 安装两条路径中使用相同 fallback：依次选择个人、组织、免费团队；客户端还会在 fallback 前匹配本地已保存的 team identifier。团队列表规模很小，现有实现最多进行三次线性扫描，时间复杂度仍为 `O(n)`，不引入额外缓存或跨账户状态。

外部调用必须有失败出口；下载文件、解压目录、证书和连接必须按单次任务生命周期释放。

### `DES-004` 数据边界

- Core Data：source、store app、installed app、App ID、team、refresh attempt、logged error 等长期关系数据。
- Keychain：账户、证书或其他敏感值；不得迁移到普通 plist、日志或 source JSON。
- UserDefaults：非敏感偏好与轻量状态。
- 临时目录：下载 IPA、解压 bundle、重签输出；成功或失败后清理。
- App Group：AltForge、Widget 与 AltBackup 之间的受控共享数据。

### `DES-005` Unicode IPA 兼容

Unicode 处理分两层：

- Apple App ID description：只发送 ASCII 字母、数字和普通空格，trim 后为空则使用 `App`；这不修改 `CFBundleDisplayName`。
- ZIP entry：优先读取 UTF-8 flag，再验证 Info-ZIP Unicode Path extra field；对没有正确标志的历史包，使用无损的 GB18030/GBK、Big5、Shift-JIS、EUC-KR 和 DOS fallback。输出 ZIP 一律写 UTF-8 filename flag。

每个 entry 的 filename 与 extra field 按 ZIP 字段上限分配，处理复杂度为 `O(entries + filename bytes)`，不建立随 archive 无界增长的缓存。解压前拒绝绝对路径和 `..` component。

### `DES-006` 本地化

项目继续使用 Xcode string catalog、storyboard localization 和 `NSLocalizedString`。简体中文资源与英文源文案共用现有 key；代码中的品牌字符串和 bundle/source identity 通过 `Bundle`、常量或 model 统一提供，避免散落硬编码。

### `DES-007` Source 与更新

`AltStoreCore/Model/Source.swift` 负责 source URL 和稳定 source ID；query、fragment、scheme、大小写和多余斜杠不应制造重复 source。官方 source 指向 GitHub Release 的 `apps.json`。

### `DES-008` 错误模型

本地 Error 通过 `ALTLocalizedError`、`ALTServerError` 和 `CodableError` 传输。序列化必须保留 domain/code/failure/recovery suggestion，并移除不能安全编码的对象。日志使用 OSLog privacy 标记，敏感字段不得标记为 public。

### `DES-009` 构建依赖

- Workspace：`AltStore.xcworkspace`
- CocoaPods：Sparkle、STPrivilegedTask，使用 `Podfile.lock`
- Swift packages：KeychainAccess、LaunchAtLogin、Nuke、swift-argument-parser、TelemetryDeck，使用 workspace `Package.resolved`
- Submodules：AltSign、Roxas、libimobiledevice、libplist、libusbmuxd、MarkdownAttributedString

构建必须使用递归 submodule，并对网络依赖设置 CI timeout。AltSign 通用修复保存在 `legeling/AltSign` fork；同步上游时需要同时更新 nested commit 与 superproject gitlink。

Classic 版本必须使用未定义 `MARKETPLACE` 且包含 Apple 认证所需 crypto 实现的 AltSign 基线。迁移 AltSign 时先在 fork 分支提交并推送，再更新 superproject gitlink；不得以 dirty submodule 交付。

### `DES-010` 发布流水线

仓库只保留 tag-driven release workflow，普通 branch push 与 pull request 不触发自动构建。根目录 `VERSION` 使用纯数字 `X.Y.Z`，作为 iOS、macOS 和 Windows 产品版本的唯一来源；仅严格匹配的 `vX.Y.Z` 标签通过 preflight。CI build number 使用 GitHub run number，以便同一产品版本下仍能追踪具体构建。

标签 preflight 先校验版本、release metadata contract 与 repository policy contract，再并行运行 Apple 测试/构建和 Win32 Windows AltServer 构建，最后汇总 source/checksum 并创建 Draft GitHub Release。Apple runner 使用与 `Podfile.lock` 一致的 CocoaPods 1.16.2；Windows runner 在 workspace 检出 `vcpkg.json` 指定的固定 vcpkg commit，避免依赖 hosted runner 的可变系统 checkout。任一平台失败时 publish job 不运行。产物先写入 runner 临时目录，不回写仓库。

### `DES-011` Windows AltServer

`AltServer-Windows/` 是官方 Windows 1.7.4 源码的单仓库快照，保留 C++ AltSign、libimobiledevice 和设备服务分层。产品 source 固定指向本仓库 `apps.json`，安装 bundle identifier 为 `com.legeling.AltForge`；内部历史类型和协议 error domain 不批量改名，以降低协议回归风险。

上游两个 gitlink、libimobiledevice 构建所需的三个源码树与 Apple 开源 mDNSResponder 由 PowerShell 按 commit 恢复，存在不同 revision 时直接失败，不静默覆盖。cpprestsdk、OpenSSL、PCRE2 和 zlib 由固定 vcpkg baseline 提供；仓库级 MSBuild targets 只把 manifest include/library 路径注入 Win32 项目，并为 imobiledevice/AltServer 补齐 OpenSSL 与 zlib 链接契约。每个源码仓库最多三次 fetch，CI job 总时限 60 分钟；不存在无界并发。Windows Release 使用 Win32 ZIP，以兼容 32/64 位 Windows，并在压缩前检查 executable、device libraries、DNS-SD、HTTP、OpenSSL、PCRE2、zlib 和 VC runtime DLL。

官方 Windows 树中的 Apple corecrypto 预编译库及 headers 受限于禁止再分发的 Internal Use License，因此不进入 AltForge。Windows 认证改用 vcpkg OpenSSL 实现 SHA-256、PBKDF2、HMAC、AES 和大数运算，并按固定 `js-srp-gsa` commit 的 ISC-licensed GSA/SRP-6a 计算规则实现交换；Release 同步携带 ISC 与 OpenSSL license notice。

Windows 自动更新不使用上游 WinSparkle feed，菜单改为打开本仓库 Releases，避免把 AltForge 服务替换成官方二进制。用户仍须自行安装 Apple 官网版 iTunes/iCloud；仓库和 Release 不再分发 Apple 运行时。

### `DES-012` 发布审核与更新独立性

标签流水线完成三平台构建后使用 `gh release create --draft` 创建 Draft Release。Draft 包含 IPA、macOS AltServer DMG、Windows AltServer ZIP、`apps.json`、远程配置 JSON 和总 checksum；只有维护者完成人工下载、hash、安装说明与已知风险审查后才在 GitHub UI 发布。失败或未审核的 Draft 不改变 `releases/latest`。

`apps.json` 的当前版本使用 `releases/download/vX.Y.Z/AltForge.ipa` 固定 URL。生成器可读取上一正式 Release 的 `apps.json`，校验 source identifier 与 bundle identifier 后，去重并保留最多 19 个旧版本，使当前加历史总数不超过 20。处理成本为 `O(versions + bytes)`，输出空间上限为 20 个版本条目，不请求或加载无关 Release。

Classic 客户端的 feature flags、trusted/blocked sources 和 recommended collections 从本仓库 Release 的静态 JSON 读取。默认配置为空或仅信任 AltForge 官方 source，不允许上游站点写入本地 feature flags 或决定 source 封禁。上游官方 patron 列表和 Fediverse enrichment 在 Classic fork 中停用；Patreon source pledge、Marketplace、Developer Disk 和 Apple 服务属于不同能力，不得冒充 AltForge 官方服务。Developer Disk 索引由 AltForge 发布，索引引用的文件和 Apple API 作为明确披露的外部兼容性依赖保留。

AltForge 没有自有官网或社交账号时，以仓库 README、Issues、隐私文档和故障排查文档作为稳定用户入口，并隐藏无归属的社交/赞助按钮。Windows 桌面端只打开本仓库 Releases；macOS 桌面端可读取 GitHub latest Release 比较产品版本，但不自动下载、替换或安装 App。

### `DES-013` macOS DMG 打包与本地验证

`Scripts/package_macos_dmg.sh` 是 CI 与本地共用的唯一 DMG 打包入口。脚本把输入 App 复制到任务专属临时 staging，加入 `/Applications` 快捷方式，以 `hdiutil` 生成压缩 DMG 并立即执行 image verify；成功、失败或中断都会清理 staging。处理时间与 I/O 为 `O(app bytes)`，除一个 App 副本和压缩映像外不常驻额外大型数据。

Release workflow 与本地验证都只对 staging 副本执行 `--ad-hoc-sign`，密封完整 App bundle，使 `SMAppService` 能验证登录项来源，并由 artifact verifier 执行 `codesign --verify --deep --strict`。该签名没有 Team ID、证书身份或 notarization，不得描述为可信发行身份；Developer ID、hardened runtime 和 notarization 必须在获得正式凭据后通过独立 change 设计。脚本不会修改 Xcode build 输出，并拒绝覆盖已有输出，防止静默替换人工审核中的 artifact。

### `DES-014` AltForge Server 菜单与设置

公开产品名使用 AltForge Server，Info.plist、About、菜单、通知和用户错误统一这一名称；Xcode target、Mach-O executable、协议类型、旧数据路径和上游源码头继续保留 AltServer，避免破坏兼容与制造无意义同步冲突。About 以贡献者和项目社区为单位表达维护/致谢，同时单独保留上游版权事实和 AGPL v3.0。

打开状态菜单时，只调用一次 `availableDevices` 和一次 USB-only `connectedDevices`，将 USB identifier 组成有界集合；三个设备子菜单复用该集合生成 `设备名（USB）` 或 `设备名（Wi-Fi）`，同时使用 template SF Symbols。USB/Wi-Fi 同时可用时优先 USB。菜单栏图标继续使用 19/38 px alpha template asset，并在运行时显式设置 template 渲染。

`Settings` 是状态菜单内的子菜单，不创建独立窗口；其中直接包含 `Launch at Login` 开关和语言子菜单。登录启动菜单项使用标准 `NSMenuItem.state`，并以本地化标题补充 `On/Off/Requires Approval`；macOS 13+ 使用 `SMAppService.mainApp` 的真实状态、可抛错 register/unregister 和登录项系统设置入口，macOS 11/12 才使用 `LaunchAtLogin` fallback。语言选择使用单选勾选状态，保存到 App 自有 preference，并为下一次启动设置 `AppleLanguages`；选择“跟随系统”时移除覆盖。偏好在重启前显式写盘，随后明确提供“立即重启/稍后”；立即重启只创建一个 0.5 秒延迟的短生命周期 relauncher，避免选择丢失和新旧服务实例长期并存。Storyboard/string catalog 仍是唯一文本源，不尝试在当前进程热替换已加载资源。设备子菜单不得声明为 `recentDocuments` 系统菜单，避免 macOS 注入与安装无关的时钟图标；安装、设置和检查更新入口分别使用安装、齿轮和刷新 template SF Symbol，安装图标另提供兼容 fallback。

“检查更新”对固定 GitHub API 发出单次 GET，请求超时 10 秒且不重试。解析只接受 200 JSON；打开 Release 前必须验证 `https` 和 `github.com` host。它只比较当前 `CFBundleShortVersionString` 与 latest tag，不承担下载、签名或安装职责；首次 Release 尚未发布、离线、限流或格式错误均返回明确的手工 Releases 入口。

### `DES-015` 网络所有权边界

网络端点按所有权分为三类，不做机械式域名替换：

1. **AltForge 控制面**：`apps.json`、flags、trusted/blocked sources、recommended collections、Developer Disk 索引、版本检查和用户支持入口固定使用 `legeling/AltForge` 的 GitHub Release、API 或仓库文档。
2. **外部兼容性服务**：Apple Developer/device 服务、Patreon API、第三方 source 和 Developer Disk 文件继续使用真实提供方。它们不能被改写成不兼容的 GitHub URL，也不能被描述为 AltForge 托管。
3. **构建依赖与归属**：CocoaPods、SwiftPM、submodule 及上游 provenance/许可证链接保留真实来源；只有已有且经过验证的 fork 才切换，例如 `legeling/AltSign`。

`Release/developerdisks.json` 只托管版本到下载位置的有界索引，不复制 Apple 或社区提供的 disk image。索引采用 version 1 schema，每个条目只能包含 `archive`，或同时包含 `disk` 与 `signature`；全部 URL 必须是 HTTPS 且 host 在显式允许列表中。macOS 和 Windows 使用同一个 latest Release 索引，避免平台策略漂移。索引规模与受支持系统版本数线性增长，解析和校验复杂度为 `O(entries + bytes)`；列表由发布审查控制，不接受运行时用户输入。

Classic 的三个远程配置端点不再保留上游 Marketplace 分支。当前 Release build 不定义 `MARKETPLACE`；仓库中的 Marketplace/Fediverse API 实现属于未发布的历史代码，不能作为 Classic 运行时依赖。Classic 固定隐藏 Fediverse 交互，启动不调度交互 operation，source 刷新不查询上游 CloudKit metadata；未来启用 Marketplace 前必须另行设计 AltForge 自有的兼容后端和迁移策略。遗留 Mail plug-in 只支持检测和卸载，不再查询或下载上游 plug-in。Patreon 是可选第三方集成：默认 plist 不含凭据和回调，客户端隐藏入口并在任何认证请求前 fail closed；维护者必须配置自己的 OAuth application 与 HTTPS redirect URI 才能启用。

### `DES-016` macOS Apple ID 账号与凭据管理

认证 UI 使用独立原生 AppKit window controller，替代狭窄的 `NSAlert` accessory view。账号输入采用普通可编辑文本框与自定义 transient popover，按最近顺序列出成功认证的账号；账号框和密码框保持相同宽度，账号选择、忘记账号和密码显隐使用独立图标按钮。密码区同时维护 secure/plain 两个互斥文本框，并在 modal 生命周期内用一个 local flags-change monitor 更新 Caps Lock 提醒。窗口按可见内容动态收缩或扩展，关闭时必须移除 monitor，不启动后台线程或常驻观察者。

Apple verification handler 使用匹配的独立 window controller 替代验证码 `NSAlert`。验证码字段过滤为最多六位 ASCII 数字，兼容粘贴；验证码只经当前 callback 返回给 AltSign，窗口退出后释放，不进入 Keychain、UserDefaults 或日志。

AltServer 复用仓库已经固定的 KeychainAccess package，新建仅属于桌面端的 `afterFirstUnlockThisDeviceOnly` service。账号与可选密码编码为 versioned 单项 archive，使账号顺序和密码选择通过一次 Keychain update 原子替换；最多八个账号、64 KiB archive、账号 320 字符和密码 1024 字符。认证窗口通过一次 `credentialSnapshot` 读取账号和可选密码，账号下拉只查询该 window-modal 生命周期内的有界快照；结束时释放快照和表单值，不把凭据提升为进程级缓存。读取、选择、更新和忘记账号均为有界 `O(accounts + bytes)`，账号数上限使 UI 更新为常量级；不得使用 UserDefaults、明文文件、Application Support、App bundle、日志或同步型 iCloud Keychain fallback。

只有 `ALTAppleAPI.authenticate` 返回 account/session 后才触发 credential callback。勾选“记住密码”时保存密码，未勾选时仍保留账号但清除该账号的旧密码；损坏或不可访问的 archive fail closed，窗口显示无敏感详情的内联提示并继续允许手工登录。Keychain 更新失败不改变认证/安装结果，仅发送不含账号的本地通知。

登录窗口使用异步 submission callback 驱动现有安装链路，点击继续只进入有界的 loading state，不结束 modal session。认证前失败在主线程恢复全部输入控件并显示本地化内联错误；只有取得 account/session 后才保存凭据并关闭窗口，随后团队、设备、证书、签名或安装阶段的错误继续使用全局错误窗口。AltSign 的用户可见错误 key 在 AltServer 主 string catalog 中提供完整简体中文翻译，避免 framework fallback 英文与中文标题混排。

Classic AltForge Server 通过 AltSign 已有的 CoreCrypto/SRP 实现完成 GrandSlam 认证。`MARKETPLACE` 条件会使 `GSAContext` 的密钥生成和服务端校验固定失败，只适用于不包含该能力的 Marketplace 产物；Classic package target 禁止定义该条件，并由 repository contract 检查。这里不复制或自行实现密码学算法。

账号 archive 的 credential 增加可选 team-type raw value，保持 archive version 1 向后兼容；未知值不显示类型，避免把尚未查询的账号误标成异常状态。认证成功先保存账号与密码 consent，`fetchTeam` 成功后在主线程补写 `.free`、`.individual` 或 `.organization`。只有自定义账号选择器在已确认类型时显示这一快照，当前可编辑账号行保持简洁；类型不表示持久 Apple session。

证书流程先过滤 machine name 为 `AltForge*` 或历史 `AltStore*` 的托管证书，再用服务端 machine identifier 解密本机 P12，并要求序列号一致。缓存不可复用时只允许用户明确替换托管证书；没有托管证书时直接请求创建 `AltForge` 证书，失败则返回错误，不撤销任意 `certificates.first`。该边界保护 Xcode 与团队成员的签名资产。

### `DES-017` macOS 单设备安装事务与 Release 下载

`AppDelegate` 以设备 identifier 保存单次运行期安装 activity。认证、远程 IPA、本地 IPA、签名和设备写入共用这一锁；重复点击同一设备不创建第二条链路，只把认证窗口或现有进度窗口带到前台。任务成功、失败、用户取消或认证窗口关闭时均删除 activity。不同设备仍可各自执行，但每台设备最多一条任务，字典规模受当前连接设备数限制。

Apple ID 认证成功后关闭凭据窗口，并立即显示独立原生进度窗口。安装管理器通过显式 callback 报告团队查询、设备注册、证书、设备准备、IPA 下载、描述文件、签名和安装阶段；URLSession 与底层 `NSProgress` 提供下载及设备安装百分比。全宽进度条不为隐藏的百分比标签预留右侧列；下载信息放在独立行，使用 `ByteCountFormatter` 显示已下载量、总大小和指数平滑后的即时速度。下载源选择器由线程安全的单任务 control 连接 UI 与 URLSession，切换时增加 generation、取消并释放旧 task/KVO，只接受当前 generation 的 completion，避免旧回调覆盖新下载。窗口不记录账号、UDID、证书或签名材料，完成后短暂显示成功状态，失败时先关闭进度再进入既有结构化错误窗口。

官方 source 仍选择 tag 固定的 `github.com/legeling/AltForge/releases/download/.../AltForge.ipa`，并携带发布时生成的 size/SHA-256；旧 metadata 缺失时再以固定 GitHub API 查询同名 asset。当前版本可以声明最多四个经过 HTTPS 结构校验的 `downloadMirrors`，其中仓库 Actions 变量生成的自有 CDN 排在自动线路首位；随后是 GitHub 和两个固定 HTTPS 反向代理。用户也可选择单一线路立即重启下载。所有镜像下载后以 1 MiB 流式块计算 SHA-256，并同时校验文件大小，任何不匹配都失败，绝不解压。自动尝试数上限为配置 CDN 4 个、GitHub 1 个和固定公共镜像 2 个，始终顺序执行；请求 idle timeout 为 45 秒、总资源 timeout 为 600 秒。时间复杂度为 `O(sum(attempted download bytes))`，额外内存为 `O(1 MiB)`，临时文件、task 与 KVO 在成功、失败和线路切换时释放。

### `DES-018` iOS App Group 数据迁移降级

`FileManager.altstoreSharedDirectory` 是 App Group 可用性的唯一运行时真相：Info.plist 中的 `ALTAppGroups` 只表示候选 identifier，不能证明当前 provisioning profile 和系统 sandbox 已授予 container。`DatabaseManager` 在任何 `NSFileCoordinator` intent、Core Data migration、删除或目录替换之前同时要求迁移偏好开启且 shared container URL 非空。

免费开发者或其他重签环境无法解析 container 时，`PersistentContainer` 与 `InstalledApp` 保持既有 application-support fallback，启动按普通沙盒路径继续；迁移偏好不清除，以便未来获得有效 entitlement 后再尝试。即使运行期 container 解析状态发生变化，标准化后的数据库与 Apps 源/目标路径必须分别不同，否则整次迁移无写入返回。判断与路径比较均为常数成本 `O(1)`，不新增复制、轮询或重试。

## 可选目标与边界

| Target | 责任 | 核心安装依赖 |
|---|---|---|
| AltWidgetExtension | 展示 installed app / expiration snapshot | 否 |
| AltBackup | 备份与恢复 app container/app group 数据 | 否 |
| AltJIT | macOS CLI，准备 developer disk 并启用 JIT | 可选 |
| AltDaemon / AltXPC / AltPlugin | 辅助进程与历史 macOS 集成 | 按构建配置 |
| AltMarketplace | MarketplaceKit extension | 当前 Classic 发布不嵌入 |

## 失败链路

- Source 下载失败：保留原 source，记录可恢复错误，不写入半解析数据。
- Apple 认证或 App ID 失败：停止签名，不生成部分安装成功状态。
- Archive 解码或路径校验失败：关闭 archive/file handle，删除临时输出，返回 file error。
- 设备断连：终止当前请求，保留可用于诊断的结构化错误，不无界重试。
- Release 任一步失败：不创建不完整 GitHub Release；校验和只基于已存在产物生成。
- DMG 输入无效、输出已存在或 image verify 失败：停止打包并清理本次 staging，不覆盖既有 artifact。
- Windows 依赖 revision 不匹配或 runtime DLL 缺失：立即停止构建/打包，清理本次 staging directory，不覆盖现有依赖 checkout。
- 自有 metadata 缺失或 schema/host 校验失败：停止 Release，不回退到上游控制面；Classic 不执行 Fediverse enrichment；未配置 OAuth 时不打开浏览器、不发送 token 请求。

## 方案取舍

| 方案 | 优点 | 代价 | 决策 |
|---|---|---|---|
| 直接等待上游修复 | 同步成本低 | 长期 Issue 无法及时解决 | 不采用为唯一策略 |
| 在 AltForge UI 层改名/重打包 | 改动快 | 破坏显示名，绕过真实所有者 | 不采用 |
| 在 AltSign 修复 App ID 与 ZIP 兼容 | 两端复用、可回馈上游 | 需要维护 submodule fork | 当前采用，见 `ADR-20260808-001` |

## 待确认

- `[待确认]` 未来是否将整个项目迁移到 Swift 6 language mode；当前已确认并对外说明的 build setting 为 Swift 5.0。
- `[待确认]` 是否为 release 增加 Developer ID 签名、notarization 和 Sparkle feed。
- `[待确认]` 是否为 installation protocol 建立独立版本兼容矩阵。
