<p align="center">
  <img src="../../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Requirements

## 用户角色

| 角色 | 主要目标 |
|---|---|
| 最终用户 | 安装、刷新、更新和管理侧载应用，获得可理解的错误信息 |
| 国际用户 | 使用本地化界面并安装包含 Unicode 元数据与资源路径的 IPA |
| 贡献者 | 在不破坏上游结构的情况下实现修复并验证影响范围 |
| 发布维护者 | 生成可追溯、可校验、可供 AltServer 使用的发布产物 |

## 功能需求

### 安装与签名

- `FR-001` 用户必须能通过 macOS AltServer 将 AltForge 安装到受支持的 iOS/iPadOS 设备。
- `FR-002` 用户必须能在 AltForge 中选择或下载 IPA，并通过可用 AltServer 完成认证、App ID 注册、provisioning、重签和设备安装。
- `FR-003` 安装链路必须保留应用 bundle identifier、权限、extension 和版本约束所需的信息，并对不兼容或无效包返回明确错误。
- `FR-004` App ID 注册名称必须满足 Apple 服务的 ASCII 限制，但不得因此修改设备桌面上的 Unicode 显示名。
- `FR-017` 认证返回多个开发团队时，有已保存团队信息的客户端流程必须优先复用；其余情况按个人、组织、免费团队的顺序选择，不能因只有组织团队而中止安装。

### Unicode 与本地化

- `FR-005` 解压和重建 IPA 时必须正确处理标准 UTF-8 ZIP 文件名、Info-ZIP Unicode Path 字段以及常见的旧式东亚编码文件名。
- `FR-006` 简体中文必须可作为应用语言使用，并兼容 iOS per-app language switching。
- `FR-007` 用户可见的新增文本必须进入项目既有的 string catalog 或本地化资源，不得在业务代码中另建第二套本地化机制。

### 刷新、来源与更新

- `FR-008` AltForge 必须跟踪已安装应用与签名到期信息，并在用户触发或系统允许时刷新活动应用。
- `FR-009` 用户必须能添加、读取和更新兼容的 AltStore source，并按稳定 source ID 去重。
- `FR-010` 官方 AltForge source 必须指向本仓库 GitHub Release 的 `apps.json` 与 IPA。
- `FR-033` iOS 主导航必须聚焦浏览、来源、我的 App 和设置，不提供聚合资讯标签页；source 中的资讯数据结构与来源详情内的上下文展示继续保持兼容。
- `FR-034` iOS 主标签必须使用一致的系统语义图标；官方来源和 AltForge 自身卡片必须使用当前官方主题的克制来源色，不得被旧 metadata 覆盖。设置页必须使用可适配深浅色的系统语义颜色，版本必须来自构建产物，并同时展示本仓库维护者、上游原始开发者/设计归属和 AltForge 自有 GitHub、Issue、隐私入口。
- `FR-035` iOS 主应用在桌面、系统问题报告、崩溃报告和其他公开界面中必须显示 AltForge；当前产品与配套服务必须显示 AltForge / AltForge Server。为兼容上游同步和既有数据，内部 target、scheme、Swift module、app bundle 目录、协议标识、数据库名称和历史 identifier 可以继续使用 AltStore，但不得成为系统或用户可见名称。

### 诊断与可选能力

- `FR-011` 客户端与 AltServer 间的失败必须保留错误域、错误码、失败原因和可用恢复建议，同时清理不可序列化或敏感字段。
- `FR-012` 在受支持系统和设备上，用户可请求为侧载应用启用 JIT；不满足前置条件时必须返回明确错误。
- `FR-013` 备份、Widget、Daemon、XPC、Plugin 和 Marketplace 目标必须保持其既有模块边界，不得成为核心安装链路的隐式依赖。

### 构建与发布

