# 设备发现、USB、Wi-Fi 与 Server 连接

- 上游仓库：[`altstoreio/AltStore`](https://github.com/altstoreio/AltStore)
- 最后核对：2026-08-11
- 开放 Issue：34 条
- 分类键：`device-connectivity`
- 处置分布：`tracked-merged` 34 条
- 本地映射：[`ISSUE-20260811-005`](../../ISSUE-20260811-005-device-discovery-connectivity.md)

## 主题边界

设备枚举、配对与信任、Bonjour discovery、USB/Wi-Fi fallback、连接中断、socket reset 和多设备选择。

## 合并依据

共同门禁是跨平台连接矩阵、超时、迟到回调隔离、任务去重与资源释放。

## AltForge 处置

纳入当前范围，并统一合并到设备发现与连接实机验证。

本分类是维护分流，不声称所有上游报告具有同一根因；本地实施仍需复现、定位并关联 `FR/DES/TEST/T/CHG`。

## 全部上游条目

| Issue | 标题 | 更新日期 | Labels | 处置 | 本地 Issue |
|---:|---|---|---|---|---|
| [#1769](https://github.com/altstoreio/AltStore/issues/1769) | Failed to refresh app. Socket(Os { code: 54, kind: ConnectionReset, message: "Connection reset by peer" }) | 2026-07-27 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1767](https://github.com/altstoreio/AltStore/issues/1767) | Putaek84/altstore | 2026-07-13 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1756](https://github.com/altstoreio/AltStore/issues/1756) | Error «There was an error communicating with your device» | 2026-06-27 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1685](https://github.com/altstoreio/AltStore/issues/1685) | AltServer on macOS 26.1 crashes during Backup step when deactivating apps on iPhone 17 (iOS 26.1), causing ServerError 2002 (USB) / Operation Error 1200 (Wi-Fi) | 2025-12-08 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1648](https://github.com/altstoreio/AltStore/issues/1648) | The connection to AltServer was lost when trying to install any app. | 2025-09-02 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1606](https://github.com/altstoreio/AltStore/issues/1606) | Altserver says no connected device | 2026-08-04 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1605](https://github.com/altstoreio/AltStore/issues/1605) | (Windows) (AltStore Classic) AltServer could not be found (Error 1200) over Wi-Fi | 2025-06-26 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1585](https://github.com/altstoreio/AltStore/issues/1585) | when im downloading Null`s brawl(650MB) it stops at 70-80% then says "Connection to altstore was lost" but when i downloaded Delta(roblox exploit)(160MB) its downloading | 2026-05-11 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1532](https://github.com/altstoreio/AltStore/issues/1532) | Altserver could not be found error over wifi | 2025-04-09 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1525](https://github.com/altstoreio/AltStore/issues/1525) | iPhone no longer connecting to iTunes after iOS 18 update | 2025-05-05 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1491](https://github.com/altstoreio/AltStore/issues/1491) | There's something wrong with installing AltStore | 2024-06-26 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1377](https://github.com/altstoreio/AltStore/issues/1377) | AltServer could not sign in with your Apple ID. The network connection was lost. | 2024-10-07 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1332](https://github.com/altstoreio/AltStore/issues/1332) | Altserver cannot find this device | 2023-11-03 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#1283](https://github.com/altstoreio/AltStore/issues/1283) | Apps not installing | 2023-10-30 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#1262](https://github.com/altstoreio/AltStore/issues/1262) | Error communicating with device. (0xe800800D) | 2023-08-19 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1182](https://github.com/altstoreio/AltStore/issues/1182) | Suggestion of WIFI Refresh Faild(Could not find Altserver) | 2023-06-17 |  | `tracked-merged` | `ISSUE-20260811-005` |
| [#1114](https://github.com/altstoreio/AltStore/issues/1114) | Patron - cannot add repos | 2023-01-24 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#1106](https://github.com/altstoreio/AltStore/issues/1106) | Can I connect to altserver remotely? | 2026-05-13 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#1081](https://github.com/altstoreio/AltStore/issues/1081) | What apps do I need to whitelist from my VPN for Altstore to detect my iOS devices? | 2025-07-30 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#1007](https://github.com/altstoreio/AltStore/issues/1007) | iPod Touch 7G not being detected in AltServer | 2026-04-03 | bug | `tracked-merged` | `ISSUE-20260811-005` |
| [#994](https://github.com/altstoreio/AltStore/issues/994) | [App Source Support] yattee as Trusted source | 2023-08-15 | enhancement, source request | `tracked-merged` | `ISSUE-20260811-005` |
| [#980](https://github.com/altstoreio/AltStore/issues/980) | [bug] Installation Failed: "rename error" | 2025-07-21 | bug | `tracked-merged` | `ISSUE-20260811-005` |
| [#903](https://github.com/altstoreio/AltStore/issues/903) | Custom Icons Don’t Work | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#838](https://github.com/altstoreio/AltStore/issues/838) | iPhone can't be detected by AltServer and iTunes | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#780](https://github.com/altstoreio/AltStore/issues/780) | Is it possible to connect when pc connects the router through a cable? | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#754](https://github.com/altstoreio/AltStore/issues/754) | Installing an app cancels after a few minutes | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#716](https://github.com/altstoreio/AltStore/issues/716) | Cannot connect to altstore after recent update. | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#683](https://github.com/altstoreio/AltStore/issues/683) | Unable to refresh over WiFi on Beta 1.5.0.3 | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#344](https://github.com/altstoreio/AltStore/issues/344) | Could not find Altserver, iphone 11 | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#339](https://github.com/altstoreio/AltStore/issues/339) | Couldn't connect to AltServer (Mac) | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#292](https://github.com/altstoreio/AltStore/issues/292) | "The connection to Altserver was dropped" | 2023-01-17 | support | `tracked-merged` | `ISSUE-20260811-005` |
| [#163](https://github.com/altstoreio/AltStore/issues/163) | Allow specifying AltServer IP Address | 2022-11-29 | enhancement | `tracked-merged` | `ISSUE-20260811-005` |
| [#26](https://github.com/altstoreio/AltStore/issues/26) | Multiple device support | 2023-01-09 | enhancement | `tracked-merged` | `ISSUE-20260811-005` |
| [#5](https://github.com/altstoreio/AltStore/issues/5) | [Discussion] Using local VPN to install IPAs | 2020-08-02 | enhancement | `tracked-merged` | `ISSUE-20260811-005` |

## 复核规则

- 上游状态或证据变化时，更新机器审计后重新生成本页。
- 只有共同所有者、风险和完成门禁一致时才继续合并；出现独立根因时拆出新的本地 Issue。
- 不在仓库复制正文、评论、附件、作者、Apple ID、UDID、证书或其他敏感材料。
