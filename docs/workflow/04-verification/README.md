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

## 首批高价值失败测试

1. 纯中文 display name 与带英文 extension 名称组合后不产生 leading whitespace App ID。
2. raw GBK `Payload/Test.app/音乐.png` 解压为正确路径。
3. 有效 `0x7075` Unicode Path extra field 覆盖 legacy raw name；CRC 错误时不得盲目信任。
4. `../escape` 和绝对路径 entry 被拒绝，目标目录外无文件。
5. writer 输出中文 filename 时 general-purpose bit 11 已设置。
6. source metadata 中 size/hash 与实际 IPA 一致。

## 实际命令

CI build/test 命令登记在 [回归套件](05-regression-suite.md)。本地不能访问依赖或没有 simulator 时，必须报告未执行项，不能以 syntax check 代替完整构建。

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
- Windows ZIP 尚未执行 hosted runner 和真实设备验证，见 `ISSUE-20260809-001`。
- 简体中文 simulator 上完整错误测试仍有 12 项因 Foundation 本地化描述的空格规则失败，见 `ISSUE-20260808-007`。
