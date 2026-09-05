<p align="center">
  <img src="../../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Key Behaviors

## iOS 安装记录与可见状态（未发布）

- 设备安装前保留原子恢复记录，成功回执先保存 InstalledApp，再完成操作。返回前台时仅以有效恢复记录、保留的 App.app 与系统正向安装身份恢复漏记；不会根据 App ID 猜测，也不会用暂时缺失的 UTI 删除记录。
- 未确认的缓存保留以避免失去刷新来源；用户明确移除时才同时清除管理记录、恢复文件和缓存。恢复的条目下次刷新走完整重签，不把缓存版本冒充成已确认的设备更新。
- IPA 导入面板显示阶段、聚合进度、耗时、等待状态及可关闭的结果，布局遵循安全区域和大字体。手动安装的常亮租约在终态释放；手动锁屏仍受 iOS 后台限制。取消与无响应超时结束等待，但不声称设备端一定停止安装。
- 主题变化沿用现有 AltTheme 通知，导航/按钮/复用组件不得固定为品牌红；危险操作、错误、到期警告与第三方图标保留自身语义。

## iOS 主导航

- 主标签固定为浏览、软件源、我的 App、设置，并默认进入浏览。
- 不提供跨 source 的聚合资讯标签；source 声明的资讯仍在对应来源详情中展示。
- deep link 通过 `TabBarController.Tab` 选择目标标签，枚举顺序必须与主 storyboard 的 relationship 顺序一致。

## 安装 AltForge

1. AltServer 发现已连接设备并读取设备类型、UDID 和系统版本。
2. 用户选择 Install AltForge，AltServer 获取官方 source 并选择与设备兼容的版本。
3. AltServer 获取 anisette data、认证 Apple ID、选择 team、注册 device、获取 certificate。
4. IPA 被下载到临时位置并解压。
5. AltServer 为主应用和 extensions 注册 App IDs、配置 capabilities、获取 profiles。
6. AltSign 重签 app，设备服务执行安装。
7. 成功或失败后释放 connection、archive handle 与临时文件。

规则：最低系统不满足时可以提示最后一个兼容版本；不能静默安装不兼容版本。

macOS 状态菜单为每个 device identifier 只维护一个活动安装。认证成功后必须显示准备、下载、签名和设备安装进度；重复点击同一设备只聚焦既有窗口。下载阶段显示已下载量、总大小、实时速度和当前线路，允许在自动、GitHub、仓库配置 CDN 与固定公共镜像间切换；线路切换只保留一个 URLSession task。任何镜像 IPA 必须匹配官方 source 或 GitHub Release API 的大小和 SHA-256，校验失败不得进入解压或签名。

macOS 桌面产物的公开目录和 executable 均为 `AltForge Server`；内部 Xcode target 与 Swift module 仍为 `AltServer`。登录时启动使用当前 App 的 ServiceManagement 注册，系统登录项/后台项目提示应显示公开名称。从历史 `AltServer.app` 开发构建升级时，用户需要关闭再开启一次登录项以替换 macOS 缓存的旧注册路径；App 不在后台静默改变这项用户授权。

## 从 AltForge 安装应用

1. 用户从 source 或 Files 选择 IPA。
2. AltForge 验证 app metadata、权限、来源与系统兼容性。
3. `AppManager` 创建 operation graph，下载/读取并准备 app。
4. `FindServerOperation` 发现 AltServer，`SendAppOperation` 发送请求和 payload。
5. AltServer 完成 provisioning、resign、install，并返回结构化结果。
6. 客户端更新 Core Data、active app 状态与 UI。

部分失败规则：在设备安装确认前，不把应用写成成功安装；错误应保留底层原因。

## iOS 数据目录启动

- `ALTAppGroups` 只声明候选 App Group identifier；只有系统返回实际 container URL 时才能开始共享数据迁移。
- 免费开发者或其他重签 profile 不授予 App Group 时，数据库和 Apps 缓存继续使用当前应用沙盒，启动不得因迁移失败而中止。
- 数据库或 Apps 的标准化源、目标路径相同时禁止迁移、删除或目录替换；迁移标记保持未完成，以便未来取得有效 entitlement 后重试。

## Unicode 名称

- `CFBundleDisplayName` 是用户可见名称，可以为中文或其他 Unicode。
- Apple App ID description 是独立字段，必须转换为 Apple 接受的 ASCII；纯 Unicode 名称使用 `App` fallback。
- IPA entry 如果有 UTF-8 flag，按 UTF-8 解码。
- 如果存在有效的 Info-ZIP Unicode Path extra field，校验 filename CRC 后使用其 UTF-8 path。
- 旧式无标志 entry 只接受无损编码检测结果。
- 输出 IPA entry 一律标记 UTF-8。
- 绝对路径或包含 `..` 的 archive path 必须拒绝。

## Refresh

1. AltForge 读取 active installed apps 与 expiration date。
2. 用户触发或 background task 选择需要刷新的 app。
3. 多个 app 可组成 refresh group，但网络和 signing fan-out 必须有界。
4. 每个 app 重新获取 profile、签名并安装。
5. `RefreshAttempt` 记录结果；失败不应删除上一份可用应用状态。

## Source

