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
| `TEST-008` 简体中文与 per-app language 切换 | `FR-006`, `FR-007` | Build/Manual UI | 待执行 |
| `TEST-009` Source ID normalization | `FR-009`, `FR-010` | XCTest | 已有 |
| `TEST-010` Error bridge/serialization | `FR-011` | XCTest | 部分通过；简体中文空格断言失败 |
| `TEST-011` AltStore iOS Simulator build | `FR-014` | Build | 本地构建及 source identity 定向测试通过 |
| `TEST-012` AltServer macOS build | `FR-014` | Build | 本地通过 |
| `TEST-013` Release metadata/artifact contract | `FR-015`, `FR-016` | Script/Packaging | 自动化 fixture 已加入 CI |
| `TEST-014` AltJIT 系统/设备前置条件矩阵 | `FR-012` | Unit/Manual | 缺失 |
| `TEST-015` Refresh cancellation 与部分失败 | `FR-008` | Integration | 缺失 |
| `TEST-016` 开发团队选择优先级与组织账户 fallback | `FR-017` | Unit/Manual E2E | 双路径构建通过；真实账户待执行 |
| `TEST-017` 过期应用天数不为负数、错误详情可选中复制 | `FR-008`, `FR-011` | Build/Manual UI | 双目标构建通过；手工 UI 待执行 |
| `TEST-018` Windows AltServer 固定依赖、Release build 和 ZIP contract | `FR-018`, `FR-019` | CI Build/Packaging | CI 已定义；当前 macOS 开发机未执行 |
| `TEST-019` Windows USB/Wi-Fi 安装与刷新 | `FR-018`, `FR-019` | Manual E2E | 待执行 |
| `TEST-020` 标签、根版本与三平台产品版本 contract | `FR-020` | Script/Workflow | 本地自动化通过；标签触发行为待下次 Release 验证 |
| `TEST-021` tag-only 与 Draft-only release policy | `FR-021` | Script/Workflow | 静态 contract 自动化通过；真实 Draft 待授权标签验证 |
| `TEST-022` source 固定 URL、历史继承、去重与上限 | `FR-022` | Script/Packaging | fixture 自动化覆盖，最多保留 20 个版本 |
| `TEST-023` AltForge 自有远程配置与安全默认值 | `FR-023` | Script/Static | JSON schema 与 Classic endpoint contract 自动化覆盖 |
| `TEST-024` update/离线 identity 与用户入口 | `FR-016`, `FR-024` | Static/Build/Manual | repository contract、iOS 定向测试/构建与 macOS arm64 Release build 通过；手工入口点击和 Windows build 待执行 |
| `TEST-025` macOS DMG contract 与本地安装 | `FR-025` | Script/Packaging/Manual | 本机 Universal DMG 创建、image verify、挂载、symlink、bundle/version/signature 检查通过；CI IPA/DMG verifier 与 publish checksum gate 已定义，Finder 首次启动和真实 tag run 待执行 |
| `TEST-026` AltForge Server 身份、菜单与设置 | `FR-026`, `FR-027` | Static/Build/Manual | repository contract、macOS Universal Release、iOS Simulator build 和 preview DMG mount/signature 检查通过；设置/菜单 UI、语言重启和 USB/Wi-Fi 实机状态待手工验证 |
| `TEST-027` 网络所有权、Developer Disk 索引、Classic Fediverse 与可选 OAuth fail-closed | `FR-028` | Script/Static/Build | repository/release contract、JSON/plist 与 iOS/macOS build 通过；Windows build 未执行 |

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