- `FR-014` 维护者必须能从递归 submodule、CocoaPods lockfile 和 Swift package resolution 构建 iOS 与 macOS 目标。
- `FR-015` 版本标签必须生成 `AltForge.ipa`、`AltForge-AltServer-macOS.dmg`、`AltForge-AltServer-Windows.zip`、`apps.json`、`flags.json`、`sources.json`、`recommended-sources.json`、`developerdisks.json` 和 `SHA256SUMS.txt`。
- `FR-016` 发布 source 的版本、build、最低系统、下载 URL、大小和 SHA-256 必须与实际 IPA 一致。
- `FR-018` 维护者必须能从同一仓库内的固定上游源码和固定依赖构建 Windows AltServer；Windows 服务必须从本仓库官方 source 下载 `com.legeling.AltForge`。
- `FR-019` Windows Release ZIP 必须包含可执行文件及其运行时 DLL，且不得包含 Apple ID、证书、anisette data、设备标识或 Apple 软件安装包。
- `FR-020` 自动构建和 Draft Release 创建只能由与根目录 `VERSION` 一致的纯数字 `vX.Y.Z` 标签触发；iOS、macOS 与 Windows 必须使用同一产品版本，CI build number 独立管理。
- `FR-021` 标签流水线只能创建 Draft Release；公开发布必须由维护者在核对产物、checksum、版本和已知风险后人工完成。
- `FR-022` AltForge 官方 source 必须保留仍受支持的历史版本，并为每个版本使用不可随 latest release 漂移的 tag 固定下载 URL。
- `FR-023` 能改变 feature flags、可信/封禁 source 或官方推荐内容的远程配置必须由本仓库发布；上游服务只能作为明确披露且不可替代的兼容性依赖。
- `FR-024` 用户可见的支持、隐私、GitHub、FAQ 和桌面发布入口必须指向 AltForge 自有仓库内容；没有自有账号的社交或赞助入口不得冒充上游账号。
- `FR-025` macOS Release 必须使用可挂载 DMG，包含公开命名的 `AltForge Server.app` 和 `/Applications` 快捷方式；首次打开必须使用紧凑、固定的 Finder 图标布局，不得因缺少目录元数据而继承接近全屏的任意窗口尺寸；在 Developer ID 路径落地前，CI 与本地验证必须对 staging App 做 deep ad-hoc 完整性签名，以支持 ServiceManagement 并拒绝不完整的 linker-only signature，但不得冒充 Developer ID 身份或 notarization。
- `FR-026` macOS 桌面端的 `.app` 包目录、Mach-O executable、登录项/后台项目系统提示、About、菜单、通知和错误必须使用 AltForge Server 公开身份，保留 AltForge contributors、上游项目/版权、第三方社区与许可证归属；About 必须提供足够空间并水平居中显示完整的 AltForge GitHub 仓库地址及 Releases、文档和 Issue 入口，可点击链接悬停时必须显示指向手势；内部 target、module 和兼容标识无需批量改名。
- `FR-027` macOS 菜单必须显示设备的 USB/Wi-Fi 连接方式，提供可恢复的检查更新和遗留邮件插件清理文案，并在状态菜单的设置子菜单中直接提供登录时启动、跟随系统、English 和简体中文选项，不额外打开设置窗口；登录启动必须通过系统勾选和“已开启/已关闭/需要批准”文本反馈真实状态，注册失败不得静默；语言变化必须明确提示重启并允许用户立即重启。
- `FR-028` AltForge 自有的更新、远程配置、Developer Disk 索引和用户入口必须由 `legeling/AltForge` 发布；第三方依赖、Apple 服务、Patreon 和 Developer Disk 文件来源必须按真实所有者保留并显式披露。Classic 不得访问上游 Marketplace、Fediverse 或 OAuth 控制面，禁止把外部服务伪装成本仓库服务。
- `FR-029` macOS Apple ID 认证窗口必须支持选择成功认证过的账号、用户明确选择是否记住密码、密码显隐和 Caps Lock 提醒；账号与可选密码只在认证成功后写入本机 Keychain，不得进入 UserDefaults、日志或错误详情，并提供忘记账号的操作。“记住密码”说明必须提醒用户：读取已保存密码时 macOS 可能要求输入 Mac 登录密码进行钥匙串授权，这不是 Apple ID 密码。每次打开窗口最多执行一次用于填充历史账号的 Keychain archive 读取，账号切换必须复用窗口生命周期内的有界快照，并在 modal 结束后释放。成功查询 Apple 团队后，历史账号必须显示最后确认的免费、个人开发者或组织/企业类型，但不得声称持久 Apple 登录状态。窗口必须提供 macOS 原生最小化能力。双重认证必须使用匹配的独立窗口，仅接受六位数字且不得持久化验证码。认证请求期间窗口必须保持显示，失败后保留用户输入、恢复编辑并显示完整本地化的内联错误，只有认证成功或用户主动取消时才关闭。Classic 构建不得使用会禁用 AltSign SRP 认证实现的 Marketplace 编译条件。
- `FR-030` macOS 安装流程不得自动撤销普通 Xcode、分发或其他非 AltForge 证书。只允许复用序列号匹配且持有本机私钥的 AltForge/旧 AltStore 开发证书；替换托管证书前必须说明受影响范围并取得明确确认，新建证书必须使用 AltForge 标识。
- `FR-031` macOS 安装流程在 Apple ID 认证成功后必须持续显示团队、设备、证书、下载、签名和设备安装进度；下载阶段必须使用左右对称的全宽进度条，并根据 `URLSessionDownloadDelegate` 的实际写入字节显示百分比、已下载量、总大小、实时速度、当前线路及手动线路选择。同一设备同一时间最多存在一个安装任务，重复操作只聚焦现有进度。官方 IPA 下载必须有有界超时，并在 GitHub 直连失败后按固定数量尝试 GitHub Release 镜像；仓库可以为 tag 固定版本声明自有 HTTPS CDN，自动模式优先 CDN，手动切换必须取消旧任务且不得并发下载。任何非 GitHub 下载必须以官方 source 或 GitHub Release API 返回的大小和 SHA-256 校验通过后才能解压、签名或安装。installation_proxy 明确返回 `Complete` 时必须完成设备事务并显示可由用户关闭的安装成功窗口，不能依赖终态是否携带百分比，也不能用固定计时器自动隐藏成功结果。
- `FR-032` iOS 客户端只有在系统实际提供 App Group container 时才能迁移数据库与已缓存 Apps；重签后只有 App Group 元数据但无 container 时必须继续使用应用沙盒，禁止删除、替换或移动同一路径，并允许未来取得 container 后重新尝试迁移。
- `FR-036` iOS 设置页、认证页和“我的 App”之间切换不得因展示层动态配色退出，浅色与深色模式都不得用固定前景色造成正文不可读；第三方 IPA 的畸形可选 plist 字段或 operation 无结果结束必须返回普通错误，不得触发异常或 precondition。安装、更新和刷新失败或前台异常退出后，错误日志必须保留有界的客户端诊断编号、失败阶段和相对耗时轨迹，并允许一次复制诊断报告。记录可以包含操作类型、App 名称与 bundle ID、预定义 UI checkpoint、USB/Wi-Fi/本机连接类别、账号团队类别和错误域/代码，但不得包含 Apple ID、密码、验证码、UDID、团队 ID、Server 名称/ID、证书、profile 内容或本地/远程文件路径。Apple developer team 必须沿用账号返回结果自动选择，并在设置中显示实际团队名称与账号类型；认证和工作原理说明必须准确覆盖 USB/Wi-Fi、签名、安装、七天有效期与刷新条件。
- `FR-037` iOS 客户端必须在设置中提供带色板和选中状态的主题色选择，偏好重启后保持并在非法值时回退默认色；默认使用与 AltForge 图标一致的锻造红，页面背景继续使用系统语义色。主题变化必须更新导航、标签栏、徽标和官方 AltForge source/app tint，不得覆盖第三方 source/app 自有 tint。

