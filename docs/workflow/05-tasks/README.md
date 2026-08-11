<p align="center">
  <img src="../../assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Current Tasks

## 优先队列

| Task | 状态 | 关联 | 完成标准 |
|---|---|---|---|
| `T-001` 建立 AltSign Unicode archive/App ID 自动化 fixture | Pending | `FR-004`, `FR-005`; `DES-005`; `TEST-003`, `TEST-005`-`TEST-007` | 测试入库并覆盖 UTF-8、Unicode extra、GBK、traversal、round trip |
| `T-002` 验证干净 checkout CI 构建 | In progress | `FR-014`; `DES-009`; `TEST-011`, `TEST-012` | iOS Simulator、source ID test、AltServer build 通过，失败依赖有记录 |
| `T-003` 执行脱敏真实设备安装 smoke | Pending | `FR-001`-`FR-003`; `DES-001`-`DES-003`; `TEST-002` | 英文与中文 fixture 均安装/启动，结果进入 verification |
| `T-004` 完成简体中文 per-app language UI matrix | Pending | `FR-006`, `FR-007`; `DES-006`; `TEST-008` | 核心导航、安装、错误、设置、Widget 无截断或 missing key |
| `T-005` 维护官方 source identity 测试 | Done | `FR-009`, `FR-010`; `DES-007`; `TEST-009` | 当前 URL 断言已存在 |
| `T-006` 维护错误序列化回归 | In progress | `FR-011`; `DES-008`; `TEST-010` | 本地/远端 error bridge 在英文和简体中文环境均通过 |
| `T-007` 为 release metadata 添加 dry-run contract test | Done | `FR-015`, `FR-016`; `DES-010`; `TEST-013` | size/hash/schema/Windows artifact/缺失参数已有自动化断言并进入 Release preflight |
| `T-008` 补 refresh cancellation 与部分失败测试 | Backlog | `FR-008`; `DES-001`-`DES-003`; `TEST-015` | 不产生错误成功状态或遗留临时资源 |
| `T-009` 建立 AltJIT 支持矩阵 | Backlog | `FR-012`; `DES-003`; `TEST-014` | 系统/设备/DeveloperDisk 前置条件可查 |
| `T-010` 移植低风险上游维护修复 | Done with manual gap | `FR-008`, `FR-011`, `FR-017`; `DES-003`, `DES-008`; `TEST-016`, `TEST-017` | 组织团队 fallback、到期天数下限、错误详情选择完成双目标构建验证 |
| `T-011` 迁移 AltSign Classic 基线 | Pending | `FR-001`, `FR-002`; `DES-003`, `DES-009`; `TEST-002` | fork 基于 upstream Classic、重放 Unicode 修复、真机认证安装通过并更新 gitlink |
| `T-012` 集成 Windows AltServer 单仓库交付 | In progress | `FR-018`, `FR-019`; `DES-011`; `TEST-018`, `TEST-019` | 源码/固定依赖/CI/Release ZIP 已定义，Windows runner 与真实设备验证通过 |
| `T-013` 收敛 tag-only 构建与统一版本 | In progress | `FR-020`; `DES-010`; `TEST-020` | 普通 push/PR 不构建，tag/version contract 自动校验，三平台标签构建通过 |
| `T-014` 收敛发布审核与更新独立性 | In progress | `FR-021`-`FR-024`; `DES-012`; `TEST-021`-`TEST-024` | Draft gate、历史 source、自有远程配置、更新判断和用户入口通过本地 contract，真实 Draft 待标签验证 |
| `T-015` 建立 macOS DMG 与本地安装验证 | In progress | `FR-025`; `DES-013`; `TEST-025` | CI 使用共用 DMG packager，本机完成 build/package/mount/bundle 验证并补齐安装指南；Developer ID/notarization 作为独立后续范围 |
| `T-016` 收敛 AltForge Server 菜单与设置 | In progress | `FR-026`, `FR-027`; `DES-014`; `TEST-026` | build product/executable、扩展 About/GitHub 入口、公开身份、连接方式、安装图标、菜单内设置、更新与双语通过 build/static；系统登录项提示、新版 About 截图、实机连接与语言重启待验证 |
| `T-017` 收敛仓库网络所有权 | Done with Windows gap | `FR-028`; `DES-015`; `TEST-027` | 自有控制面均由本仓库发布，外部依赖被准确分类，Developer Disk 索引进入 Release，Classic Fediverse、遗留 plug-in 和默认 OAuth 均 fail closed；contract 与 Apple build 通过，Windows build 待 CI |
| `T-018` 建立 macOS Apple ID 账号与证书管理 | In progress | `FR-029`, `FR-030`; `DES-016`; `TEST-028`, `TEST-029` | 单次 Keychain snapshot、最近账号、团队类型、托管证书保护和六位 2FA 通过 static/build；真实认证/证书/UI matrix 待验证 |
| `T-019` 建立 macOS 单设备安装事务与多线路 Release 下载 | In progress | `FR-031`; `DES-017`; `TEST-030` | delegate 实际字节、installation_proxy Complete、双语关闭按钮、设备级去重、切源取消、CDN/镜像与 size/SHA-256 通过 static/build；修复后真实完成窗口、切源和失败清理待验证 |
| `T-020` 修复 iOS App Group 不可用时首次启动失败 | In progress | `FR-032`; `DES-018`; `TEST-031` | 真实 container gate、same-path 保护、历史失败 contract、iOS build 与 simulator 首次启动通过；重签真机首次启动待验证 |
| `T-021` 收敛 iOS 主导航资讯页 | Done | `FR-033`; `DES-019`; `TEST-032` | 主导航仅保留四个核心标签并默认进入浏览，source 资讯兼容不变，contract/build/simulator UI 通过 |
| `T-022` 收敛 iOS 品牌、配色与设置身份 | Done with device gap | `FR-034`; `DES-020`; `TEST-033` | 系统 tab 图标、官方 tint、动态设置配色、bundle 版本、本仓库入口与上游致谢已通过 contract/build/深浅色 simulator UI；真机视觉矩阵待补 |
| `T-023` 修复 iOS 公开身份和 crash-report 名称 | Done with system UI gap | `FR-035`; `DES-021`; `TEST-034` | bundle/executable/test host、公开资源 allowlist、iOS build/build-for-testing 与产物 Mach-O 检查通过；系统 crash-report 标题待真机手工确认 |
| `T-024` 修复 iOS 安装中断崩溃、恢复日志与认证说明 | In progress | `FR-036`; `DES-022`; `TEST-035` | 系统 crash report 根因移除、跨 context 日志安全、有界脱敏阶段轨迹与复制报告已实现；认证/工作原理双语和 simulator 回归纳入验证，诊断日志 runtime 与第三方 IPA 真机安装待验证 |

## Analyze 门禁结果

- 高优先级安装与 Unicode 需求已有 design/test/task 映射。
- `FR-013` 可选 targets 尚无完整测试映射，但不阻塞当前 Classic 核心链路。
- 阻塞自动化的主要缺口是 AltSign 没有独立 test target，以及本地依赖构建尚未完全验证。
- 当前明确使用 Swift 5.0 language mode；未来 Swift 6 migration 需要独立 change。macOS notarization 与 Windows 签名安装器仍是 `[待确认]`，Windows build/device gap 由 `ISSUE-20260809-001` 跟踪。

## 执行规则

- 开始 Task 前创建 `docs/changes/active/<change-key>/`。
- Task 状态变化时同步 verification matrix 与 coverage map。
- P0/P1 Task 完成后必须移动 change 到 completed，并记录实际命令与残余风险。
