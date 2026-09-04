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

项目继续使用 Xcode string catalog、storyboard localization 和 `NSLocalizedString`。简体中文资源与英文源文案共用现有 key；代码中的品牌字符串和 bundle/source identity 通过 `Bundle`、常量或 model 统一提供，避免散落硬编码。Repository contract 解析仓库维护的 13 份 App、Widget、Core、Backup 与 Server catalog，线性检查简体中文完整性与格式占位符多重集，并锁定“已激活/未激活”“点赞/取消点赞”“软件源”“授权项”等关键术语；扫描成本为 `O(s + b)`，其中 `s` 为条目数、`b` 为字符串总字节数，不增加运行时开销。

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

Apple job 不依赖 hosted image 预先创建某个固定名称的 Simulator。它从所选 Xcode 的可用 iOS runtime 中选择最高版本，优先使用 iPhone 17 Pro device type，创建任务专属 Simulator 并以 UDID 运行回归；无论成功或失败都删除该 Simulator。runtime 或 iPhone device type 不存在时 fail closed，不把跳过测试当作发布通过。

维护者明确授权 force 更新已公开 tag 的紧急恢复是唯一例外：三个平台仍必须从新 tag commit 完整重建，publish job 不删除 Release，而是以 `--clobber` 原位替换九项受审资产。上传完成后重新下载 Release 并按新的 `SHA256SUMS.txt` 校验；不得仅替换 IPA，因为 source metadata 中的 build、size 和 SHA-256 必须同步变化。

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

`Scripts/package_macos_dmg.sh` 是 CI 与本地共用的唯一 DMG 打包入口。脚本把输入 App 复制到任务专属临时 staging，加入 `/Applications` 快捷方式，先创建 UDRW 中间映像并以 Finder AppleScript 写入 `.DS_Store`：内容区域固定为 520 × 300 pt，88 pt 图标分别位于左右两侧，工具栏、状态栏和路径栏隐藏。Finder 只会为标准 `/Volumes` 挂载持久化目录窗口元数据，因此脚本使用公开卷名挂载，并在发现同名现有卷时拒绝继续，避免操作用户挂载。元数据缺失时 fail closed；成功后推出可写映像、转换为 UDZO 压缩 DMG 并立即执行 image verify。成功、失败或中断都会推出本任务捕获的设备并清理 staging。处理时间与 I/O 为 `O(app bytes)`，Finder 布局为固定两个项目的 `O(1)` 操作，除一个 App 副本、可写中间映像和压缩映像外不常驻额外大型数据。

Release workflow 与本地验证都只对 staging 副本执行 `--ad-hoc-sign`，密封完整 App bundle，使 `SMAppService` 能验证登录项来源，并由 artifact verifier 执行 `codesign --verify --deep --strict`。该签名没有 Team ID、证书身份或 notarization，不得描述为可信发行身份；Developer ID、hardened runtime 和 notarization 必须在获得正式凭据后通过独立 change 设计。脚本不会修改 Xcode build 输出，并拒绝覆盖已有输出，防止静默替换人工审核中的 artifact。

### `DES-014` AltForge Server 菜单与设置

公开产品名使用 AltForge Server，Xcode build product、`.app` 包目录、Mach-O executable、Info.plist、登录项/后台项目系统提示、About、菜单、通知和用户错误统一这一名称。Xcode target 与 `PRODUCT_MODULE_NAME` 继续保留 `AltServer`，使 `AltServer-Swift.h`、协议类型、旧数据路径和上游源码头保持兼容；scheme 的 `BlueprintName` 指向内部 target，而 `BuildableName` 指向 `AltForge Server.app`。About 使用 560 × 420 pt 的独立原生窗口，主体内容水平居中，以贡献者和项目社区为单位表达维护/致谢，单独保留上游版权事实和 AGPL v3.0，并显示可复制、可点击的完整 `https://github.com/legeling/AltForge` 地址及 Releases、文档和 Issue 入口。URL 与链接按钮通过 cursor rect 在悬停时显示 pointing-hand 光标。