- Source URL 规范化时忽略 scheme、query、fragment、leading `www`、大小写与重复 slash 的差异。
- 非默认 port 与有效 path 属于 source identity。
- 解析成功后才写入 Core Data；权限或 schema 错误必须可见。
- 官方 source 的 latest download URL 是稳定入口，具体版本信息来自生成的 `apps.json`。
- 官方 source 与 AltForge 自身应用在 UI 中使用仓库定义的 `SourceTint`；该覆盖优先于已缓存 metadata，仅影响官方 identity，第三方 source/app 继续使用自己的 tint。

## iOS 品牌与设置

- 四个主标签使用表达功能的 SF Symbols，不把 App 品牌图标当作来源或设置图标。
- 设置页使用系统动态 grouped/label/separator 颜色，不能再以旧版青色作为整页背景。
- 设置版本来自当前 bundle 的 `CFBundleShortVersionString`，不得由独立静态键覆盖。
- Credits 同时展示 AltForge Contributors、上游原始开发者 Riley Testut 和原始设计 Caroline Moore；AltForge 的 GitHub、Issue 与隐私入口归 `legeling/AltForge`。
- 系统公开身份由 `CFBundleDisplayName`、`CFBundleName` 和实际 executable 共同定义，三者均为 AltForge，避免系统问题报告回退到历史 target 名。
- `AltStore` target/scheme/Swift module、`AltStore.app` 包目录、协议/数据库/历史 identifier 属于内部兼容边界，不应为了视觉品牌做机械重命名；AltStore PAL、AltStore 2.0、第三方 source、上游归属和旧证书识别继续保留真实名称。
- GitHub 仓库地址表示 AltForge 项目的固定维护与发布归属，不用于推断用户的 Apple 开发者身份。认证后从 Apple 返回的团队中优先复用 active team，否则按个人开发者、组织、免费团队、首个未知团队的顺序自动选择，并在设置中显示实际团队名称和类型。
- Apple 认证使用 AltForge Server 提供的 anisette 值；客户端描述必须由当前 Mac model、macOS version/build 与已验证的现代 Xcode client version 组成。Apple 或网络中间层返回 HTML、空内容或畸形 plist 时，流程在 IPA 读取前以认证握手失败结束，只保留底层错误类型，不记录响应正文或任何凭据/anisette 值。
- 安装、更新和刷新进入队列时只持久化最多 20 条脱敏 operation 摘要；每条最多保存 16 个关键阶段和 120 字符 detail。正常结束立即删除，失败时把客户端诊断编号、最后阶段和相对耗时轨迹写入既有错误日志，进程在结果落库前中断时于下次启动补写一次错误日志。诊断只允许连接类别和团队类别等低敏上下文，不保存凭据、设备/团队/Server 标识、签名材料或文件路径。设置、我的 App 和认证页面不得通过递归遍历 UIKit 私有子视图实现动态配色。

## 错误传输

- 本地 error 保留 domain 和 code。
- `ALTLocalizedError` 提供 failure、reason 和 recovery suggestion。
- `CodableError` 只编码允许的数据类型；unsupported userInfo 不跨进程传输。
- 客户端收到错误后优先显示可操作的恢复建议，详细诊断进入 error log。
- 所有可见错误通过 `userFacingPresentation` 生成“标题、具体原因、下一步”；Apple API、AltSign、Server 与 Connection 的远端文案按客户端当前语言重新生成，避免把 Server 端英文固化到中文界面。
- 解析错误、网络错误、认证错误、IPA/签名错误只按真实 domain/code 分类；未知 code 使用不猜测原因的兜底。源码位置、debug description、底层错误和原始进程输出仅进入“更多详情”。
- 诊断轨迹使用客户端生成的 operation ID，只关联本机 AppManager 阶段；当前不改变 Server Protocol，也不宣称能关联 macOS/Windows Server 的独立日志。

## Release

1. 维护者创建 `v<semver>` tag。
2. workflow 在有限 timeout 下 resolve dependencies、构建 iOS/macOS。
3. iOS `.app` 以 `Payload/AltStore.app` 结构打包为 `AltForge.ipa`。
4. Ruby 脚本读取实际文件大小和 hash，生成 `apps.json` 与 `SHA256SUMS.txt`。
5. 只有全部步骤成功后创建 GitHub Release。

## 远程配置与外部服务

- Classic 启动只从最新已公开的 AltForge Release 获取 flags、known sources 和 recommended collections；请求失败时保留本地值或安全默认值，不回退到上游配置。
- macOS 与 Windows AltForge Server 从同一 Release 获取 `developerdisks.json`，再按索引访问经过审核的第三方 disk 文件。索引属于 AltForge，disk 文件仍属于各自提供方。
- 遗留 Mail plug-in 仅可检测和卸载；不会检查、下载或安装上游 plug-in。
- Classic 固定关闭 Fediverse 交互：启动不调度交互更新，source 刷新不查询上游 CloudKit metadata，界面不暴露点赞入口。
- Patreon 默认未配置并隐藏。只有构建者提供自己的 client ID、client secret 和 HTTPS redirect URI 后才允许认证；缺少任一项时必须在网络请求前失败。
- 依赖下载与 Apple 服务保留真实外部地址。仓库归属收敛不等于伪造外部服务的所有权。

## 状态与清理

- 下载 task 完成后删除 URLSession 临时文件。
- 解压/重签使用单次任务临时目录；成功和失败路径均需清理。
- CI 使用 runner temporary directory 和 bounded job timeout。
- 只清理当前任务创建的资源，不终止用户已有 AltServer、VPN、代理或设备服务。
