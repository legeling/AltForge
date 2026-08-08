# Coverage Map

| Area | FR | DES | Tests | Current coverage | Gap owner |
|---|---|---|---|---|---|
| AltForge install | `FR-001`-`FR-003` | `DES-001`-`DES-003` | `TEST-001`, `TEST-002`, `TEST-004` | Low | `T-003` |
| Developer team selection | `FR-017` | `DES-003` | `TEST-016` | Implementation present, real organization account pending | `T-010` |
| Unicode App ID | `FR-004` | `DES-005` | `TEST-003` | Implementation present, no persistent test | `T-001` |
| Unicode ZIP | `FR-005` | `DES-005` | `TEST-005`-`TEST-007` | Manual GBK/round-trip evidence only | `T-001` |
| Localization | `FR-006`, `FR-007` | `DES-006` | `TEST-008` | Build resources present, UI matrix missing | `T-004` |
| Refresh | `FR-008` | `DES-001`-`DES-003` | `TEST-015`, `TEST-017` | Expiration display guard present; failure coverage low | `T-008`, `T-010` |
| Source identity | `FR-009`, `FR-010` | `DES-007` | `TEST-009` | Automated | maintenance |
| Error transport | `FR-011` | `DES-008` | `TEST-010`, `TEST-017` | Serialization automated; macOS selection UI pending | `T-010` |
| JIT | `FR-012` | `DES-003` | `TEST-014` | Unknown | `T-009` |
| Build | `FR-014` | `DES-009` | `TEST-011`, `TEST-012` | CI defined | `T-002` |
| Release | `FR-015`, `FR-016` | `DES-010` | `TEST-013` | Workflow/script present, contract test missing | `T-007` |

## 风险排序

1. P0：archive traversal/resource cleanup 与 release artifact integrity。
2. P1：真实安装、Unicode fixtures、build reproducibility、refresh failure paths。
3. P2：localization UI matrix、Widget/Backup/JIT coverage。

## 更新规则

- 新增 TEST 时先登记 test-case matrix，再更新本表。
- `Planned` 不能视为覆盖。
- 手工验证必须注明 commit、环境和日期，不能永久替代 P0/P1 自动化。