打开状态菜单时，只调用一次 `availableDevices` 和一次 USB-only `connectedDevices`，将 USB identifier 组成有界集合；三个设备子菜单复用该集合生成 `设备名（USB）` 或 `设备名（Wi-Fi）`，同时使用 template SF Symbols。USB/Wi-Fi 同时可用时优先 USB。菜单栏图标继续使用 19/38 px alpha template asset，并在运行时显式设置 template 渲染。

`Settings` 是状态菜单内的子菜单，不创建独立窗口；其中直接包含 `Launch at Login` 开关和语言子菜单。登录启动菜单项使用标准 `NSMenuItem.state`，并以本地化标题补充 `On/Off/Requires Approval`；macOS 13+ 使用 `SMAppService.mainApp` 的真实状态、可抛错 register/unregister 和登录项系统设置入口，macOS 11/12 才使用 `LaunchAtLogin` fallback。macOS 会缓存同一 bundle identifier 的旧注册路径与展示信息，所以从历史 `AltServer.app` 开发构建升级后由用户关闭再开启一次登录项以完成 unregister/register；App 不在启动时静默修改用户的登录项授权。语言选择使用单选勾选状态，保存到 App 自有 preference，并为下一次启动设置 `AppleLanguages`；选择“跟随系统”时移除覆盖。偏好在重启前显式写盘，随后明确提供“立即重启/稍后”；立即重启只创建一个 0.5 秒延迟的短生命周期 relauncher，避免选择丢失和新旧服务实例长期并存。Storyboard/string catalog 仍是唯一文本源，不尝试在当前进程热替换已加载资源。设备子菜单不得声明为 `recentDocuments` 系统菜单，避免 macOS 注入与安装无关的时钟图标；安装、设置和检查更新入口分别使用安装、齿轮和刷新 template SF Symbol，安装图标另提供兼容 fallback。

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

只有 `ALTAppleAPI.authenticate` 返回 account/session 后才触发 credential callback。勾选“记住密码”时保存密码，未勾选时仍保留账号但清除该账号的旧密码；窗口在复选框下以英文和简体中文说明 macOS 读取密码时可能请求 Keychain 授权，并明确所需的是 Mac 登录密码而非 Apple ID 密码。损坏或不可访问的 archive fail closed，窗口显示无敏感详情的内联提示并继续允许手工登录。Keychain 更新失败不改变认证/安装结果，仅发送不含账号的本地通知。

登录窗口使用异步 submission callback 驱动现有安装链路，点击继续只进入有界的 loading state，不结束 modal session。认证前失败在主线程恢复全部输入控件并显示本地化内联错误；只有取得 account/session 后才保存凭据并关闭窗口，随后团队、设备、证书、签名或安装阶段的错误继续使用全局错误窗口。AltSign 的用户可见错误 key 在 AltServer 主 string catalog 中提供完整简体中文翻译，避免 framework fallback 英文与中文标题混排。

Classic AltForge Server 通过 AltSign 已有的 CoreCrypto/SRP 实现完成 GrandSlam 认证。`MARKETPLACE` 条件会使 `GSAContext` 的密钥生成和服务端校验固定失败，只适用于不包含该能力的 Marketplace 产物；Classic package target 禁止定义该条件，并由 repository contract 检查。这里不复制或自行实现密码学算法。

账号 archive 的 credential 增加可选 team-type raw value，保持 archive version 1 向后兼容；未知值不显示类型，避免把尚未查询的账号误标成异常状态。认证成功先保存账号与密码 consent，`fetchTeam` 成功后在主线程补写 `.free`、`.individual` 或 `.organization`。只有自定义账号选择器在已确认类型时显示这一快照，当前可编辑账号行保持简洁；类型不表示持久 Apple session。

证书流程先过滤 machine name 为 `AltForge*` 或历史 `AltStore*` 的托管证书，再用服务端 machine identifier 解密本机 P12，并要求序列号一致。缓存不可复用时只允许用户明确替换托管证书；没有托管证书时直接请求创建 `AltForge` 证书，失败则返回错误，不撤销任意 `certificates.first`。该边界保护 Xcode 与团队成员的签名资产。

