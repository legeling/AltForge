# Coverage Map

| Area | FR | DES | Tests | Current coverage | Gap owner |
|---|---|---|---|---|---|
| AltForge install | `FR-001`-`FR-003` | `DES-001`-`DES-003` | `TEST-001`, `TEST-002`, `TEST-004` | Low | `T-003` |
| Developer team selection | `FR-017` | `DES-003` | `TEST-016` | Implementation present, real organization account pending | `T-010` |
| Unicode App ID | `FR-004` | `DES-005` | `TEST-003` | Implementation present, no persistent test | `T-001` |
| Unicode ZIP | `FR-005` | `DES-005` | `TEST-005`-`TEST-007` | Manual GBK/round-trip evidence only | `T-001` |
| Localization | `FR-006`, `FR-007` | `DES-006` | `TEST-008` | Build resources present, UI matrix missing | `T-004` |
| Refresh | `FR-008` | `DES-001`-`DES-003` | `TEST-015`, `TEST-017` | Expiration display guard present; cancellation、partial failure、backup/restore 与 cleanup 覆盖低，上游 49 条报告合并见 `ISSUE-20260811-006` | `T-008`, `T-010` |
| Source identity | `FR-009`, `FR-010` | `DES-007` | `TEST-009` | Automated | maintenance |
| Error transport | `FR-011` | `DES-008` | `TEST-010`, `TEST-017` | Serialization partial; zh-Hans spacing assertions and macOS selection UI pending | `T-006`, `T-010` |
| JIT | `FR-012` | `DES-003` | `TEST-014` | 上游已确认 Python/pymobiledevice3、动态 RSD 与多 PID 失败风险；本地支持矩阵和真机验证缺失，见 `ISSUE-20260811-004` | `T-009` |
| Build | `FR-014` | `DES-009` | `TEST-011`, `TEST-012` | Apple CI defined | `T-002` |
| Release | `FR-015`, `FR-016` | `DES-010` | `TEST-013` | Ruby fixture covers metadata, hashes, Windows artifact and invalid input | `T-007` |
| Release versioning | `FR-020` | `DES-010` | `TEST-020` | Local contract automated; first tag-driven three-platform run pending | `T-013` |
| Windows AltServer | `FR-018`, `FR-019` | `DES-011` | `TEST-018`, `TEST-019` | Source/workflow present; hosted build and `ISSUE-20260811-005` USB/Wi-Fi discovery/device E2E pending | `T-012` |
| Release review gate | `FR-021` | `DES-012` | `TEST-021` | Static policy automated; real Draft pending | `T-014` |
| Release source history | `FR-022` | `DES-012` | `TEST-022` | Metadata fixture covers pinned URL, merge, de-duplication and 20-version bound | `T-014` |
| Remote configuration | `FR-023` | `DES-012` | `TEST-023` | Safe JSON defaults and Classic repository endpoints automated | `T-014` |
| Update and user identity | `FR-016`, `FR-024` | `DES-012` | `TEST-024` | Static contract, iOS targeted tests/build and macOS arm64 Release build pass; manual navigation and Windows build pending | `T-014` |
| macOS DMG | `FR-025` | `DES-013` | `TEST-025` | Shared packager/static contract and local Universal package/mount/signature smoke cover writable staging and fail-closed persistence; final 520 × 300 hidden-chrome screenshot and user visual review pass; real tag run and Developer ID/notarization pending | `T-015` |
| macOS desktop identity/settings | `FR-026`, `FR-027` | `DES-014` | `TEST-026` | Public product/executable, internal module, expanded About/GitHub links, inline settings/install-icon/SMAppService/restart static contract and clean Debug build plus prior Universal Release, iOS Simulator and preview DMG checks pass; system login-item prompt and `ISSUE-20260811-005` USB/Wi-Fi/language/update UI matrix pending | `T-016` |
| Network ownership | `FR-028` | `DES-015` | `TEST-027` | Repository contract、JSON/plist validation、iOS/macOS builds pass; Windows static coverage only | `T-017` |
| macOS Apple ID credentials and certificate ownership | `FR-029`, `FR-030` | `DES-016` | `TEST-028`, `TEST-029` | Static contract and macOS build cover single-read credential snapshot, account-type metadata and managed-certificate filtering; sanitized mock UI passed; upstream enterprise/2FA/response/anisette evidence is tracked in `ISSUE-20260811-003`, real authentication/certificate/device matrix pending | `T-018` |
| macOS installation transaction and Release download | `FR-031` | `DES-017` | `TEST-030` | Static contract and Universal Debug build cover delegate byte progress, installation-proxy Complete, explicit localized close action, per-device dedup, manual source cancellation, bounded CDN/mirrors and integrity checks; corrected live progress plus `ISSUE-20260811-005` real-device connection/completion/failure cleanup pending | `T-019` |
| iOS App Group migration fallback | `FR-032` | `DES-018` | `TEST-031` | Historical source fails the new contract; static regression, local/hosted iOS build, Draft artifact checks and temporary iOS 26.5 simulator launch pass; re-signed device launch pending | `T-020` |
| iOS main navigation | `FR-033` | `DES-019` | `TEST-032` | Repository contract、storyboard compile、iOS build、临时 simulator 四标签及官方 source-only 可操作空状态通过；第三方 source 聚合与详情资讯手工 fixture 待补 | `T-021` |
| iOS brand and settings | `FR-034` | `DES-020` | `TEST-033` | 用户反馈推翻此前设置子页深浅色结论；当前 repository contract、storyboard/XIB 解析编译和 iOS build 已覆盖固定颜色门禁、应用图标切换状态、版本与归属，完整 Simulator/真机视觉矩阵待重做 | `T-022` |
| iOS public identity | `FR-035` | `DES-021` | `TEST-034` | Repository contract、iOS build/build-for-testing 和产物检查覆盖 bundle/executable/test host、Universal Mach-O 与公开资源 allowlist；系统 crash-report 标题待真机手工确认 | `T-023` |
| iOS install crash, diagnostics and authentication | `FR-036` | `DES-022` | `TEST-035` | build 15 定位 ldid 未映射 CPU type 的空架构名称崩溃，最符合 Watch arm64_32；真实最小 watchOS Mach-O 签名、未知 CPU 安全失败、repository contract 与完整 iOS Release build 通过；同一第三方 IPA E2E 待验证 | `T-024` |
| iOS theme colors | `FR-037` | `DES-023` | `TEST-036` | Forge Red default、four-value preference/fallback、localized swatch picker、Launch child 即时刷新路径、official source/app/news/detail effective tint、raw metadata bypass guard、permission/add-source semantic colors and release metadata are covered by XCTest/static contracts, resource parsing and a full Debug iOS Simulator build; light/dark real-device matrix pending | `T-025` |
| Static download website | `FR-039` | `DES-025` | `TEST-038` | Static contracts, browser matrix, platform routing, Release fallback, production security headers and Cloudflare Pages live readback pass | `T-038` |
| Website visual and repository delivery | `FR-040` | `DES-026` | `TEST-039` | Static contracts, production deployment `92c5fb54`, local 320-1918px bilingual light/dark Playwright, Git delivery, and hosted verify run `31790637050` cover the single hero, bounded motion/reduced-motion, repository provenance, SVG fallback, platform routing, production hashes/headers/downloads and GitHub homepage; hosted deploy secrets remain pending | `T-039` |
| Apple authentication response compatibility | `FR-041` | `DES-027` | `TEST-040` | Source/static contract and macOS/iOS builds cover the modern coherent client identity and safe malformed-response mapping; no-credential GSA probe returned 200/plist, while real Apple account/2FA/team/certificate and install validation remain pending | `T-040` |
| User-facing error copy | `FR-042` | `DES-028` | `TEST-041` | Shared presentation, provider relocalization, known-code fixtures, zh-Hans scan, iOS test build/two focused tests and macOS build pass; Windows build/device and real Chinese UI pending | `T-041` |

## 风险排序

1. P0：archive traversal/resource cleanup 与 release artifact integrity。
2. P1：真实安装、Unicode fixtures、build reproducibility、refresh failure paths。
3. P2：localization UI matrix、Widget/Backup/JIT coverage。

## 更新规则

- 新增 TEST 时先登记 test-case matrix，再更新本表。
- `Planned` 不能视为覆盖。
- 手工验证必须注明 commit、环境和日期，不能永久替代 P0/P1 自动化。
