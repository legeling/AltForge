# IPA、签名、归档路径与扩展

- 上游仓库：[`altstoreio/AltStore`](https://github.com/altstoreio/AltStore)
- 最后核对：2026-08-11
- 开放 Issue：81 条
- 分类键：`ipa-signing-packaging`
- 处置分布：`tracked-merged` 81 条
- 本地映射：[`ISSUE-20260808-001`](../../ISSUE-20260808-001-unicode-regression-tests.md)、[`ISSUE-20260808-006`](../../ISSUE-20260808-006-altsign-classic-baseline.md)、[`ISSUE-20260811-002`](../../ISSUE-20260811-002-ios-third-party-install-device-validation.md)

## 主题边界

IPA/ZIP 解包、Unicode 路径、Info.plist、nested code、extensions、ldid、AltSign 和大型包安装。

## 合并依据

按归档解析、签名底层与 iOS 安装回归三个所有者映射到既有本地 Issue，避免为单个 App 建重复问题。

## AltForge 处置

纳入当前范围；第三方 IPA 只有能复现到共享解析、签名或安装链路时才提升为实现任务。

本分类是维护分流，不声称所有上游报告具有同一根因；本地实施仍需复现、定位并关联 `FR/DES/TEST/T/CHG`。

## 全部上游条目

| Issue | 标题 | 更新日期 | Labels | 处置 | 本地 Issue |
|---:|---|---|---|---|---|
| [#1744](https://github.com/altstoreio/AltStore/issues/1744) | Failed to write serialized MiBundleMetadata error help. | 2026-05-18 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1692](https://github.com/altstoreio/AltStore/issues/1692) | Nested plugins signing error | 2026-06-29 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1660](https://github.com/altstoreio/AltStore/issues/1660) | Altsign error when trying to sideload specific ipa | 2025-11-06 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1657](https://github.com/altstoreio/AltStore/issues/1657) | ERROR 2008 0xe8008015 | 2025-09-16 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1650](https://github.com/altstoreio/AltStore/issues/1650) | ldid.cpp(2376):_assert() error when trying to install latest LiveContainer+SideStore ipa | 2025-12-13 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1627](https://github.com/altstoreio/AltStore/issues/1627) | Could not install AltStore - * Line 1, Column 2 Syntax error: Malformed token | 2025-06-10 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1613](https://github.com/altstoreio/AltStore/issues/1613) | Bug: AltStore.ipa fails to install — “DeveloperDiskImage.dmg could not be determined” | 2025-05-15 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1594](https://github.com/altstoreio/AltStore/issues/1594) | Sideloaded apps take insanely long to refresh | 2025-04-21 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1568](https://github.com/altstoreio/AltStore/issues/1568) | could not install altstore to iphone | 2025-02-04 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1557](https://github.com/altstoreio/AltStore/issues/1557) | Is there any way to remove app extensions when installing an app from a source within Altstore | 2025-01-18 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1553](https://github.com/altstoreio/AltStore/issues/1553) | X64 version of Altserver | 2025-01-12 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1547](https://github.com/altstoreio/AltStore/issues/1547) | AltSign.Error 0 while installing Kodi | 2026-02-06 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1536](https://github.com/altstoreio/AltStore/issues/1536) | "App contains extensions" promt doesn't appear when downloading app from custom source | 2024-11-15 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1518](https://github.com/altstoreio/AltStore/issues/1518) | Allow people to enable entitlements for sideloaded apps | 2024-10-01 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1517](https://github.com/altstoreio/AltStore/issues/1517) | Altstore Crashing When Installing a Large ipa file (2gb or higher) | 2024-09-29 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1485](https://github.com/altstoreio/AltStore/issues/1485) | AltStore unverifying itself and other sideloaded apps when trying to backup a sideloaded app | 2024-08-28 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1457](https://github.com/altstoreio/AltStore/issues/1457) | Error I am getting with few selected apps | 2024-10-24 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1395](https://github.com/altstoreio/AltStore/issues/1395) | You can't save this file because there is no enough Space | 2025-06-26 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1393](https://github.com/altstoreio/AltStore/issues/1393) | Error sideloading IPA to Apple TV from AltStore | 2024-03-03 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1382](https://github.com/altstoreio/AltStore/issues/1382) | The file "MusicallyCore" couldn't be saved in the folder "MusicallyCore.framework". | 2024-02-08 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1367](https://github.com/altstoreio/AltStore/issues/1367) | NSCocoaErrorDomain 513 | 2025-01-06 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1351](https://github.com/altstoreio/AltStore/issues/1351) | stupid "FILE NAME OR DIRECTORY TOO LONG ERROR" when installing ENMITY! | 2023-12-12 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1339](https://github.com/altstoreio/AltStore/issues/1339) | Could not install AltStore to iPhone (canonical, AltWidgetExtension.appex) | 2025-09-05 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1277](https://github.com/altstoreio/AltStore/issues/1277) | "(1007) This app is in an invalid format" error | 2026-06-23 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1273](https://github.com/altstoreio/AltStore/issues/1273) | How to solve “Failed to load Info”？ | 2023-08-21 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1243](https://github.com/altstoreio/AltStore/issues/1243) | Error while trying to update sideloaded apps | 2023-07-28 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1240](https://github.com/altstoreio/AltStore/issues/1240) | [Bug] Windows version can't sign IPA which contains unallowed characters in Windows. | 2024-04-16 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1237](https://github.com/altstoreio/AltStore/issues/1237) | Apps do not install properly most of the time in iOS 17 beta 2 | 2023-09-14 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1216](https://github.com/altstoreio/AltStore/issues/1216) | The file ** couldn't be saved in the folder *folder name* error. | 2023-06-20 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1207](https://github.com/altstoreio/AltStore/issues/1207) | some ipa Altstore can't install, Error 0 | 2023-10-24 | bug, support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1199](https://github.com/altstoreio/AltStore/issues/1199) | Error when installing large ipa files | 2024-11-22 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1191](https://github.com/altstoreio/AltStore/issues/1191) | Sideload error | 2023-09-13 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1189](https://github.com/altstoreio/AltStore/issues/1189) | Failed to load info.Plist | 2023-09-13 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1173](https://github.com/altstoreio/AltStore/issues/1173) | [bug]After refreshing the app use Altstore, the app signed by other ipa signing tools becomes invalid | 2023-04-24 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1163](https://github.com/altstoreio/AltStore/issues/1163) | Increase open files limit in AltServer | 2023-08-02 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1150](https://github.com/altstoreio/AltStore/issues/1150) | APP‘s name contains invalid characters | 2024-08-30 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1117](https://github.com/altstoreio/AltStore/issues/1117) | Failed to unhide archs in executable file error | 2023-01-29 | bug, support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1108](https://github.com/altstoreio/AltStore/issues/1108) | [BUG] Can altstore support Displayname with Chinese words ? | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1098](https://github.com/altstoreio/AltStore/issues/1098) | Kodi can't be installed | 2025-08-07 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1097](https://github.com/altstoreio/AltStore/issues/1097) | Error installing apps with appex extensions | 2023-02-12 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1094](https://github.com/altstoreio/AltStore/issues/1094) | There is no XCFramework found | 2023-01-11 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1091](https://github.com/altstoreio/AltStore/issues/1091) | Created App ID for sideloaded app doesn't contain correct capabilities | 2023-08-02 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1070](https://github.com/altstoreio/AltStore/issues/1070) | Failed to verify code signature | 2023-08-02 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1056](https://github.com/altstoreio/AltStore/issues/1056) | No mapping for the Unicode character exists in the target multi-byte code page. | 2025-02-09 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1034](https://github.com/altstoreio/AltStore/issues/1034) | Sideloading giving ldid error | 2026-05-19 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1013](https://github.com/altstoreio/AltStore/issues/1013) | Application is missing the application-identifier entitlement | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#1010](https://github.com/altstoreio/AltStore/issues/1010) | failed IPA installs are neither cleaned nor show in the user interface, piling up | 2023-08-02 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#997](https://github.com/altstoreio/AltStore/issues/997) | Error: The filename or extension is too long. | 2024-09-01 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#995](https://github.com/altstoreio/AltStore/issues/995) | Not able to sideload files over 300mb says "bad allocation" | 2023-01-11 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#984](https://github.com/altstoreio/AltStore/issues/984) | Failed to verify code signature 0xe8008015 | 2024-06-27 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#979](https://github.com/altstoreio/AltStore/issues/979) | Application missing the application-identifier entitlement | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#920](https://github.com/altstoreio/AltStore/issues/920) | “Application is missing the application- identifier entitlement” error when deactivating apps | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#881](https://github.com/altstoreio/AltStore/issues/881) | The file " *file name* " couldn't be saved in the folder " *folder name* " error. | 2025-02-17 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#833](https://github.com/altstoreio/AltStore/issues/833) | File "Apps" couldn't be saved | 2023-07-20 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#815](https://github.com/altstoreio/AltStore/issues/815) | UX: Add version and sideload date in "My Apps" for IPAs | 2023-01-11 | enhancement | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#804](https://github.com/altstoreio/AltStore/issues/804) | help installing | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#801](https://github.com/altstoreio/AltStore/issues/801) | share extension does not work | 2023-01-11 | developer, support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#799](https://github.com/altstoreio/AltStore/issues/799) | Install Failed: Appex bundle at... does not define either an NSExtensionMainStoryBoard.... | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#786](https://github.com/altstoreio/AltStore/issues/786) | iOS 15 + macOS 11.3.1. AltServer + AltStore working, sideloading stops at 0.5x | 2024-04-18 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#779](https://github.com/altstoreio/AltStore/issues/779) | Failed to Verify Code Signature #319 | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#758](https://github.com/altstoreio/AltStore/issues/758) | "The app is invalid" error. | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#740](https://github.com/altstoreio/AltStore/issues/740) | The file "objects-13.0+.nib" could not be saved in the folder "01J-lp-oVM-view-Ze5-6b-2t3.nib". | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#691](https://github.com/altstoreio/AltStore/issues/691) | Phycicpaper apps don’t work | 2023-08-02 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#684](https://github.com/altstoreio/AltStore/issues/684) | Apple watch signing support? | 2023-01-13 | enhancement | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#673](https://github.com/altstoreio/AltStore/issues/673) | bad allocation or lost connection | 2023-01-19 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#642](https://github.com/altstoreio/AltStore/issues/642) | Kernel Extension for the OpenCore boot loader | 2023-08-02 | enhancement | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#571](https://github.com/altstoreio/AltStore/issues/571) | The file "gta3.pvr.dat" couldn't be saved in the folder "gta3sa.app". | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#421](https://github.com/altstoreio/AltStore/issues/421) | lost connection error | 2024-07-01 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#419](https://github.com/altstoreio/AltStore/issues/419) | The installation of Ducktales get stuck | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#326](https://github.com/altstoreio/AltStore/issues/326) | AltStore error: "Failed to find matching arch for FAT input file" | 2024-06-15 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#313](https://github.com/altstoreio/AltStore/issues/313) | Can't install IPAs | 2020-08-24 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#303](https://github.com/altstoreio/AltStore/issues/303) | AltStore crashing whenever sideloading large ipa file | 2021-01-05 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#291](https://github.com/altstoreio/AltStore/issues/291) | "Bad Allocation" When I try to sideload an app | 2026-05-28 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#229](https://github.com/altstoreio/AltStore/issues/229) | Apple Watch app resigning | 2021-08-01 | enhancement | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#174](https://github.com/altstoreio/AltStore/issues/174) | AltServer crashes whenever I try to install an ipa | 2023-01-23 | support | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#170](https://github.com/altstoreio/AltStore/issues/170) | "The App is invalid." error when trying to install a flutter app. Create an app making tutorial for apps to install using AltStore. | 2025-11-05 | enhancement | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#159](https://github.com/altstoreio/AltStore/issues/159) | Libraries/Frameworks not signed properly | 2025-01-31 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#110](https://github.com/altstoreio/AltStore/issues/110) | Can’t select any IPA to sideload in browse | 2024-10-29 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#94](https://github.com/altstoreio/AltStore/issues/94) | Failed to verify code signature? | 2025-01-31 | bug | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#19](https://github.com/altstoreio/AltStore/issues/19) | Support for network shares in the sideloading file provider | 2020-05-24 | enhancement | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |
| [#18](https://github.com/altstoreio/AltStore/issues/18) | Error when sideloading apps (EXC_BAD_ACCESS) | 2019-10-04 |  | `tracked-merged` | `ISSUE-20260808-001`, `ISSUE-20260808-006`, `ISSUE-20260811-002` |

## 复核规则

- 上游状态或证据变化时，更新机器审计后重新生成本页。
- 只有共同所有者、风险和完成门禁一致时才继续合并；出现独立根因时拆出新的本地 Issue。
- 不在仓库复制正文、评论、附件、作者、Apple ID、UDID、证书或其他敏感材料。