### `DES-017` macOS 单设备安装事务与 Release 下载

`AppDelegate` 以设备 identifier 保存单次运行期安装 activity。认证、远程 IPA、本地 IPA、签名和设备写入共用这一锁；重复点击同一设备不创建第二条链路，只把认证窗口或现有进度窗口带到前台。失败、用户取消或认证窗口关闭时删除 activity；成功时底层事务立即结束，但用于持有完成窗口的 UI activity 保留到用户关闭窗口。不同设备仍可各自执行，但每台设备最多一条任务，字典规模受当前连接设备数限制。

Apple ID 认证成功后关闭凭据窗口，并立即显示独立原生进度窗口。安装管理器通过显式 callback 报告团队查询、设备注册、证书、设备准备、IPA 下载、描述文件、签名和安装阶段；下载使用独立 `URLSessionDownloadDelegate` 的 `didWriteData` 实际字节回调，最多每 0.1 秒向 UI 提交一次且保证完成样本，设备写入继续使用底层 `NSProgress`。全宽进度条不为隐藏的百分比标签预留右侧列；下载信息放在独立行，使用 `ByteCountFormatter` 显示已下载量、总大小和指数平滑后的即时速度。下载源选择器由线程安全的单任务 control 连接 UI 与 URLSession，切换时增加 generation、取消并释放旧 transfer/session，只接受当前 generation 的 completion，避免旧回调覆盖新下载；任何迟到成功文件立即删除。窗口不记录账号、UDID、证书或签名材料。设备 installation_proxy 返回 `Status == Complete` 时无论是否仍携带百分比都把子进度置满并完成底层事务；进度窗口切换为简洁的完成状态，仅此时显示默认的本地化“关闭”按钮并启用原生标题栏关闭按钮，两者复用同一受控 close path；设备级 UI activity 保留到用户关闭窗口，避免固定延迟让结果一闪而过。失败时先关闭进度再进入既有结构化错误窗口。

官方 source 仍选择 tag 固定的 `github.com/legeling/AltForge/releases/download/.../AltForge.ipa`，并携带发布时生成的 size/SHA-256；旧 metadata 缺失时再以固定 GitHub API 查询同名 asset。当前版本可以声明最多四个经过 HTTPS 结构校验的 `downloadMirrors`，其中仓库 Actions 变量生成的自有 CDN 排在自动线路首位；随后是 GitHub 和两个固定 HTTPS 反向代理。用户也可选择单一线路立即重启下载。所有镜像下载后以 1 MiB 流式块计算 SHA-256，并同时校验文件大小，任何不匹配都失败，绝不解压。自动尝试数上限为配置 CDN 4 个、GitHub 1 个和固定公共镜像 2 个，始终顺序执行；请求 idle timeout 为 45 秒、总资源 timeout 为 600 秒。时间复杂度为 `O(sum(attempted download bytes))`，额外内存为 `O(1 MiB)`，临时文件与 delegate session 在成功、失败和线路切换时释放。

### `DES-018` iOS App Group 数据迁移降级

`FileManager.altstoreSharedDirectory` 是 App Group 可用性的唯一运行时真相：Info.plist 中的 `ALTAppGroups` 只表示候选 identifier，不能证明当前 provisioning profile 和系统 sandbox 已授予 container。`DatabaseManager` 在任何 `NSFileCoordinator` intent、Core Data migration、删除或目录替换之前同时要求迁移偏好开启且 shared container URL 非空。

免费开发者或其他重签环境无法解析 container 时，`PersistentContainer` 与 `InstalledApp` 保持既有 application-support fallback，启动按普通沙盒路径继续；迁移偏好不清除，以便未来获得有效 entitlement 后再尝试。即使运行期 container 解析状态发生变化，标准化后的数据库与 Apps 源/目标路径必须分别不同，否则整次迁移无写入返回。判断与路径比较均为常数成本 `O(1)`，不新增复制、轮询或重试。

### `DES-019` iOS 主导航收敛