## 非功能需求

- `NFR-001 Correctness`：兼容性修复不得破坏签名内容、entitlement、provisioning profile 或安装原子性。
- `NFR-002 Security`：Apple ID、密码、证书、private key、anisette data、Cookie、设备 UDID 和生产凭据不得写入仓库、普通日志或发布产物。
- `NFR-003 Compatibility`：当前基线为 iOS 17.4、macOS 11、Windows 10；AltJIT 为 macOS 13。目标变化必须同步 README、build settings、source metadata 和验证矩阵。
- `NFR-004 Performance`：IPA 解压与重建的时间复杂度应为 `O(entries + bytes)`；文件名解码使用单 entry 有界缓冲，不保留整个 archive 的文件名列表。
- `NFR-005 Resource control`：网络请求、CI job、设备操作和并发任务必须有超时或上限；临时下载、解压目录和构建产物必须清理。
- `NFR-006 Maintainability`：优先复用现有 Operation、AltStoreCore model、Shared protocol、AltSign 和 libimobiledevice，不建立重复体系。
- `NFR-007 Upstreamability`：通用修复应与品牌改动分离，便于向 altstoreio/AltStore 或 rileytestut/AltSign 回馈。

## 验收标准

- `AC-001` 给定纯中文 `CFBundleDisplayName`，Apple App ID 注册使用合法 ASCII fallback，安装后的显示名仍为原中文名称。覆盖 `FR-004`。
- `AC-002` 给定包含 `Payload/Test.app/音乐.png` 的 IPA，解压后路径和内容保持一致，重新打包后的 ZIP entry 设置 UTF-8 标志。覆盖 `FR-005`。
- `AC-003` 给定不可解析或路径穿越 ZIP entry，系统拒绝安装并释放 archive/file handle。覆盖 `FR-003`、`NFR-002`。
- `AC-004` 官方 source URL 的 source ID 为 `github.com/legeling/altforge/releases/latest/download/apps.json`。覆盖 `FR-009`、`FR-010`。
- `AC-005` CI 在无代码签名条件下完成 iOS Simulator 与 macOS AltServer 构建，并运行 source identity 测试。覆盖 `FR-014`。
- `AC-006` 语义版本标签生成 `FR-015` 列出的全部预期产物，校验和与文件内容一致。覆盖 `FR-015`、`FR-016`、`FR-019`。
- `AC-007` 错误经过 client/server 序列化后仍保留语义字段且不包含不可安全传输的对象。覆盖 `FR-011`。
- `AC-008` 新增简体中文文本在系统语言和 per-app language 切换后可正确显示。覆盖 `FR-006`、`FR-007`。
- `AC-009` 给定仅有组织团队的 Apple Developer 账户，客户端和 AltServer 均选择该团队；客户端有已保存团队时仍优先复用。覆盖 `FR-017`。
- `AC-010` Windows CI 在 60 分钟上限内恢复六个固定源码仓库和固定 vcpkg manifest，完成 Win32 Release build，并生成通过必需 DLL 检查的 ZIP。覆盖 `FR-018`、`FR-019`。
- `AC-011` 普通 push/PR 不触发 GitHub Actions；标签与 `VERSION` 或任一平台产品版本不一致时，Release 在构建前失败。覆盖 `FR-020`。
- `AC-012` 标签构建成功后只存在 Draft Release，人工发布前 `releases/latest` 不发生变化。覆盖 `FR-021`。
- `AC-013` 给定上一版 source，新 source 首项为当前版本、旧版本保持顺序、每个 IPA URL 固定到各自 tag，重复当前版本不会出现两次。覆盖 `FR-022`。
- `AC-014` Classic 启动读取的 flags、known sources 与 recommended collections 均来自本仓库 Release；空配置不得引入上游远程行为。覆盖 `FR-023`。
- `AC-015` 首次启动时本地 build number 与官方 source build number 一致，不显示伪更新；离线 fallback 显示 AltForge identity。覆盖 `FR-016`、`FR-024`。
- `AC-016` macOS 打包脚本拒绝无效输入和覆盖已有文件，生成可通过 `hdiutil verify` 的 DMG；挂载后 App、Applications 快捷方式、bundle identifier 与产品版本均正确，`.DS_Store` 将首次 Finder 内容区域固定为 520 × 300 pt、隐藏多余栏位并明确放置两个安装项目。覆盖 `FR-025`。
- `AC-017` build product、executable、登录项系统提示、About/菜单/设置没有旧版公开名称；升级旧开发构建后关闭并重新开启登录项会注册当前 App；设备项显示 USB 或 Wi-Fi；语言偏好重启后生效；更新检查在 10 秒内成功或给出手工入口，且只打开合法 GitHub HTTPS Release URL。覆盖 `FR-026`、`FR-027`。
- `AC-018` repository contract 能区分自有控制面与允许的外部依赖：macOS/Windows Developer Disk 索引、Classic flags/source/recommended 配置均来自本仓库 Release，Classic source 刷新和交互更新不会访问上游 Fediverse/CloudKit，遗留 Mail plug-in 不再访问上游更新服务，未配置自有 OAuth 回调时 Patreon 入口 fail closed。覆盖 `FR-028`。
- `AC-019` 给定无历史账号、新账号、八个历史账号、旧版无类型 archive、损坏 Keychain archive、Caps Lock 开启、密码显隐切换、错误密码、握手失败和 2FA challenge，认证窗口保持可操作；失败时账号、密码和记住密码状态不丢失，用户可直接修改并重试，错误与 AltSign recovery 文案不会中英混排。只有 Apple 认证成功后才关闭窗口并以最近使用顺序更新最多八个账号，团队查询成功后显示账号类型，未勾选记住密码时不保存密码，验证码只接受六位 ASCII 数字且不持久化。覆盖 `FR-029`。
- `AC-020` 给定普通 Xcode 证书、可复用 AltForge 证书、私钥缺失的旧 AltStore 证书和混合证书列表，流程只复用序列号匹配的本机证书，只对 AltForge/旧 AltStore 证书显示精确替换确认，取消时不撤销任何证书，任何路径都不得把列表第一张普通证书作为 fallback。覆盖 `FR-030`。
- `AC-021` 登录成功后进度窗口按顺序显示准备账号、注册设备、准备证书、下载、签名和安装；所有阶段的进度条与窗口左右边距一致，下载阶段按 delegate 实际写入字节显示百分比、已下载/总大小、平滑实时速度和当前线路。用户可在自动、GitHub、配置 CDN和两个固定镜像间手动切换，切换时旧下载被取消且只有一条下载任务；镜像下载的大小或 SHA-256 不匹配时拒绝安装。连续点击同一设备不会产生第二条认证、下载或签名链路；设备返回 `Complete` 后即使同一状态仍带 100% 也必须显示完成窗口，该窗口提供本地化关闭按钮和原生标题栏关闭按钮，并保持到用户主动关闭，关闭后可重新发起。覆盖 `FR-031`。
- `AC-022` 给定 Info.plist 含 App Group identifier 但 `containerURL` 返回 `nil` 的重签应用，首次启动不执行迁移、不修改 `Library/Application Support` 且能继续加载数据库；任何解析结果中迁移源和目标相同都必须在文件协调与替换前直接跳过。覆盖 `FR-032`。
- `AC-023` iOS 启动后仅显示浏览、来源、我的 App 和设置四个主标签，默认进入浏览；来源详情仍能解析并展示该来源声明的资讯。覆盖 `FR-033`。
- `AC-024` iOS 四个主标签使用系统图标；官方来源和自身应用卡片使用当前 AltForge 主题的克制来源色；设置页在深浅色模式使用系统分组背景，显示构建版本、AltForge Contributors、上游原始开发者和原始设计，所有项目入口指向 `legeling/AltForge`。覆盖 `FR-034`。
- `AC-025` iOS 构建产物的 `CFBundleDisplayName`、`CFBundleName`、`CFBundleExecutable` 和实际 Mach-O 文件均为 AltForge；AltTests 能加载该 executable。公开 storyboard/XIB/string catalog 不再显示当前产品为 AltStore 或 AltServer，同时仍准确保留 AltStore PAL、AltStore 2.0、第三方 source、上游致谢和旧证书兼容文本。覆盖 `FR-035`。
- `AC-026` 新安装默认显示锻造红；用户在设置中切换四种主题后，色板勾选、导航、标签栏、徽标与官方来源卡片立即更新，第三方 tint 不变，重启后仍保持选择；非法偏好回退锻造红，浅色与深色背景和文字继续使用系统语义色。覆盖 `FR-037`。

