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
| `TEST-010` | Shared errors | P1 | XCTest | error serialization | Partial |
| `TEST-011` | AltStore | P1 | Build | iOS Simulator build | CI defined |
| `TEST-012` | AltServer | P1 | Build | macOS build | CI defined |
| `TEST-013` | Release | P0 | Script/Packaging | artifact/source/checksum contract | Automated |
| `TEST-014` | AltJIT | P2 | Unit/Manual | OS/device/developer disk 前置条件 | Planned |
| `TEST-015` | Refresh | P1 | Integration | cancellation、partial failure、cleanup | Planned |
| `TEST-016` | Authentication/AltServer | P1 | Unit/Manual E2E | saved、individual、organization、free team 选择顺序 | Manual pending |
| `TEST-017` | My Apps/AltServer UI | P2 | Build/Manual | 到期天数下限与错误详情文本选择 | Manual pending |
| `TEST-018` | Windows AltServer | P1 | CI Build/Packaging | pinned dependencies、Win32 Release、runtime DLL ZIP contract | CI defined |
| `TEST-019` | Windows AltServer/device | P1 | Manual E2E | Windows 10/11 USB install、refresh、Wi-Fi discovery | Manual pending |
| `TEST-020` | Release | P0 | Script/Workflow | tag、`VERSION`、Xcode 与 Windows 产品版本一致 | Automated |
| `TEST-021` | Release | P0 | Script/Workflow | tag-only 触发与 Draft-only 发布策略 | Partial |
| `TEST-022` | Release source | P1 | Script/Packaging | tag 固定 URL、去重、历史继承与 20 条上限 | Automated |
| `TEST-023` | Remote configuration | P0 | Script/Static | 自有 flags/source/recommended 配置与安全默认值 | Automated |
| `TEST-024` | Identity/update | P1 | Static/Build/Manual | buildVersion、离线身份、支持/隐私/FAQ/桌面入口 | Partial |
| `TEST-025` | macOS packaging | P1 | Script/Packaging/Manual | DMG 结构、520 × 300 Finder layout、hidden chrome、icon positions、Applications link、image verify、bundle/version、首次启动 | Partial |
| `TEST-026` | macOS desktop UX | P1 | Static/Build/Manual | AltForge Server build product/executable/system login-item identity、expanded About/GitHub links、USB/Wi-Fi、图标、更新检查、登录项三态/失败恢复、设置与语言重启 | Partial |
| `TEST-027` | Network ownership | P0 | Script/Static/Build | 自有控制面、Developer Disk schema/host、Classic Fediverse fail-closed、遗留 plug-in 无网络、OAuth fail-closed | Partial |
| `TEST-028` | macOS authentication | P1 | Static/Build/Manual Security UI | single-read credential snapshot、saved account selection、Keychain-only password consent、reveal、Caps Lock、forget、failure retry/input retention、localized AltSign errors、six-digit 2FA input/paste、corrupt archive | Partial |
| `TEST-029` | macOS certificate ownership | P0 | Static/Build/Manual Security | known account team type in picker、legacy archive、managed certificate reuse/replace consent、unrelated Xcode certificate protection、cancel no-op | Partial |
| `TEST-030` | macOS installation/download | P0 | Static/Build/Network/Manual E2E | per-device dedup、delegate bytes/total/speed、installation-proxy Complete、symmetric UI、localized close button/titlebar close、manual source switch/cancel、configured CDN priority、GitHub timeout、bounded mirror fallback、size/SHA-256 rejection、cleanup | Partial |
| `TEST-031` | iOS App Group migration | P1 | Static/Build/Simulator/Manual E2E | metadata present + container unavailable、source/destination identity guard、sandbox fallback、future migration retry、no data deletion | Partial |
| `TEST-032` | iOS main navigation | P2 | Static/Build/Simulator | four tabs、Browse default、source-driven recent/category/featured content、zero-app actionable empty state、source-scoped News retained | Partial |
| `TEST-033` | iOS brand/settings | P2 | Static/Build/Simulator UI | SF Symbols、official tint override、settings + all subpage semantic colors、light/dark system chrome、six app-icon variants、nonblocking icon switch feedback、post-change checkmark、bundle version、credits/repository links、“侧载”术语与 zh-Hans labels | Partial |
| `TEST-034` | iOS public identity | P1 | Static/Build/Manual System UI | display/bundle/executable names、AltTests host、public resource scan、legacy identity allowlist、system crash-report title | Partial |
| `TEST-035` | iOS install/authentication diagnostics | P0 | Static/Unit/Build/Simulator/Manual E2E | bilingual persistent stage/overall-percent UI、extension count/name review、recommended removal vs keep-and-sign disclosure、light/dark semantic text、settings-to-My Apps crash regression、arm64_32 ldid signing/unknown CPU and nil-entitlement safe failure、unsupported Watch removal、sanitized bundle/architecture checkpoint、serialized progress/terminal response、terminal progress validation、InstalledApp save/relaunch persistence、malformed plist types、missing operation result、temporary object ID、atomic 20-record/16-stage/120-char journal、foreground checkpoint、diagnostic ID/failure stage/relative trace、copy report、sensitive-field allowlist、interrupted-operation recovery log、team selection、auth/workflow bilingual UI、third-party IPA device install | Partial |
| `TEST-036` | iOS theme colors | P2 | Unit/Static/Build/Simulator UI | Forge Red default、four-value persistence/fallback、localized swatch/checkmark picker、live navigation/tab/badge/official source/app/news/detail tint、raw metadata bypass guard、permission/add-source semantic colors、third-party tint preservation、semantic status-color allowlist、light/dark contrast | Partial |
| `TEST-038` | Static website | P2 | Script/Browser/Network | 双语、latest Release 下载与 fallback、320-1440px 深浅色、平台识别、安全响应头、Pages 生产回读 | Automated |
| `TEST-039` | Website visual/repository delivery | P2 | Script/Browser/Network/CI | 单一全幅 hero、首屏层级、仓库归属带、无旧双图标、320-1440px 深浅色与双语、平台推荐、Actions fail-closed、Pages 生产回读、GitHub homepage | Partial |
| `TEST-040` | Apple authentication response compatibility | P0 | Static/Unit/Build/Manual E2E | AuthKit compatibility identity、single parser path、init/complete/apptokens/decrypted/2FA stage metadata、429/5xx/HTML/malformed mapping、isolated session recovery/invalidation、retry/timeout limits、structured error priority、no response-body/header logging、real Apple login/2FA/team/certificate lookup | Partial; 17 local XCTest and Apple builds passed, user confirmed macOS login; full install/platform matrix pending |
| `TEST-041` | Error presentation | P1 | XCTest/Static/Build/Localization | known custom codes、provider relocalization、system-domain classification、detail-only diagnostics、Windows parity | Partial |
| `TEST-042` | macOS direct update | P1 | Static/Build/Network/Manual UI | newer/current/invalid latest metadata、pinned GitHub DMG、size/SHA-256、progress、cancel、timeout、single transfer、Downloads collision、automatic installer open、failure recovery | Partial |