主 `UITabBarController` 只装载浏览、来源、我的 App 和设置四个入口，并将浏览作为默认首屏。聚合资讯场景及其主导航关系从 `Main.storyboard` 删除，`Tab` 枚举顺序与 storyboard relationship 顺序保持一致，避免删减后 deep link 选中错误标签。

资讯仍是 AltStore source 格式的一部分，因此不修改 `NewsItem`、Core Data model、source decoder 或来源详情页面。这样第三方 source 继续兼容，用户仍可在具体来源中查看有上下文的公告，同时避免一个内容重复且价值较低的全局聚合页。启动只实例化四个主导航 controller，时间与额外空间均为 `O(1)`；source 同步复杂度不变。

浏览页不是官方资讯或 Release 列表，而是第三方 source 的发现层：按最近更新、类别和各 source 精选关系读取现有 Core Data 对象，并继续排除 AltForge 自身以避免把当前客户端当作可重复安装的商店内容。聚合结果为零时用单个 `RSTPlaceholderView` 覆盖空分区标题，明确说明内容来自软件源，并通过“管理软件源”切换到来源标签；加载中和失败分别显示进度或恢复提示。空状态判断读取 composite data source 的 `itemCount`，每次 source 合并或页面出现执行 `O(1)` 判断，不增加网络请求、数据复制或持久化。

### `DES-020` iOS 品牌与设置语义颜色

主 tab 在 `TabBarController` 统一覆盖 storyboard 的历史图片，分别使用 bag、source stack、app grid 和 gear 的 SF Symbols，并提供 selected variant。图标表达功能而非品牌，因此不复用 App 图标或上游自定义 SVG。

官方来源色与交互强调色分离：`Primary` 用于交互强调，`SourceTint` 是对大面积卡片降低亮度后的 token。官方 source ID 与 AltForge bundle ID 在展示层强制使用 `SourceTint`，避免本地 Core Data 缓存或旧 Release metadata 改变官方品牌色；第三方 source/app 仍尊重自己的 tint。`DES-023` 在此 token 边界上加入用户主题解析，并让 Release metadata 使用默认锻造红作为兼容值。

设置 controller 使用 `systemGroupedBackground`、`secondarySystemGroupedBackground`、`label`、`secondaryLabel` 和 `separator`，不再用旧青色作为整页背景。版本只读取 bundle 的 `CFBundleShortVersionString`，确保与 Xcode/release contract 的当前版本真相一致。Credits 将 AltForge Contributors 标为维护者，同时保留 Riley Testut 和 Caroline Moore 的上游贡献归属；项目 GitHub、Issue 和隐私仍归本仓库。所有操作均为固定规模 UI 配置，不新增 I/O 或网络请求。

设置的 storyboard/XIB 只允许在 system color 资源定义中保留设计期 fallback，不允许控件自身使用固定白色/黑色。主页、许可证、刷新记录、错误日志、兼容账号和应用图标页面统一使用系统分组背景；导航标题、正文、次要说明、分隔线及高亮分别使用 `label`、`secondaryLabel`、`separator` 和 `tertiarySystemFill`。应用图标列表使用原生 inset-grouped cell、主题色 checkmark 和语义按下态；调用 `setAlternateIconName` 后只在目标行显示原生 activity indicator，不禁用 collection。回调后扫描当前可见 cell 并通过 `reconfigureItems` 更新旧/新两行，避免 `reloadData` 引起整页重建和滚动位置变化，同时用选择及成功/失败触感补足异步反馈。图标清单固定为九项，回调扫描时间为 `O(visible icon count)`、额外空间为 `O(visible icon count)`，上限均为九；不新增缓存或网络请求。冰霜、纸白、霓虹和蓝图由仓库脚本从正式透明品牌模板确定性生成 1024px 无 alpha PNG；钛金属、光学玻璃和陶瓷珐琅保留项目自有 1024px 权威源图，并由统一品牌脚本确定性复制到 Icon Composer bundle。

### `DES-021` iOS 公开身份与内部兼容边界

