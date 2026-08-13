# 刷新、停用、备份与应用生命周期

- 上游仓库：[`altstoreio/AltStore`](https://github.com/altstoreio/AltStore)
- 最后核对：2026-08-11
- 开放 Issue：49 条
- 分类键：`refresh-backup-lifecycle`
- 处置分布：`tracked-merged` 49 条
- 本地映射：[`ISSUE-20260811-006`](../../ISSUE-20260811-006-refresh-backup-lifecycle.md)

## 主题边界

refresh、deactivate、backup/restore、App ID、到期、部分失败、取消和失败清理。

## 合并依据

这些报告共享安装记录、设备状态、备份状态与本地持久化之间的一致性门禁。

## AltForge 处置

纳入当前范围；以幂等、原子恢复和跨平台真机回归作为关闭条件。

本分类是维护分流，不声称所有上游报告具有同一根因；本地实施仍需复现、定位并关联 `FR/DES/TEST/T/CHG`。

## 全部上游条目

| Issue | 标题 | 更新日期 | Labels | 处置 | 本地 Issue |
|---:|---|---|---|---|---|
| [#1688](https://github.com/altstoreio/AltStore/issues/1688) | Missing app in list | 2025-12-13 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1664](https://github.com/altstoreio/AltStore/issues/1664) | WinHttpSendRequest: 12002: operation time has expired | 2025-10-13 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1640](https://github.com/altstoreio/AltStore/issues/1640) | Failed to refresh AltStore Apps while connected to a VPN hosted on the exact network | 2025-08-05 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1638](https://github.com/altstoreio/AltStore/issues/1638) | cant refresh wirelessly | 2025-08-19 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1623](https://github.com/altstoreio/AltStore/issues/1623) | refresh github action | 2025-06-02 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1615](https://github.com/altstoreio/AltStore/issues/1615) | Choose App IDs | 2025-08-23 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1526](https://github.com/altstoreio/AltStore/issues/1526) | Installed apps are no longer available after a refresh | 2024-10-17 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1522](https://github.com/altstoreio/AltStore/issues/1522) | Install and Refresh Failed: NSCocoaErrorDomain 512 | 2024-10-08 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1439](https://github.com/altstoreio/AltStore/issues/1439) | Altstore app shows expiry in negative days. | 2024-04-23 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1412](https://github.com/altstoreio/AltStore/issues/1412) | App ID's don't expire | 2024-07-24 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1378](https://github.com/altstoreio/AltStore/issues/1378) | Altstore is not avalieble and dev profile is deleted automatically | 2024-01-26 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1328](https://github.com/altstoreio/AltStore/issues/1328) | Shortcut refresh: refresh all apps not supported on iphone | 2023-12-16 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#1314](https://github.com/altstoreio/AltStore/issues/1314) | Installing IPA app only shows the App ID, but doesn't show the app on the AltStore "My Apps" tab or the homescreen. | 2024-02-13 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#1309](https://github.com/altstoreio/AltStore/issues/1309) | Certificates not expiring | 2023-10-16 | question | `tracked-merged` | `ISSUE-20260811-006` |
| [#1297](https://github.com/altstoreio/AltStore/issues/1297) | Failed installs take up storage | 2023-10-04 | question, support | `tracked-merged` | `ISSUE-20260811-006` |
| [#1296](https://github.com/altstoreio/AltStore/issues/1296) | iPad "Refresh All Apps" shortcut doesn't work anymore | 2024-06-25 | bug | `tracked-merged` | `ISSUE-20260811-006` |
| [#1282](https://github.com/altstoreio/AltStore/issues/1282) | Add an option to disable AppIDs renewal | 2023-09-03 | enhancement | `tracked-merged` | `ISSUE-20260811-006` |
| [#1276](https://github.com/altstoreio/AltStore/issues/1276) | The operation couldn’t be completed. Unable to install the app from the staging directory | 2024-04-15 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#1254](https://github.com/altstoreio/AltStore/issues/1254) | Clear Cache Setting | 2023-08-01 | enhancement | `tracked-merged` | `ISSUE-20260811-006` |
| [#1236](https://github.com/altstoreio/AltStore/issues/1236) | [Discussion] Refresh apps in the wide area network | 2023-11-04 | enhancement | `tracked-merged` | `ISSUE-20260811-006` |
| [#1233](https://github.com/altstoreio/AltStore/issues/1233) | Add confirm button when manually refreshing app id's. | 2023-08-02 | enhancement | `tracked-merged` | `ISSUE-20260811-006` |
| [#1209](https://github.com/altstoreio/AltStore/issues/1209) | error when trying to install altstore: WinHttpQueryDataAvaliable: 12002: Operation timeout expired | 2023-06-20 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#1203](https://github.com/altstoreio/AltStore/issues/1203) | AltServer Windows Refresh Bug | 2023-05-07 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1180](https://github.com/altstoreio/AltStore/issues/1180) | Question about updating apps + altstore taking too much storage space | 2023-03-24 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1179](https://github.com/altstoreio/AltStore/issues/1179) | Questions about backup and recovery | 2023-11-23 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1174](https://github.com/altstoreio/AltStore/issues/1174) | Not able to clear cache | 2023-09-13 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#1170](https://github.com/altstoreio/AltStore/issues/1170) | Refresh failed | 2023-10-16 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#1158](https://github.com/altstoreio/AltStore/issues/1158) | BUG: Altstore expires earlier than it should | 2023-08-02 | bug | `tracked-merged` | `ISSUE-20260811-006` |
| [#1157](https://github.com/altstoreio/AltStore/issues/1157) | Mac dirty cow refresh more than 3 apps | 2023-03-08 | enhancement | `tracked-merged` | `ISSUE-20260811-006` |
| [#1156](https://github.com/altstoreio/AltStore/issues/1156) | Install fail after trying to restore or install a deactivated app | 2023-03-06 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#1148](https://github.com/altstoreio/AltStore/issues/1148) | BUG: Altstore takes equivalent space of the app it signed. | 2023-03-16 |  | `tracked-merged` | `ISSUE-20260811-006` |
| [#1136](https://github.com/altstoreio/AltStore/issues/1136) | Refreshing sideloaded app takes forever | 2024-01-21 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#1111](https://github.com/altstoreio/AltStore/issues/1111) | Backup and Restore Feature Question | 2023-11-07 | enhancement | `tracked-merged` | `ISSUE-20260811-006` |
| [#1103](https://github.com/altstoreio/AltStore/issues/1103) | AltStore Beta stole my App IDs from my Youtube alt app | 2024-11-16 | bug | `tracked-merged` | `ISSUE-20260811-006` |
| [#1073](https://github.com/altstoreio/AltStore/issues/1073) | Multiple App IDs from iPOGO without the actual app | 2023-01-11 | bug | `tracked-merged` | `ISSUE-20260811-006` |
| [#1066](https://github.com/altstoreio/AltStore/issues/1066) | Altstore and installed apps are invalid after refresh or installation | 2023-09-08 | bug | `tracked-merged` | `ISSUE-20260811-006` |
| [#1061](https://github.com/altstoreio/AltStore/issues/1061) | Apps can’t be deactivated after installing without extensions. | 2023-08-02 | bug | `tracked-merged` | `ISSUE-20260811-006` |
| [#1059](https://github.com/altstoreio/AltStore/issues/1059) | AltStore stopped working, then required an update - but failed to open because too many app registrations | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#1044](https://github.com/altstoreio/AltStore/issues/1044) | Dev Accounts with Organizations showing as Free | 2025-12-15 | bug | `tracked-merged` | `ISSUE-20260811-006` |
| [#1026](https://github.com/altstoreio/AltStore/issues/1026) | AltStore/Altserver crashes after renewing Apple Dev membership | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#964](https://github.com/altstoreio/AltStore/issues/964) | Fix for Altserver the background refreshing on Windows | 2023-01-11 | enhancement | `tracked-merged` | `ISSUE-20260811-006` |
| [#937](https://github.com/altstoreio/AltStore/issues/937) | You are not signed in | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#844](https://github.com/altstoreio/AltStore/issues/844) | The provided anatteled data is invalid | 2026-06-15 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#714](https://github.com/altstoreio/AltStore/issues/714) | "Invalid argument" error after updating to 1.4.5 | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#709](https://github.com/altstoreio/AltStore/issues/709) | AltStore refreshes my apps too many times per day | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#708](https://github.com/altstoreio/AltStore/issues/708) | AltStore can't refresh apps via shortcuts. | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#641](https://github.com/altstoreio/AltStore/issues/641) | Could not find Alt Server (Yes I read the FAQ and tried EVERTHING) | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260811-006` |
| [#288](https://github.com/altstoreio/AltStore/issues/288) | Manual refreshing or maybe good automatic refreshing | 2020-07-31 | enhancement | `tracked-merged` | `ISSUE-20260811-006` |
| [#131](https://github.com/altstoreio/AltStore/issues/131) | Error: You may only register 10 App ID's every 10 days | 2024-04-26 | bug | `tracked-merged` | `ISSUE-20260811-006` |

## 复核规则

- 上游状态或证据变化时，更新机器审计后重新生成本页。
- 只有共同所有者、风险和完成门禁一致时才继续合并；出现独立根因时拆出新的本地 Issue。
- 不在仓库复制正文、评论、附件、作者、Apple ID、UDID、证书或其他敏感材料。
