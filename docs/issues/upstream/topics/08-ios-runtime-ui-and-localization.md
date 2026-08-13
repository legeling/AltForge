# iOS 运行时、崩溃、UI 与本地化

- 上游仓库：[`altstoreio/AltStore`](https://github.com/altstoreio/AltStore)
- 最后核对：2026-08-11
- 开放 Issue：59 条
- 分类键：`ios-runtime-ui`
- 处置分布：`tracked-merged` 59 条
- 本地映射：[`ISSUE-20260808-007`](../../ISSUE-20260808-007-zh-error-test-spacing.md)、[`ISSUE-20260811-002`](../../ISSUE-20260811-002-ios-third-party-install-device-validation.md)

## 主题边界

启动崩溃、黑屏、Widget、后台行为、语言、图标、系统版本变化和安装时客户端退出。

## 合并依据

运行时安装崩溃与本地化回归映射到现有风险，其余条目在复现后按具体模块进入 change。

## AltForge 处置

当前范围内保留证据，但标题相似不代表共同根因。

本分类是维护分流，不声称所有上游报告具有同一根因；本地实施仍需复现、定位并关联 `FR/DES/TEST/T/CHG`。

## 全部上游条目

| Issue | 标题 | 更新日期 | Labels | 处置 | 本地 Issue |
|---:|---|---|---|---|---|
| [#1748](https://github.com/altstoreio/AltStore/issues/1748) | Altstore crashed on launch on IOS 26.5 | 2026-06-28 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1736](https://github.com/altstoreio/AltStore/issues/1736) | App I sideload with AltStore works for 1 day, and then crashes on launch unless I deactivate and re-add | 2026-04-05 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1730](https://github.com/altstoreio/AltStore/issues/1730) | AltStore opens to black screen and crashes (iOS 26.4) | 2026-03-24 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1717](https://github.com/altstoreio/AltStore/issues/1717) | Unable to open AltStore on iOS 26.4 beta 1 | 2026-03-30 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1679](https://github.com/altstoreio/AltStore/issues/1679) | Altserver hangs after exiting sleep state | 2025-12-25 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1674](https://github.com/altstoreio/AltStore/issues/1674) | AltStore Classic crashes when installing IPAs on iOS 26.1 | 2026-04-24 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1672](https://github.com/altstoreio/AltStore/issues/1672) | Missing Library causes crash on iOS 26.1 on startup | 2025-11-12 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1636](https://github.com/altstoreio/AltStore/issues/1636) | More languages please！ | 2025-08-19 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1628](https://github.com/altstoreio/AltStore/issues/1628) | Liquid Glass Icon | 2025-06-11 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1624](https://github.com/altstoreio/AltStore/issues/1624) | This pull request is a parent for tracking the changes for SkyEmu v4. | 2025-06-05 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1599](https://github.com/altstoreio/AltStore/issues/1599) | Lock Screen widget not working on Version 2.2 | 2025-05-27 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1587](https://github.com/altstoreio/AltStore/issues/1587) | I can't use Altstore widget after reinstalling | 2025-03-13 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1586](https://github.com/altstoreio/AltStore/issues/1586) | Request to add language pack | 2025-03-11 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1502](https://github.com/altstoreio/AltStore/issues/1502) | Moved on new iPhone and AltStore stopped working | 2024-08-05 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1475](https://github.com/altstoreio/AltStore/issues/1475) | Crashes app | 2024-05-29 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1464](https://github.com/altstoreio/AltStore/issues/1464) | I cant find the AltStore Widget | 2024-09-30 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1456](https://github.com/altstoreio/AltStore/issues/1456) | Unable to launch AltStore BETA | 2024-08-25 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1437](https://github.com/altstoreio/AltStore/issues/1437) | accessibility: "Confirm" button identified as a blank element by VoiceOver | 2024-04-22 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1423](https://github.com/altstoreio/AltStore/issues/1423) | iPad layout support | 2025-01-28 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1417](https://github.com/altstoreio/AltStore/issues/1417) | Is it possible to use app groups in altstore? | 2024-06-13 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1331](https://github.com/altstoreio/AltStore/issues/1331) | AltServer with iOS 14.3, says needs to download AltStore v1.6.3, and crashes | 2023-11-29 | bug | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1266](https://github.com/altstoreio/AltStore/issues/1266) | 'Permissions Changed' alert for updating apps that have changed their requested permissions | 2023-08-02 | enhancement | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1258](https://github.com/altstoreio/AltStore/issues/1258) | iOS 16 Lock Screen Widget | 2023-08-01 | enhancement | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1247](https://github.com/altstoreio/AltStore/issues/1247) | can not install utm se | 2026-01-14 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1194](https://github.com/altstoreio/AltStore/issues/1194) | AltStore 2.0 not for iPhone 7 Plus? | 2023-09-20 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1186](https://github.com/altstoreio/AltStore/issues/1186) | iOS 16.4 App Installation fail | 2023-09-13 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1183](https://github.com/altstoreio/AltStore/issues/1183) | What about add a function of change app icon. We are really looking forward to that! | 2023-09-13 | enhancement | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1164](https://github.com/altstoreio/AltStore/issues/1164) | menu doesn't appear in menu bar after launch | 2026-04-08 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1155](https://github.com/altstoreio/AltStore/issues/1155) | crash upon open | 2023-08-02 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1154](https://github.com/altstoreio/AltStore/issues/1154) | How to remove altstore widget when installing through altstoee | 2025-11-16 | enhancement | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1142](https://github.com/altstoreio/AltStore/issues/1142) | I can't use Altstore widget after reinstalling | 2025-03-13 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1099](https://github.com/altstoreio/AltStore/issues/1099) | crashing "sources" tab | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1035](https://github.com/altstoreio/AltStore/issues/1035) | Altstore installs but then after a few hours crashes on startup | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1033](https://github.com/altstoreio/AltStore/issues/1033) | Altstore was denied permission to launch | 2024-09-22 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1032](https://github.com/altstoreio/AltStore/issues/1032) | My app crash | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1012](https://github.com/altstoreio/AltStore/issues/1012) | Crash when add sources | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#1001](https://github.com/altstoreio/AltStore/issues/1001) | Crashing! | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#986](https://github.com/altstoreio/AltStore/issues/986) | crashes when installing ytmusicultimate, crashlog attached | 2025-10-06 | bug | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#965](https://github.com/altstoreio/AltStore/issues/965) | 安装时建议支持中文字符串 | 2025-09-29 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#956](https://github.com/altstoreio/AltStore/issues/956) | Can someone help me out?(altstore crashing at start) | 2023-01-11 | bug | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#953](https://github.com/altstoreio/AltStore/issues/953) | Monterey AltStore crash on open after installed | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#899](https://github.com/altstoreio/AltStore/issues/899) | Problem | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#897](https://github.com/altstoreio/AltStore/issues/897) | altstore crashes when opening, ios 13.2.2 | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#884](https://github.com/altstoreio/AltStore/issues/884) | AltStore crash on open on several devices after fresh install | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#883](https://github.com/altstoreio/AltStore/issues/883) | AltStore crash iOS 12.5.5 11/2121 | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#874](https://github.com/altstoreio/AltStore/issues/874) | crash after altstore update to 1.4.8 ios 13.5 | 2023-01-11 | bug | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#873](https://github.com/altstoreio/AltStore/issues/873) | [Windows/Mac] Both Work installing but Crash upon Launch | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#867](https://github.com/altstoreio/AltStore/issues/867) | AltStore crashed after update to newest version (1.4.8) | 2023-01-11 | bug | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#863](https://github.com/altstoreio/AltStore/issues/863) | Altstore crashing during start // iOS 15.1 | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#851](https://github.com/altstoreio/AltStore/issues/851) | Altstore force close when opening | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#850](https://github.com/altstoreio/AltStore/issues/850) | “Unable to Launch AltStore” | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#829](https://github.com/altstoreio/AltStore/issues/829) | Failed to verift code of signature of... (The identity used to sign the executable is no longer valid.) | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#763](https://github.com/altstoreio/AltStore/issues/763) | sideloads crashing | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#727](https://github.com/altstoreio/AltStore/issues/727) | Attempting to install iSH from source crashes AltStore | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#686](https://github.com/altstoreio/AltStore/issues/686) | Unable to launch altstore app on iPhone 12 pro Max iOS 14.5 public Beta 2 | 2023-01-13 |  | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#416](https://github.com/altstoreio/AltStore/issues/416) | install ipa crash on ios 14.1  version 1.4.1 | 2023-01-14 | support | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#294](https://github.com/altstoreio/AltStore/issues/294) | VoiceOver issues with AltStore iOS app | 2020-08-23 | enhancement | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#145](https://github.com/altstoreio/AltStore/issues/145) | AltStore accessibility problems | 2020-05-22 | enhancement | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |
| [#39](https://github.com/altstoreio/AltStore/issues/39) | Ipad Screen Support | 2026-01-20 | enhancement | `tracked-merged` | `ISSUE-20260808-007`, `ISSUE-20260811-002` |

## 复核规则

- 上游状态或证据变化时，更新机器审计后重新生成本页。
- 只有共同所有者、风险和完成门禁一致时才继续合并；出现独立根因时拆出新的本地 Issue。
- 不在仓库复制正文、评论、附件、作者、Apple ID、UDID、证书或其他敏感材料。