主应用 Info.plist 固定 `CFBundleDisplayName` 和 `CFBundleName` 为 `AltForge`，AltStore target 的 Debug/Release build settings 固定 `EXECUTABLE_NAME = AltForge`。AltTests 的 `TEST_HOST` 继续定位 `AltStore.app`，但加载其中的 `AltForge` executable。这样系统崩溃报告与进程身份使用 AltForge，同时不改 target/scheme、Swift module、产品包目录和 Release 中的 `Payload/AltStore.app`，避免 storyboard module、现有脚本和上游同步产生大范围兼容风险。

公开品牌扫描只检查 storyboard/XIB 的用户属性和 string catalog 实际显示值，不机械替换符号、文件名、协议、数据库、URL scheme、第三方 source、AltStore PAL/2.0 或上游归属。新证书、新 App Group 和导出 UTI 使用 AltForge；证书读取同时接受 AltForge 和旧 AltStore 前缀，以保证升级兼容。AltSign submodule 的历史本地化 key 保持不变，由主 App catalog 提供 AltForge 显示值。运行时额外成本为 `O(1)`；回归扫描为 `O(resource bytes)`。

### `DES-022` iOS 安装恢复日志与认证界面

设置页不在 `UITableViewDelegate.willDisplay` 中递归修改任意子视图；页面背景、导航、已知 label、cell 和 separator 使用 UIKit 语义色，避免对 UIKit 私有视图发送未支持 selector。认证 storyboard 同样使用 `systemGroupedBackground`、`secondarySystemGroupedBackground`、`label`、`secondaryLabel`、`tertiaryLabel` 和 AltForge `Primary`，并把凭据用途说明放在表单之后的固定间距，而不是压到超长页面底部。

My Apps 的 collection supplementary view 只能在 UIKit 的 data source callback 中 dequeue。Flow-layout 尺寸计算使用独立 XIB prototype，不得为了 Auto Layout 测量而直接调用 `viewForSupplementaryElementOfKind`；否则新版 UIKit 会发现有复用对象未被返回并主动断言退出。

签名继续由 `Dependencies/AltSign` 的 ldid 层处理。架构映射覆盖 iOS 主程序的 `arm64` 与 IPA 中可能携带的 Apple Watch `arm64_32` Mach-O，两者使用既有 16 KiB 对齐；每个已识别架构必须向 progress 提供非空名称。AltStore Classic 不支持为 Apple Watch companion 注册、配置和安装独立 profile，因此 iPhone 侧载副本在修改 Info.plist 和签名前移除顶层 `Watch/`，原始下载文件不变。未来遇到未识别 CPU type、无 prepared entitlement、非法 UTF-8 或不可表示的文件系统路径时，在写回前抛出可由 `ALTSigner` 捕获的 `runtime_error`，不得把 Objective-C `nil`/C `NULL` 隐式转换为 `std::string`。回归使用 Xcode watchOS SDK 生成最小 `arm64_32` 可执行文件并执行真实 ldid 签名，同时篡改一份 CPU type 验证未知架构安全失败；fixture 和编译产物只存在任务临时目录并在退出时删除。

`AuthenticationOperation.fetchTeam` 保留现有确定性顺序：优先复用仍存在的 active team，否则依次选择 individual、organization、free 和首个未知团队；设置页从持久化 active team 显示实际名称、Apple ID 和本地化账号类型，不从 GitHub 仓库或维护者身份推断 Apple developer team。

手工导入 IPA 时，“我的 App”顶部使用 92 point 稳定高度的非卡片状态带，通过 `Progress` KVO 显示整体百分比，通过 `RefreshGroup` 的主线程状态回调显示当前阶段和有界详情。状态带只持有一个 KVO token 和最新阶段，更新为 `O(1)`；安装结束后释放 observation、恢复 collection inset 并重新开放导入按钮，不生成进度历史或后台轮询。

解包后如果 `ALTApplication.appExtensions` 非空，以名称排序并最多展示前四项，用户在继续前必须显式选择剔除或保留并签名。剔除为免费账号的默认推荐动作，但同时披露可能失去小组件、分享、通知等扩展功能；保留会为每个 extension 创建 App ID/profile 并占用相应限额。剔除仅作用于本次解压工作副本和 `SC_Info/Manifest.plist` 中的 `PlugIns/` 复制路径，原 IPA 不变；处理成本与 extension 数量及目录大小线性相关，不引入新依赖。