## 范围外

- 已签名的 Windows MSI/MSIX、自动更新 feed 和 Apple 软件再分发。
- 绕过 Apple 的账号限制或长期签名机制。
- 在没有凭据方案前承诺 macOS 公证和自动更新渠道。
- 对所有历史编码进行无歧义猜测；旧式无编码标志 ZIP 只能提供受控兼容 fallback。

## 追踪摘要

| Requirement | Design | Verification | Task |
|---|---|---|---|
| `FR-001`, `FR-002`, `FR-003`, `FR-017` | `DES-001`, `DES-002`, `DES-003` | `TEST-001`, `TEST-002`, `TEST-004`, `TEST-016` | `T-003`, `T-010` |
| `FR-004`, `FR-005` | `DES-005` | `TEST-003`, `TEST-005`, `TEST-006`, `TEST-007` | `T-001` |
| `FR-006`, `FR-007` | `DES-006` | `TEST-008` | `T-004` |
| `FR-008` | `DES-001`, `DES-002`, `DES-003` | `TEST-015` | `T-008` |
| `FR-009`, `FR-010` | `DES-007` | `TEST-009` | `T-005` |
| `FR-011` | `DES-008` | `TEST-010` | `T-006` |
| `FR-012` | `DES-003` | `TEST-014` | `T-009` |
| `FR-013` | `DES-004`, `DES-009` | `TEST-011`, `TEST-012` | `T-002` |
| `FR-014` | `DES-009` | `TEST-011`, `TEST-012` | `T-002` |
| `FR-015`, `FR-016` | `DES-010` | `TEST-013` | `T-007` |
| `FR-018`, `FR-019` | `DES-011` | `TEST-018`, `TEST-019` | `T-012` |
| `FR-020` | `DES-010` | `TEST-020` | `T-013` |
| `FR-021`-`FR-024` | `DES-012` | `TEST-021`-`TEST-024` | `T-014` |
| `FR-025` | `DES-013` | `TEST-025` | `T-015` |
| `FR-026`, `FR-027` | `DES-014` | `TEST-026` | `T-016` |
| `FR-028` | `DES-015` | `TEST-027` | `T-017` |
| `FR-029` | `DES-016` | `TEST-028` | `T-018` |
| `FR-030` | `DES-016` | `TEST-029` | `T-018` |
| `FR-031` | `DES-017` | `TEST-030` | `T-019` |
| `FR-032` | `DES-018` | `TEST-031` | `T-020` |
| `FR-033` | `DES-019` | `TEST-032` | `T-021` |
| `FR-034` | `DES-020` | `TEST-033` | `T-022` |
| `FR-035` | `DES-021` | `TEST-034` | `T-023` |
| `FR-037` | `DES-023` | `TEST-036` | `T-025` |
