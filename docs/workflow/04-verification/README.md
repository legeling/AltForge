<p align="center">
  <img src="../../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Verification Plan

## 验证目标

验证分为四层：纯逻辑单元测试、跨模块集成测试、构建/打包检查、真实账户与设备 smoke test。签名、archive、协议、敏感数据和 release 属于高风险区域，不能只依赖编译成功。

## 需求映射

| Test | 覆盖 | 层级 | 当前状态 |
|---|---|---|---|
| `TEST-001` install operation graph 成功/失败状态 | `FR-002`, `FR-003` | Integration | 缺失 |
| `TEST-002` AltServer 真实设备安装 smoke | `FR-001`, `FR-002` | Manual E2E | 待执行 |
| `TEST-003` App ID ASCII sanitize + Unicode display name | `FR-004` | Unit/Integration | 缺失自动化 |
| `TEST-004` 拒绝无效 app metadata | `FR-003` | Unit | 部分覆盖 |
| `TEST-005` UTF-8 / Unicode Path archive extraction | `FR-005` | Unit | 缺失持久测试 |
| `TEST-006` GBK/GB18030、Big5、Shift-JIS、EUC-KR fallback | `FR-005` | Unit | GBK 手工 harness 通过；未入库 |
| `TEST-007` ZIP path traversal、超长 filename、资源释放 | `FR-005`, `NFR-002`, `NFR-005` | Security/Unit | 缺失 |
| `TEST-008` 简体中文与 per-app language 切换 | `FR-006`, `FR-007` | Static/Build/Manual UI | 13 份 App、Widget、Core、Backup 与 Server catalog 的简体中文完整性、占位符和关键术语静态门禁通过；完整 per-app language 页面矩阵待执行 |
| `TEST-009` Source ID normalization | `FR-009`, `FR-010` | XCTest | 已有 |
| `TEST-010` Error bridge/serialization | `FR-011` | XCTest | 部分通过；简体中文空格断言失败 |
| `TEST-011` AltStore iOS Simulator build | `FR-014` | Build | 本地构建及 source identity 定向测试通过 |
| `TEST-012` AltServer macOS build | `FR-014` | Build | 本地通过 |
| `TEST-013` Release metadata/artifact contract | `FR-015`, `FR-016` | Script/Packaging | 自动化 fixture 已加入 CI |
| `TEST-014` AltJIT 系统/设备前置条件矩阵 | `FR-012` | Unit/Manual | 缺失；上游 Python/pymobiledevice3、动态 RSD 和多 PID 失败证据已同步到 `ISSUE-20260811-004` |
| `TEST-015` Refresh cancellation 与部分失败 | `FR-008` | Integration | 缺失；上游 49 条 refresh/backup/lifecycle 报告已合并到 `ISSUE-20260811-006` |
| `TEST-016` 开发团队选择优先级与组织账户 fallback | `FR-017` | Unit/Manual E2E | 双路径构建通过；真实账户待执行 |
| `TEST-017` 过期应用天数不为负数、错误详情可选中复制 | `FR-008`, `FR-011` | Build/Manual UI | 双目标构建通过；手工 UI 待执行 |
| `TEST-018` Windows AltServer 固定依赖、Release build 和 ZIP contract | `FR-018`, `FR-019` | CI Build/Packaging | CI 已定义；当前 macOS 开发机未执行 |
| `TEST-019` Windows USB/Wi-Fi 安装与刷新 | `FR-018`, `FR-019` | Manual E2E | 待执行；跨平台 discovery/connection 失败矩阵合并见 `ISSUE-20260811-005` |
| `TEST-020` 标签、根版本与三平台产品版本 contract | `FR-020` | Script/Workflow | 本地自动化通过；标签触发行为待下次 Release 验证 |
| `TEST-021` tag-only 与 Draft-only release policy | `FR-021` | Script/Workflow | 静态 contract 自动化通过；真实 Draft 待授权标签验证 |
| `TEST-022` source 固定 URL、历史继承、去重与上限 | `FR-022` | Script/Packaging | fixture 自动化覆盖，最多保留 20 个版本 |
| `TEST-023` AltForge 自有远程配置与安全默认值 | `FR-023` | Script/Static | JSON schema 与 Classic endpoint contract 自动化覆盖 |
| `TEST-024` update/离线 identity 与用户入口 | `FR-016`, `FR-024` | Static/Build/Manual | repository contract、iOS 定向测试/构建与 macOS arm64 Release build 通过；手工入口点击和 Windows build 待执行 |
| `TEST-025` macOS DMG contract 与本地安装 | `FR-025` | Script/Packaging/Manual | 本机 Universal DMG 创建、image verify、挂载、symlink、bundle/version/signature 检查通过；Finder 实测为 520 × 300 bounds、隐藏多余栏位和固定图标位置，第二轮截图与用户视觉确认通过；真实 tag run 待执行 |
| `TEST-026` AltForge Server 身份、菜单与设置 | `FR-026`, `FR-027` | Static/Build/Manual | repository contract 与干净 macOS Debug build 覆盖 `AltForge Server.app`/同名 executable、内部 `AltServer` module、独立 About/GitHub links、菜单内联设置和安装图标；此前 macOS Universal Release、iOS Simulator build 和 preview DMG mount/signature 检查通过；系统登录项提示、新版 About 截图、语言重启和 `ISSUE-20260811-005` USB/Wi-Fi 实机矩阵待验证 |
| `TEST-027` 网络所有权、Developer Disk 索引、Classic Fediverse 与可选 OAuth fail-closed | `FR-028` | Script/Static/Build | repository/release contract、JSON/plist 与 iOS/macOS build 通过；Windows build 未执行 |
| `TEST-028` macOS Apple ID 账号与凭据管理 | `FR-029` | Static/Build/Manual Security UI | repository contract 覆盖单次 credential snapshot 读取/释放、失败保留输入、内联重试、AltSign 错误双语完整性和 Classic SRP 启用条件；macOS build 已编译 CoreCrypto/GSAContext，脱敏 mock 账号/验证码窗口视觉检查通过；上游 2FA/响应格式/anisette 风险已同步到 `ISSUE-20260811-003`，真实矩阵待执行 |
| `TEST-029` macOS 账号类型与证书所有权 | `FR-030` | Static/Build/Manual Security | repository contract 检查团队类型持久化、AltForge owner filter、序列号匹配、显式替换确认及无任意证书 fallback；上游企业团队误分类/拒绝证据已同步到 `ISSUE-20260811-003`，真实 Apple 证书列表、取消零写入和团队协作场景待执行 |
| `TEST-030` macOS 单设备安装与 Release 下载 | `FR-031` | Static/Build/Network/Manual E2E | contract 检查 delegate 实际字节、installation_proxy `Complete`、设备去重、对称进度条、双语关闭按钮、手动线路取消、有限 CDN/镜像、digest 与双超时；hosted build/package、既有 Draft artifact 和本次 macOS Universal Debug build 验证通过；修复后的真实下载进度、完成窗口、线路切换以及 `ISSUE-20260811-005` 断线/失败清理待验证 |
| `TEST-031` iOS App Group migration fallback | `FR-032` | Static/Build/Simulator/Manual E2E | 历史源码回归失败、当前 repository contract、local/hosted iOS build 与 Draft artifact 验证通过；临时 iOS 26.5 simulator 首次启动进入主界面，附加 log 查询返回 65，真实重签设备待执行 |
| `TEST-032` iOS 四标签主导航与来源资讯兼容 | `FR-033` | Static/Build/Simulator | repository contract、storyboard compile 与 iOS Simulator build 通过；临时 iPhone 17 Pro 上默认进入浏览且底栏仅显示浏览、软件源、我的 App、设置，来源资讯兼容由 static/build 覆盖 |
| `TEST-033` iOS 品牌与设置语义色 | `FR-034` | Static/Build/Simulator UI | 用户反馈推翻此前设置子页深浅色结论；现已补齐主页/子页固定颜色扫描、资源解析与 iOS build，完整 Simulator/真机视觉矩阵待重新执行 |
| `TEST-034` iOS 公开身份 | `FR-035` | Static/Build/Manual System UI | bundle/executable/test host 与公开资源扫描通过；系统 crash-report 标题待真机确认 |
| `TEST-035` iOS 安装崩溃、恢复日志与认证说明 | `FR-036` | Static/Build/Simulator/Manual E2E | build 15 系统报告定位 ldid 未映射 CPU type 的架构名称空指针，最符合 Watch arm64_32；真实最小 watchOS Mach-O 签名、未知 CPU 安全失败、repository contract 与完整 iOS Release build 通过，同一第三方 IPA 真机安装待执行 |
| `TEST-036` iOS 主题色选择 | `FR-037` | Unit/Static/Build/Simulator UI | 偏好 XCTest、动态颜色与设置色板 repository contract、Launch child 刷新路径、Swift/XML/JSON 解析和完整 Release-iphoneos build 通过；四主题深浅色即时切换和重启持久化待执行 |
| `TEST-038` 静态官网与 Cloudflare Pages | `FR-039` | Script/Browser/Network | `ruby Scripts/test_website.rb` 与 repository contract 通过；真实浏览器覆盖 320/375/768/1024/1440px、浅色/深色、English/简体中文，无溢出、坏图或控制台错误；生产站 `https://altforge-dz7.pages.dev` 返回安全响应头，在线 Release metadata 显示 2.4.1，latest DMG/ZIP/IPA 均返回 200 |
| `TEST-039` 官网视觉重构与仓库联动 | `FR-040` | Script/Browser/Network/CI | website/repository contract、JavaScript/YAML syntax、HTML 边界与 diff 检查通过；单一 hero、旧双图标移除、仓库归属入口与 fail-closed workflow 由静态 contract 覆盖。Production deployment `92c5fb54` 成功，HTML/CSS/JS/hero 与本地 SHA-256 一致，安全响应头、v2.4.1 API、DMG/ZIP/IPA 200 与 GitHub homepage 通过。本地 Playwright 覆盖 320/375/768/1024/1440/1918px、双语、深浅色、hero/reveal/hover/FAQ 动效、reduced motion、语言持久化与 macOS/Windows 路由，无横向溢出；CSS 失败时 SVG 仍保持有界。提交 `2063c3fd` 与 CI 修复 `e5a7f7f8` 已推送，Actions run `31790637050` hosted verify 通过；自动 deploy 因 Secrets/启用变量未配置而按设计跳过。 |
| `TEST-040` Apple 认证响应兼容 | `FR-041` | Static/Unit/Build/Manual E2E | v2.4.4 (22) 已发布；实际 parser 的 HTML/空字段/401/429/503、错误码保留、双重认证响应、脱敏与序列化回归通过，属于 13 项 hosted XCTest；三平台构建、IPA/DMG 结构版本签名、Windows 版本资源、checksum/latest 回读通过。用户原始错误不能确认为 503，真实登录/2FA/签名安装仍未确认恢复。 |
| `TEST-041` 错误码与用户提示 | `FR-042` | XCTest/Static/Build/Localization | repository contract、iOS 288/macOS 198 条错误文案 zh-Hans 扫描、本地及 hosted 两项定向 XCTest、AltStore/AltServer build 和 Windows hosted build 通过，已随 `v2.4.2` 交付；真实简体中文界面与 Windows 设备验证待执行。 |
| `TEST-042` macOS 直接下载更新 | `FR-043` | Static/Build/Network/Manual UI | repository contract、Swift/PBX/catalog parse、本地 Release build、公开 `v2.4.2` 完整 DMG probe 与 hosted `v2.4.3 (21)` Apple/Windows build、打包/checksum/latest 回读通过；正式 DMG 二进制和简体中文资源包含更新闭环。低版本构建的下载进度、取消、重名复用、失败重试和自动挂载 GUI 矩阵待执行。 |