AppManager 在操作进入队列前创建值快照，并把最多 20 条 pending operation 原子写入 Application Support 下的 JSON journal；UserDefaults 只在受保护存储暂时不可用时作为兼容 fallback。每条记录带随机客户端诊断编号，以及最多 16 个 `{relative date, stage, bounded detail}` 事件；阶段只覆盖查找 Server、认证、准备/验证 App、准备描述文件、签名、发送、设备安装、刷新和终态，不记录进度回调的每个百分比。detail 最长 120 个字符，允许 USB/Wi-Fi/本机连接类别、Apple 团队类别、已移除的 Watch 组件类别，以及 ldid 提供并经控制字符、父目录和前导路径清理后的最多四段 bundle 相对路径与架构。连续签名 checkpoint 替换最后一条签名事件，不挤占 16 阶段历史；只记录 bundle/Mach-O checkpoint，不为普通资源逐项落盘。失败时把诊断编号、最后一个非终态阶段和相对耗时轨迹作为 `NSError.userInfo` 字符串写入既有 `LoggedError`，不修改 Core Data schema 或 Server Protocol；错误详情可查看这些字段，复制操作输出一个有界诊断报告。

App lifecycle 另以两个固定大小的原子 JSON 保存 current/interrupted foreground session，只记录随机 session ID、时间、active 状态和预定义页面 checkpoint。若启动时同时存在 pending operation，则只生成更具体的 operation recovery 日志并消费 session 记录；只有没有 pending operation 时才生成一条 runtime 意外退出日志。第三方 IPA completion 显式区分 success/error/missing-result，missing-result 转普通 `OperationError`；AltSign 对所有来自 IPA `Info.plist` 的可选字符串、字典和数组元素先做类型验证，畸形字段不得进入 Objective-C 异常路径。

AltForge Server 的设备安装 KVO progress 与 terminal success/failure 共用单一串行 response coordinator，不允许两条异步路径同时写入 framed connection。Coordinator 最多保留一个 pending progress、一个 terminal result 和一个在途标记；普通进度只合并为最新值，terminal 覆盖未发送进度并等待在途 frame 完成后唯一回调外层 completion，因此空间和排队成本均为 `O(1)`。非终态进度限制在 `0...0.99`，只由外层 completion 发送最终 `1.0`；iOS 客户端拒绝 NaN 和负值，并把有限的 `>= 1.0` 视为完成。只有收到该终态响应后，operation 才结束并保存 `InstalledApp`；不使用超时猜测设备安装成功，也不修改 Server Protocol schema。

成功完成后消费 pending record；失败时必须先把正常错误日志保存成功再消费，保存失败则保留到下次启动。应用下次在数据库启动成功后读取遗留记录并生成一次 `LoggedError`，只在日志落库成功后删除记录，说明上次进程在结果落库前结束。记录允许 App 名称、bundle ID 和上述脱敏相对签名对象，但不包含 Apple ID、密码、验证码、UDID、团队 ID、Server 名称/ID、证书、profile 内容或文件 URL。错误关系解析仅允许永久 object ID，并通过 throwing `existingObject(with:)` 查询；temporary ID 或已删除对象使用 `AnyApp` 快照。单次 append/replace 为 `O(k + e)`，`k <= 20`、`e <= 16`，总持久化空间有固定上限；Watch 检查和移除为一次 `O(1)` 路径查询与受该目录大小约束的文件删除，签名 checkpoint I/O 与 Mach-O 数量线性相关且不增加资源扫描。架构识别保持每个 Mach-O slice `O(1)`。不新增网络 I/O、后台进程或跨端协议字段。

### `DES-023` iOS 动态主题色

`AltTheme` 位于 AltStoreCore 的既有 UserDefaults 扩展边界，使用四个稳定 raw value，并由 `preferredTheme` 负责默认值、持久化和非法值回退。`UIColor.altPrimary` 与 `altSourceTint` 从当前偏好按深浅模式动态生成，不再把一次性 asset lookup 当作运行时主题真相；颜色 asset 与 Release metadata 只保留锻造红默认/兼容值。