状态只能使用：`Automated`、`CI defined`、`Partial`、`Planned`、`Manual pending`、`Manual harness only`、`Blocked`。状态变化必须同步 coverage map。
## TEST-041：错误码与用户提示

| Case | 输入 | 期望 |
|---|---|---|
| `ERR-001` | AltSign 0-7、Apple API 3000-3022 | 每个 code 有非空标题、具体原因和恢复建议 |
| `ERR-002` | Server 0-16/100-101、Connection 0-6 | 客户端按当前语言重新生成文案，不显示远端固化英文 |
| `ERR-003` | Apple API 3020，底层 Cocoa 3840 | 标题为 Apple ID 登录失败，原因指向 Apple 认证响应，不提 IPA 格式 |
| `ERR-004` | Cocoa 文件缺失、损坏、解析失败与常见 URL 错误 | 按 domain/code 区分文件、数据、网络与 TLS，不互相误报 |
| `ERR-005` | ProcessError 携带命令输出与源码位置 | 主提示不含原始输出/源码位置；详情仍保留结构化字段 |
| `ERR-006` | Windows Apple API enum | 3013-3017 与 Apple 平台一致，invalid response 独占 3022 |
| `ERR-007` | 简体中文 catalog | 所有共享标题、原因与建议存在非空中文值，变量占位符保持一致 |
