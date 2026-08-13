# macOS/Windows 桌面分发与安装器

- 上游仓库：[`altstoreio/AltStore`](https://github.com/altstoreio/AltStore)
- 最后核对：2026-08-11
- 开放 Issue：50 条
- 分类键：`desktop-distribution`
- 处置分布：`tracked-merged` 50 条
- 本地映射：[`ISSUE-20260808-003`](../../ISSUE-20260808-003-macos-distribution-signing.md)、[`ISSUE-20260808-005`](../../ISSUE-20260808-005-clean-build-reproducibility.md)、[`ISSUE-20260809-001`](../../ISSUE-20260809-001-windows-build-device-validation.md)

## 主题边界

AltServer 更新、DMG/ZIP、iCloud/iTunes 前置条件、菜单栏/托盘、启动项、架构和桌面安装失败。

## 合并依据

按 macOS 分发签名、干净构建与 Windows 构建/设备验证映射到已有风险。

## AltForge 处置

Classic 桌面端属于当前范围；平台特有结果必须分别验证，不能互相代替。

本分类是维护分流，不声称所有上游报告具有同一根因；本地实施仍需复现、定位并关联 `FR/DES/TEST/T/CHG`。

## 全部上游条目

| Issue | 标题 | 更新日期 | Labels | 处置 | 本地 Issue |
|---:|---|---|---|---|---|
| [#1741](https://github.com/altstoreio/AltStore/issues/1741) | iOS 26.2 update failing on Windows 11 laptop – AltServe won't update | 2026-04-27 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1719](https://github.com/altstoreio/AltStore/issues/1719) | Help, No Install 26.3 | 2026-02-25 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1714](https://github.com/altstoreio/AltStore/issues/1714) | Altserver crashes when opening the update window | 2026-02-19 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1680](https://github.com/altstoreio/AltStore/issues/1680) | Cannot install iCloud in Windows 11 arm | 2025-11-27 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1661](https://github.com/altstoreio/AltStore/issues/1661) | Unable to uninstall Altstore app | 2025-09-21 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1654](https://github.com/altstoreio/AltStore/issues/1654) | Error 0xe8008015 | 2025-09-15 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1614](https://github.com/altstoreio/AltStore/issues/1614) | Can´t install iCloud on Windows 11: problem with windows installer package | 2025-05-16 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1541](https://github.com/altstoreio/AltStore/issues/1541) | Altserver not showing up in taskbar | 2024-12-24 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1539](https://github.com/altstoreio/AltStore/issues/1539) | AltServer taking over windows 11 tray icons | 2024-12-10 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1477](https://github.com/altstoreio/AltStore/issues/1477) | AltServer spawn multiple system tray icons | 2024-06-03 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1406](https://github.com/altstoreio/AltStore/issues/1406) | icons spam taskbar personalization | 2024-04-25 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1392](https://github.com/altstoreio/AltStore/issues/1392) | AltServer not appearing in Menu Bar | 2026-02-22 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1381](https://github.com/altstoreio/AltStore/issues/1381) | Cannot find altstore server in taskbar tray on windows 23H2 suddenly | 2024-02-07 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1365](https://github.com/altstoreio/AltStore/issues/1365) | altserver.exception error 0 while installing Enmity or other app | 2024-01-23 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1278](https://github.com/altstoreio/AltStore/issues/1278) | iCloud there was a problem with this windows installer package | 2023-09-01 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1270](https://github.com/altstoreio/AltStore/issues/1270) | Mssing Media Features fix [Windows] | 2025-09-22 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1245](https://github.com/altstoreio/AltStore/issues/1245) | Altserver mail plugin error with mail 16.0 | 2023-09-06 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1244](https://github.com/altstoreio/AltStore/issues/1244) | Error when trying to download AltServer on Windows | 2023-07-20 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1212](https://github.com/altstoreio/AltStore/issues/1212) | Multiple taskbar icons in Windows 11's taskbar settings | 2025-09-11 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1166](https://github.com/altstoreio/AltStore/issues/1166) | Bug: AltStore won't work with multiple users signed in on macOS. | 2023-04-10 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1153](https://github.com/altstoreio/AltStore/issues/1153) | The identify used to sign the executable is no longer valid (0xe8008018) | 2023-02-21 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1107](https://github.com/altstoreio/AltStore/issues/1107) | (Windows) AltServer - Automatically start at startup doesn't work anymore | 2024-04-24 | bug | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1051](https://github.com/altstoreio/AltStore/issues/1051) | Unable to open AltServer. exe | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1046](https://github.com/altstoreio/AltStore/issues/1046) | macOS Mail App slow after installing AltStore Mail Plugin | 2023-02-17 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1029](https://github.com/altstoreio/AltStore/issues/1029) | 1.5 Freezing | 2023-01-30 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#1021](https://github.com/altstoreio/AltStore/issues/1021) | Altstore crashes on Windows after a while. | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#963](https://github.com/altstoreio/AltStore/issues/963) | Altstore Windows Error on startup | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#948](https://github.com/altstoreio/AltStore/issues/948) | entry point not found | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#860](https://github.com/altstoreio/AltStore/issues/860) | Altserver is not installing in my iPhone it keeps showing.   Altserver Installation failed. "Unknown services response error. (-1)."  Please help me. | 2023-01-12 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#854](https://github.com/altstoreio/AltStore/issues/854) | why the app signed by altstore cannot be install to iphone by ideviceinstaller | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#823](https://github.com/altstoreio/AltStore/issues/823) | Trying to install AltStore on my iPad Pro 11 inch results in AltServer silently closing | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#816](https://github.com/altstoreio/AltStore/issues/816) | Altstore doesnt install on my phone | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#813](https://github.com/altstoreio/AltStore/issues/813) | AltStore does not install at all | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#792](https://github.com/altstoreio/AltStore/issues/792) | You don't have permission | 2023-03-28 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#764](https://github.com/altstoreio/AltStore/issues/764) | AltServer Not detecting my device | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#678](https://github.com/altstoreio/AltStore/issues/678) | AltInstaller.msi not working | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#644](https://github.com/altstoreio/AltStore/issues/644) | Unknown services response error -1 | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#629](https://github.com/altstoreio/AltStore/issues/629) | Windows Installation Failed | 2026-07-08 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#405](https://github.com/altstoreio/AltStore/issues/405) | Alstore | 2020-10-27 | bug | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#336](https://github.com/altstoreio/AltStore/issues/336) | Error -1 when try to start app on Mac OS Big Sur | 2023-01-17 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#317](https://github.com/altstoreio/AltStore/issues/317) | [macOS] Update icon for macOS Big Sur? | 2022-02-07 | enhancement | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#306](https://github.com/altstoreio/AltStore/issues/306) | AltServer Silent Crashes while trying to install AltStore on Mac & Windows! | 2025-11-19 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#279](https://github.com/altstoreio/AltStore/issues/279) | This action cannot be completed at this time (-224411) | 2023-01-19 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#273](https://github.com/altstoreio/AltStore/issues/273) | install failed  failed to write serialized MlBundleMetadata to /private/var/containers/temp/bundle/application | 2024-09-06 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#261](https://github.com/altstoreio/AltStore/issues/261) | altserver Installation Failed | 2023-01-19 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#237](https://github.com/altstoreio/AltStore/issues/237) | Installing altstore from Windows gone silence. | 2023-01-19 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#201](https://github.com/altstoreio/AltStore/issues/201) | AltServer Crashes Attempting to Install AltStore | 2023-01-19 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#193](https://github.com/altstoreio/AltStore/issues/193) | Can't open the "Manage Plug-ins" button in MacOS Mail | 2024-02-01 | support | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#157](https://github.com/altstoreio/AltStore/issues/157) | AltServer Installer Crash | 2026-05-08 | bug | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |
| [#12](https://github.com/altstoreio/AltStore/issues/12) | Homebrew Cask formula for AltStore server | 2020-01-05 |  | `tracked-merged` | `ISSUE-20260808-003`, `ISSUE-20260808-005`, `ISSUE-20260809-001` |

## 复核规则

- 上游状态或证据变化时，更新机器审计后重新生成本页。
- 只有共同所有者、风险和完成门禁一致时才继续合并；出现独立根因时拆出新的本地 Issue。
- 不在仓库复制正文、评论、附件、作者、Apple ID、UDID、证书或其他敏感材料。