应用 window root 是 `LaunchViewController`，主 tab 是其直接 child。主题通知更新 window tint 后必须定位该 child 并调用 `TabBarController.applyTheme()`，使当前导航、标签栏、徽标和已加载内容立即刷新；不能只对 root 做类型转换。

设置页在现有 Display 静态分组加入一行，并 push 原生 inset-grouped table。每个候选使用固定 24 point 圆形色板、文本和 checkmark，不新增第三方 UI。选择后写偏好并发送进程内通知；UIApplication 只更新已知 window、navigation bar 和 tab bar，Settings 自己 reload data，不递归遍历 UIKit 私有层级。

`effectiveTintColor` 是 source、app 和 news 的统一展示策略：官方 source ID、AltForge bundle ID 及其资讯强制返回动态 `altSourceTint`，避免 Core Data 缓存或旧 Release metadata 的红色继续污染已选择的蓝色、靛蓝或玫瑰主题；第三方 metadata tint 路径保持不变。可复用的 banner、news cell 与 source header 监听主题通知并只重配当前对象，App 详情重载可见内容；权限确认、补丁页、添加来源、通用详情背景和文本改用 UIKit 系统语义色，交互控件使用 `altPrimary`。红、绿、黄只用于删除/失败、成功/有效期和警告状态。一次主题变化只遍历系统有界的已加载 window 和可见 view/cell，时间为 `O(v)`、额外空间为 `O(1)`；不新增网络、磁盘 I/O 或后台进程。

### `DES-025` 静态官网与 Release 单一数据源

`website/` 是不依赖框架、包管理器和服务端运行时的静态交付面。`index.html` 保留完整的中英文下载、安装、安全边界和支持入口；`app.js` 只负责本地语言偏好、用户平台识别与从本仓库 latest Release API 读取当前版本。读取失败时显示不含版本号的“最新”并保持全部链接可用；DMG、ZIP 与 IPA 始终使用本仓库稳定的 `releases/latest/download/<artifact>`，网页不复制发布二进制、不代理 Apple 账号、不建立另一套版本或下载控制面。

页面采用移动优先的语义 HTML/CSS，以系统字体、锻造红、青色辅色与仓库品牌图构建克制的下载工具界面。CSS 使用语义 token 同时定义浅色/深色、可见 focus、44px 交互区域和 reduced-motion；布局以 320/375/768/1024/1440px 为验证断点，固定格式图标使用显式尺寸和 aspect ratio。品牌图从 `docs/assets/brand/` 通过既有生成脚本复制，避免 website 产生不可追溯副本。

Cloudflare Pages 只托管 `website/` 静态目录；`_headers` 限制脚本、连接、frame 与高风险浏览器权限。部署使用有界的 Wrangler Direct Upload，生产分支标记为 `marketplace`，不改动 GitHub tag-only Release workflow。请求成本为一个 HTML、一个 CSS、一个小型 JavaScript 和三张有界图片；版本请求仅一次、无轮询，时间与内存均为 `O(1)`。部署失败保留上一版本，回滚使用 Pages deployment history或重新部署已知提交的 `website/`。

### `DES-026` 官网工业编辑视觉与仓库联动

首屏改为单一全幅品牌图：`altforge-hero.jpg` 以规范 AltForge 标记为参考，使用石墨、白色陶瓷、锻造红与信号青材质，只在右侧保留一个可识别标记，左侧低细节区域承载标题、Release、平台下载与 GitHub 源码操作。页面不再加载玻璃/钛金属双图标舞台、悬浮版本卡或分栏预览；`design-system/altforge-website/MASTER.md` 记录视觉 token、资产来源和禁止模式。下方依次使用仓库归属信息带、平台下载列表、三步安装流程、深色能力带与 FAQ，页面区段不嵌套卡片，固定控件均有稳定尺寸。

