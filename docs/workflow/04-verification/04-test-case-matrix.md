# Test Case Matrix

| ID | 模块 | 优先级 | 层级 | 覆盖 | 自动化状态 |
|---|---|---:|---|---|---|
| `TEST-001` | AppManager | P1 | Integration | install operation 状态与失败回滚 | Planned |
| `TEST-002` | AltServer/device | P1 | Manual E2E | 真实设备安装 | Manual pending |
| `TEST-003` | AltSign Apple API | P1 | Unit | Unicode display name -> ASCII App ID | Planned |
| `TEST-004` | Verification | P1 | Unit | invalid app metadata/permissions | Partial |
| `TEST-005` | AltSign ZIP | P1 | Unit | UTF-8 与 Unicode Path | Planned |
| `TEST-006` | AltSign ZIP | P1 | Unit | legacy East Asian encodings | Manual harness only |
| `TEST-007` | AltSign ZIP | P0 | Security | traversal/length/resource cleanup | Planned |
| `TEST-008` | Localization | P2 | Build/Manual | zh-Hans 与 per-app language | Planned |
| `TEST-009` | AltStoreCore Source | P1 | XCTest | stable source ID | Automated |
| `TEST-010` | Shared errors | P1 | XCTest | error serialization | Automated |
| `TEST-011` | AltStore | P1 | Build | iOS Simulator build | CI defined |
| `TEST-012` | AltServer | P1 | Build | macOS build | CI defined |
| `TEST-013` | Release | P0 | Script/Packaging | artifact/source/checksum contract | Planned |
| `TEST-014` | AltJIT | P2 | Unit/Manual | OS/device/developer disk 前置条件 | Planned |
| `TEST-015` | Refresh | P1 | Integration | cancellation、partial failure、cleanup | Planned |
| `TEST-016` | Authentication/AltServer | P1 | Unit/Manual E2E | saved、individual、organization、free team 选择顺序 | Manual pending |
| `TEST-017` | My Apps/AltServer UI | P2 | Build/Manual | 到期天数下限与错误详情文本选择 | Manual pending |

状态只能使用：`Automated`、`CI defined`、`Partial`、`Planned`、`Manual pending`、`Manual harness only`、`Blocked`。状态变化必须同步 coverage map。