## 首批高价值失败测试

1. 纯中文 display name 与带英文 extension 名称组合后不产生 leading whitespace App ID。
2. raw GBK `Payload/Test.app/音乐.png` 解压为正确路径。
3. 有效 `0x7075` Unicode Path extra field 覆盖 legacy raw name；CRC 错误时不得盲目信任。
4. `../escape` 和绝对路径 entry 被拒绝，目标目录外无文件。
5. writer 输出中文 filename 时 general-purpose bit 11 已设置。
6. source metadata 中 size/hash 与实际 IPA 一致。

## 实际命令

Release build/test 命令登记在 [回归套件](05-regression-suite.md)。普通 push/PR 不触发自动构建，因此打标签前必须先执行本地版本、metadata 与 repository policy preflight。本地不能访问依赖或没有 simulator 时，必须报告未执行项，不能以 syntax check 代替完整构建。

## 手工真实设备验证

- 使用专用测试 Apple ID，不在截图、日志或文档中记录账号、UDID、certificate。
- 先安装英文基线 IPA，再安装中文显示名/资源 fixture。
- 验证桌面名称、启动、资源读取、refresh 和卸载。
- 记录设备型号、系统版本、AltServer/AltForge commit 和脱敏结果。
- 使用个人、组织和免费测试团队覆盖已保存团队优先级与 fallback；组织账户不可用时记录为外部测试缺口。
- 清理测试 App IDs 无法立即删除时，在记录中注明 Apple quota 残余影响。

## 残余风险

- Apple Developer API 和设备服务无法完全 mock，CI 不能替代真实设备。
- 无标志 legacy ZIP encoding 存在先天歧义，自动检测不能保证所有地区包零误判。
- 当前测试 target 与签名 host app 耦合，独立验证 AltSign 的成本较高。
- release 尚未 Developer ID 签名与 notarize。
- ad-hoc 本地 DMG 只能验证本机安装路径，不能代表其他 Mac 上的 Gatekeeper 或 notarization 体验。
- 首次正式 Release 前，自有 `releases/latest` source/config endpoint 仍会返回 404；真实 Draft 与人工发布流程尚未验证。
- Windows ZIP 尚未执行 hosted runner 和真实设备验证，见 `ISSUE-20260809-001`。
- Windows Developer Disk endpoint 已由静态 contract 覆盖，但本机没有执行 MSBuild；历史 Marketplace/Fediverse 实现只在 Classic 中 fail closed，未来启用仍需自有兼容后端和独立验证。
- 简体中文 simulator 上完整错误测试仍有 12 项因 Foundation 本地化描述的空格规则失败，见 `ISSUE-20260808-007`。
