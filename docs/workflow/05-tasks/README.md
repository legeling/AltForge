<p align="center">
  <img src="../../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Current Tasks

## 优先队列

| Task | 状态 | 关联 | 完成标准 |
|---|---|---|---|
| `T-044` 修复官方源权限声明与 201 提示 | v2.4.7 已发布 / 真机更新待确认 | `FR-046`; `DES-031`; `TEST-045` | 全部 29 项 hosted XCTest、7 项 Python、三端构建、下载包 checksum/身份/版本和公开 source 与 IPA 隐私核对通过；旧客户端实际更新继续验收 |
| `T-043` 修复 iOS 安装漏记与不可见进度 | v2.4.6 已发布 / 设备验收待完成 | `FR-044`, `FR-045`; `DES-030`; `TEST-043`, `TEST-044` | 本地 28 项分批测试及全部 28 项 hosted XCTest、三平台构建、下载包身份/版本/校验和验证通过；真机最终回执丢失、锁屏恢复及刷新由 ISSUE-20260905-003 继续验收 |
| `T-001` 建立 AltSign Unicode archive/App ID 自动化 fixture | Pending | `FR-004`, `FR-005`; `DES-005`; `TEST-003`, `TEST-005`-`TEST-007` | 测试入库并覆盖 UTF-8、Unicode extra、GBK、traversal、round trip |
| `T-002` 验证干净 checkout CI 构建 | In progress | `FR-014`; `DES-009`; `TEST-011`, `TEST-012` | iOS Simulator、source ID test、AltServer build 通过，失败依赖有记录 |
| `T-003` 执行脱敏真实设备安装 smoke | Pending | `FR-001`-`FR-003`; `DES-001`-`DES-003`; `TEST-002` | 英文与中文 fixture 均安装/启动，结果进入 verification |
| `T-004` 完成简体中文 per-app language UI matrix | In progress | `FR-006`, `FR-007`; `DES-006`; `TEST-008` | 仓库维护的 13 份 catalog 已完成非空、占位符和机器直译术语门禁；核心导航、安装、错误、设置、Widget 的双语言无截断矩阵待完成 |
| `T-005` 维护官方 source identity 测试 | Done | `FR-009`, `FR-010`; `DES-007`; `TEST-009` | 当前 URL 断言已存在 |
| `T-006` 维护错误序列化回归 | In progress | `FR-011`; `DES-008`; `TEST-010` | 本地/远端 error bridge 在英文和简体中文环境均通过 |
| `T-007` 为 release metadata 添加 dry-run contract test | Done | `FR-015`, `FR-016`; `DES-010`; `TEST-013` | size/hash/schema/Windows artifact/缺失参数已有自动化断言并进入 Release preflight |
| `T-008` 补 refresh cancellation 与部分失败测试 | Backlog | `FR-008`; `DES-001`-`DES-003`; `TEST-015` | 覆盖 `ISSUE-20260811-006` 的 refresh、停用、备份、部分失败和清理，不产生错误成功状态或遗留临时资源 |
| `T-009` 建立 AltJIT 支持矩阵 | Backlog | `FR-012`; `DES-003`; `TEST-014` | 系统/设备/DeveloperDisk 前置条件可查，并覆盖 `ISSUE-20260811-004` 的运行时、动态端口和多 PID 风险 |
| `T-010` 移植低风险上游维护修复 | Done with manual gap | `FR-008`, `FR-011`, `FR-017`; `DES-003`, `DES-008`; `TEST-016`, `TEST-017` | 组织团队 fallback、到期天数下限、错误详情选择完成双目标构建验证 |
| `T-011` 迁移 AltSign Classic 基线 | Pending | `FR-001`, `FR-002`; `DES-003`, `DES-009`; `TEST-002` | fork 基于 upstream Classic、重放 Unicode 修复、真机认证安装通过并更新 gitlink |
| `T-012` 集成 Windows AltServer 单仓库交付 | In progress | `FR-018`, `FR-019`; `DES-011`; `TEST-018`, `TEST-019` | 源码/固定依赖/CI/Release ZIP 已定义；`ISSUE-20260811-005` 跟踪 Windows USB/Wi-Fi discovery 与真实设备验证 |
| `T-013` 收敛 tag-only 构建与统一版本 | In progress | `FR-020`; `DES-010`; `TEST-020` | 普通 push/PR 不构建，tag/version contract 自动校验，三平台标签构建通过 |
| `T-014` 收敛发布审核与更新独立性 | In progress | `FR-021`-`FR-024`; `DES-012`; `TEST-021`-`TEST-024` | Draft gate、历史 source、自有远程配置、更新判断和用户入口通过本地 contract，真实 Draft 待标签验证 |
| `T-015` 建立 macOS DMG 与本地安装验证 | In progress | `FR-025`; `DES-013`; `TEST-025` | CI 使用共用 DMG packager，本机完成 build/package/mount/bundle、520 × 300 hidden-chrome screenshot 与用户视觉确认；真实 tag 和 Developer ID/notarization 待完成 |
| `T-016` 收敛 AltForge Server 菜单与设置 | In progress | `FR-026`, `FR-027`; `DES-014`; `TEST-026` | build product/executable、扩展 About/GitHub 入口、公开身份、连接方式、安装图标、菜单内设置、更新与双语通过 build/static；系统登录项提示、新版 About 截图、`ISSUE-20260811-005` 实机连接与语言重启待验证 |
| `T-017` 收敛仓库网络所有权 | Done with Windows gap | `FR-028`; `DES-015`; `TEST-027` | 自有控制面均由本仓库发布，外部依赖被准确分类，Developer Disk 索引进入 Release，Classic Fediverse、遗留 plug-in 和默认 OAuth 均 fail closed；contract 与 Apple build 通过，Windows build 待 CI |
| `T-018` 建立 macOS Apple ID 账号与证书管理 | In progress | `FR-029`, `FR-030`; `DES-016`; `TEST-028`, `TEST-029` | 单次 Keychain snapshot、最近账号、团队类型、托管证书保护和六位 2FA 通过 static/build；`ISSUE-20260811-003` 跟踪真实认证、企业团队、2FA、anisette 与证书/UI matrix |
| `T-019` 建立 macOS 单设备安装事务与多线路 Release 下载 | In progress | `FR-031`; `DES-017`; `TEST-030` | delegate 实际字节、installation_proxy Complete、双语关闭按钮、设备级去重、切源取消、CDN/镜像与 size/SHA-256 通过 static/build；修复后真实完成窗口、切源及 `ISSUE-20260811-005` 连接/失败清理待验证 |
| `T-020` 修复 iOS App Group 不可用时首次启动失败 | In progress | `FR-032`; `DES-018`; `TEST-031` | 真实 container gate、same-path 保护、历史失败 contract、iOS build 与 simulator 首次启动通过；重签真机首次启动待验证 |
| `T-021` 收敛 iOS 主导航资讯页 | Done with fixture gap | `FR-033`; `DES-019`; `TEST-032` | 主导航仅保留四个核心标签并默认进入浏览；浏览明确聚合第三方 source 的更新、类别和精选，官方 source-only 时显示可操作空状态；contract/build/simulator UI 通过，第三方聚合 fixture 待补 |
| `T-022` 收敛 iOS 品牌、配色与设置身份 | In progress / visual regression | `FR-034`; `DES-020`; `TEST-033` | 已移除设置主页及子页面控件级固定白色、强制深色系统栏，应用图标扩展为九款并改用非阻塞单行切换反馈，统一“侧载”术语；静态契约、资源检查和 Simulator build 通过，九款实际切换手感待人工复核 |
| `T-023` 修复 iOS 公开身份和 crash-report 名称 | Done with system UI gap | `FR-035`; `DES-021`; `TEST-034` | bundle/executable/test host、公开资源 allowlist、iOS build/build-for-testing 与产物 Mach-O 检查通过；系统 crash-report 标题待真机手工确认 |
| `T-024` 修复 iOS 安装中断崩溃、恢复日志与认证说明 | In progress / device UX validation | `FR-036`; `DES-022`; `TEST-035` | build 18 已包含串行终态响应；当前新增持续阶段/总百分比状态带，扩展数量/名称检查，以及“剔除（推荐）/保留并签名”和免费账号限额提示；自动门禁与真机双分支回归待完成 |
| `T-025` 增加 iOS 主题色选择 | In progress / visual matrix pending | `FR-037`; `DES-023`; `TEST-036` | 默认锻造红、四主题持久化、设置色板、Launch child 即时刷新路径、官方 source/app/news/detail 统一 effective tint、权限/来源页语义色及 raw metadata 绕过门禁已实现；Debug iOS Simulator build 通过，四主题深浅色真机矩阵待完成 |
| `T-038` 建立官网与 Cloudflare Pages 下载入口 | Done | `FR-039`; `DES-025`; `TEST-038` | 同仓库双语静态页面、平台识别、Release latest 下载、版本 metadata fallback、安全响应头与品牌资产生成完成；桌面/移动、深浅色浏览器矩阵与 `https://altforge-dz7.pages.dev` 生产回读通过 |
| `T-039` 重构官网视觉并关联代码仓库 | In progress / hosted deploy secrets pending | `FR-040`; `DES-026`; `TEST-039` | 单一全幅工业品牌图、仓库归属带、下载/流程/能力/FAQ 层级、克制动效和 fail-closed workflow 已实现；production `92c5fb54`、线上 hash/headers/downloads、GitHub homepage、320-1918px 动效/reduced-motion 浏览器矩阵、Git delivery 与 hosted verify `31790637050` 通过。Pages Secrets 与 push 自动部署启用待完成 |
| `T-040` 修复 Apple 认证响应格式失败 | Published v2.4.5 / user-confirmed macOS login | `FR-041`; `DES-027`; `TEST-040` | CHG-20260905-002 已发布；本地及 hosted 17 项 XCTest、三平台 Release 构建、下载校验、包内版本/签名及 public latest 回读通过。用户确认 macOS 登录成功并进入设备准备阶段；完整安装与跨平台账号覆盖继续由 ISSUE-20260904-001 跟踪 |
| `T-041` 统一错误码与用户提示 | Released in v2.4.2 / device UI validation pending | `FR-042`; `DES-028`; `TEST-041` | 全部产品错误域已进入统一标题/原因/下一步展示；provider 重新本地化、跨平台编码 contract、本地/hosted 定向 XCTest 与 Apple/Windows build 通过，已随 `v2.4.2` 交付；真实中文界面及 Windows 设备待验证 |
| `T-042` 建立 macOS 直接下载更新闭环 | Released in v2.4.3 / manual UI pending | `FR-043`; `DES-029`; `TEST-042` | 更新检查直接下载 tag 固定 DMG，显示字节/百分比并支持取消；size/SHA-256 通过后保存到“下载”并自动打开系统安装窗口。Local/hosted build、完整 DMG probe、正式产物 checksum/binary/localization 与 latest 回读通过并发布 `v2.4.3`；旧版本下载/取消/重名/失败/自动挂载 UI 矩阵待执行 |

## Analyze 门禁结果

- 高优先级安装与 Unicode 需求已有 design/test/task 映射。
- `FR-013` 可选 targets 尚无完整测试映射，但不阻塞当前 Classic 核心链路。
- 阻塞自动化的主要缺口是 AltSign 没有独立 test target，以及本地依赖构建尚未完全验证。
- 当前明确使用 Swift 5.0 language mode；未来 Swift 6 migration 需要独立 change。macOS notarization 与 Windows 签名安装器仍是 `[待确认]`，Windows build/device gap 由 `ISSUE-20260809-001` 跟踪。

## 执行规则

- 开始 Task 前创建 `docs/changes/active/<change-key>/`。
- Task 状态变化时同步 verification matrix 与 coverage map。
- P0/P1 Task 完成后必须移动 change 到 completed，并记录实际命令与残余风险。