现有 Cloudflare `altforge` 是 Direct Upload 项目且不能原地切换为原生 Git integration，因此 `.github/workflows/website.yml` 使用官方 Wrangler Action 把仓库提交与原 Pages 项目连接。PR 和 `marketplace` push 总是运行 HTML/CSS/JS/仓库契约；生产 deploy job 额外要求仓库变量 `CLOUDFLARE_PAGES_DEPLOY_ENABLED=true` 与 `CLOUDFLARE_ACCOUNT_ID`、`CLOUDFLARE_API_TOKEN` Secrets，缺失时跳过而不尝试宽权限本地 OAuth 凭据。工作流只上传固定 `website/` 目录，10 分钟超时、同 ref 有界并发；回滚仍可重新部署已知提交或使用 Pages deployment history。

首屏图片约 1774 × 887，JPEG 控制在 2.5 MB 内；页面加载量保持固定，版本 API 使用 8 秒超时、单次请求且不重试，总体时间/空间与网络扇出为 `O(1)`。系统字体避免第三方字体请求，CSP 不新增 host。

动效只承担层级与操作反馈：hero 图片和标题在首次载入时完成一次有界入场，仓库信息顺序出现，后续标题、平台行、流程、能力与 FAQ 使用 `IntersectionObserver` 在首次进入可见区时增加小幅透明度/位移过渡并立即取消观察；按钮图标、FAQ 指示与平台标记只在 hover/open 时反馈。不读取鼠标坐标、不持续监听滚动、不改变布局尺寸。未运行 JavaScript 时内容保持完整可读，系统 reduced-motion 下所有 animation/transition 近似即时完成。观察节点数随页面组件线性增长，时间与额外空间为 `O(n)`，当前固定页面规模有界。

### `DES-027` Apple 认证客户端身份与响应边界

AltForge Server 继续在 `AnisetteDataManager` 生成或规范化 Apple 认证所需的设备描述；Mac model、macOS version 和 build 来自当前 `ProcessInfo`。AltSign 单点定义当前 Xcode 27 beta 6 产品/build `27.0 (27A5252f)` 与已由上游登录 harness 验证的 bundle version `25183.54.10`，认证、2FA、Developer Services、AOSKit、XPC 与 Mail plug-in 共用这组身份；GSA User-Agent 同时读取运行系统的 CFNetwork 与 Darwin 版本，避免 Apple 将真实当前系统与 2018-2019 年客户端标识判为不一致。该变化不修改 machine ID、one-time password、local user ID 或 routing info，也不增加认证请求、重试或持久化。

`ALTAppleAPI.sendAuthenticationRequest` 仍只解析 Apple 的 plist 响应。URLSession 错误优先返回；响应不能解析为预期 plist/Response/Status 时，统一转换为 `authenticationHandshakeFailed`，底层解析错误仅作为 `NSUnderlyingErrorKey` 保留。不得打印、持久化或复制响应正文，因为 HTML 拦截页可能包含识别信息。一次认证仍为既有有限 SRP 请求序列，新增判断为 `O(1)`，无额外网络 I/O、缓存或长期资源。

### `DES-028` 统一错误展示与跨平台编码

`NSError.userFacingPresentation` 是用户界面的唯一通用错误展示适配层，输出短标题、具体原因和可选恢复建议。Apple API、AltSign、Server 与 Connection provider 错误先移除远端固化的本地化字段，再由客户端 provider 使用当前语言和保留的结构化 userInfo 重新生成；本地业务错误继续使用各自 code 的 `errorFailureReason`。`NSURLErrorDomain` 与 `NSCocoaErrorDomain` 只覆盖稳定且可判定的网络、文件和解析 code，其余保留真实系统原因并使用保守建议。

错误详情继续保存 domain、display code、底层错误、诊断阶段和原始进程输出。主提示不再拼接源码位置、debug description 或命令输出。AltSign 公开枚举显式覆盖 Windows 已存在的签名错误 5-7，并把 Apple API invalid response 固定为 3022；Windows 3013-3017 与 Apple 平台重新对齐。所有判断均为固定 switch，单次展示 `O(1)`，不增加网络 I/O、重试、缓存或协议字段。

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
