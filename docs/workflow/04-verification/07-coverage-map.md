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
| Error transport | `FR-011` | `DES-008` | `TEST-010`, `TEST-017` | Serialization partial; zh-Hans spacing assertions and macOS selection UI pending | `T-006`, `T-010` |
| JIT | `FR-012` | `DES-003` | `TEST-014` | Unknown | `T-009` |
| Build | `FR-014` | `DES-009` | `TEST-011`, `TEST-012` | Apple CI defined | `T-002` |
| Release | `FR-015`, `FR-016` | `DES-010` | `TEST-013` | Ruby fixture covers metadata, hashes, Windows artifact and invalid input | `T-007` |
| Release versioning | `FR-020` | `DES-010` | `TEST-020` | Local contract automated; first tag-driven three-platform run pending | `T-013` |
| Windows AltServer | `FR-018`, `FR-019` | `DES-011` | `TEST-018`, `TEST-019` | Source/workflow present; hosted build and device E2E pending | `T-012` |
| Release review gate | `FR-021` | `DES-012` | `TEST-021` | Static policy automated; real Draft pending | `T-014` |
| Release source history | `FR-022` | `DES-012` | `TEST-022` | Metadata fixture covers pinned URL, merge, de-duplication and 20-version bound | `T-014` |
| Remote configuration | `FR-023` | `DES-012` | `TEST-023` | Safe JSON defaults and Classic repository endpoints automated | `T-014` |
| Update and user identity | `FR-016`, `FR-024` | `DES-012` | `TEST-024` | Static contract, iOS targeted tests/build and macOS arm64 Release build pass; manual navigation and Windows build pending | `T-014` |
| macOS DMG | `FR-025` | `DES-013` | `TEST-025` | Shared packager/static contract and local Universal image/mount/bundle checks pass; CI artifact/checksum gates defined; Finder launch, real tag run and Developer ID/notarization pending | `T-015` |
| macOS desktop identity/settings | `FR-026`, `FR-027` | `DES-014` | `TEST-026` | Public product/executable, internal module, expanded About/GitHub links, inline settings/install-icon/SMAppService/restart static contract and clean Debug build plus prior Universal Release, iOS Simulator and preview DMG checks pass; system login-item prompt and full USB/Wi-Fi/language/update UI matrix pending | `T-016` |
| Network ownership | `FR-028` | `DES-015` | `TEST-027` | Repository contract、JSON/plist validation、iOS/macOS builds pass; Windows static coverage only | `T-017` |
| macOS Apple ID credentials and certificate ownership | `FR-029`, `FR-030` | `DES-016` | `TEST-028`, `TEST-029` | Static contract and macOS build cover single-read credential snapshot, account-type metadata and managed-certificate filtering; sanitized mock UI passed, real authentication/certificate/device matrix pending | `T-018` |
| macOS installation transaction and Release download | `FR-031` | `DES-017` | `TEST-030` | Static contract and Universal Debug build cover delegate byte progress, installation-proxy Complete, explicit localized close action, per-device dedup, manual source cancellation, bounded CDN/mirrors and integrity checks; corrected live progress and real-device completion/failure cleanup pending | `T-019` |
| iOS App Group migration fallback | `FR-032` | `DES-018` | `TEST-031` | Historical source fails the new contract; static regression, local/hosted iOS build, Draft artifact checks and temporary iOS 26.5 simulator launch pass; re-signed device launch pending | `T-020` |
| iOS main navigation | `FR-033` | `DES-019` | `TEST-032` | Repository contract、storyboard compile、iOS build 和临时 simulator 四标签检查通过；source 详情资讯手工 fixture 待补 | `T-021` |
| iOS brand and settings | `FR-034` | `DES-020` | `TEST-033` | Repository contract、storyboard 编译、iOS build 和 iOS 26.5 深浅色 simulator 已覆盖图标、颜色、版本与归属；真机视觉矩阵待补 | `T-022` |
| iOS public identity | `FR-035` | `DES-021` | `TEST-034` | Repository contract、iOS build/build-for-testing 和产物检查覆盖 bundle/executable/test host、Universal Mach-O 与公开资源 allowlist；系统 crash-report 标题待真机手工确认 | `T-023` |
| iOS install crash, diagnostics and authentication | `FR-036` | `DES-022` | `TEST-035` | 重复 crash report 已定位；有界脱敏阶段轨迹、复制诊断报告、repository contract、iOS build、简体中文工作原理 UI 和 6 轮 Settings/My Apps simulator 往返纳入回归；诊断日志 runtime 与第三方 IPA 真机 E2E 待验证 | `T-024` |

## 风险排序

1. P0：archive traversal/resource cleanup 与 release artifact integrity。
2. P1：真实安装、Unicode fixtures、build reproducibility、refresh failure paths。
3. P2：localization UI matrix、Widget/Backup/JIT coverage。

## 更新规则

- 新增 TEST 时先登记 test-case matrix，再更新本表。
- `Planned` 不能视为覆盖。
- 手工验证必须注明 commit、环境和日期，不能永久替代 P0/P1 自动化。
