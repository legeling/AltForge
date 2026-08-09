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
| `T-007` 为 release metadata 添加 dry-run contract test | Done | `FR-015`, `FR-016`; `DES-010`; `TEST-013` | size/hash/schema/Windows artifact/缺失参数已有自动化断言并进入 CI |
| `T-008` 补 refresh cancellation 与部分失败测试 | Backlog | `FR-008`; `DES-001`-`DES-003`; `TEST-015` | 不产生错误成功状态或遗留临时资源 |
| `T-009` 建立 AltJIT 支持矩阵 | Backlog | `FR-012`; `DES-003`; `TEST-014` | 系统/设备/DeveloperDisk 前置条件可查 |
| `T-010` 移植低风险上游维护修复 | Done with manual gap | `FR-008`, `FR-011`, `FR-017`; `DES-003`, `DES-008`; `TEST-016`, `TEST-017` | 组织团队 fallback、到期天数下限、错误详情选择完成双目标构建验证 |
| `T-011` 迁移 AltSign Classic 基线 | Pending | `FR-001`, `FR-002`; `DES-003`, `DES-009`; `TEST-002` | fork 基于 upstream Classic、重放 Unicode 修复、真机认证安装通过并更新 gitlink |
| `T-012` 集成 Windows AltServer 单仓库交付 | In progress | `FR-018`, `FR-019`; `DES-011`; `TEST-018`, `TEST-019` | 源码/固定依赖/CI/Release ZIP 已定义，Windows runner 与真实设备验证通过 |

## Analyze 门禁结果

- 高优先级安装与 Unicode 需求已有 design/test/task 映射。
- `FR-013` 可选 targets 尚无完整测试映射，但不阻塞当前 Classic 核心链路。
- 阻塞自动化的主要缺口是 AltSign 没有独立 test target，以及本地依赖构建尚未完全验证。
- 当前明确使用 Swift 5.0 language mode；未来 Swift 6 migration 需要独立 change。macOS notarization 与 Windows 签名安装器仍是 `[待确认]`，Windows build/device gap 由 `ISSUE-20260809-001` 跟踪。

## 执行规则

- 开始 Task 前创建 `docs/changes/active/<change-key>/`。
- Task 状态变化时同步 verification matrix 与 coverage map。
- P0/P1 Task 完成后必须移动 change 到 completed，并记录实际命令与残余风险。
