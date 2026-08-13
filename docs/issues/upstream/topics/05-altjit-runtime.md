# AltJIT、Developer Disk、隧道与进程选择

- 上游仓库：[`altstoreio/AltStore`](https://github.com/altstoreio/AltStore)
- 最后核对：2026-08-11
- 开放 Issue：55 条
- 分类键：`jit`
- 处置分布：`tracked-merged` 55 条
- 本地映射：[`ISSUE-20260811-004`](../../ISSUE-20260811-004-altjit-runtime-compatibility.md)

## 主题边界

Developer Disk、pymobiledevice3、RemoteXPC/RSD、隧道、debugserver、PID 选择及新系统兼容。

## 合并依据

共同所有者位于 AltJIT 运行时适配层，且都依赖有界子进程、端口发现和失败清理。

## AltForge 处置

纳入当前范围；不得通过修改用户全局 Python、关闭安全机制或终止无关进程规避。

本分类是维护分流，不声称所有上游报告具有同一根因；本地实施仍需复现、定位并关联 `FR/DES/TEST/T/CHG`。

## 全部上游条目

| Issue | 标题 | 更新日期 | Labels | 处置 | 本地 Issue |
|---:|---|---|---|---|---|
| [#1725](https://github.com/altstoreio/AltStore/issues/1725) | issue while trying to do jit | 2026-03-09 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1711](https://github.com/altstoreio/AltStore/issues/1711) | AltJIT iPadOS 26.x: depends on system python/pymobiledevice3; causes mounter/start-tunnel/LibreSSL and dynamic RSD port failures | 2026-02-15 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1710](https://github.com/altstoreio/AltStore/issues/1710) | AltJIT: attach failed (Not allowed to attach) when app has multiple PIDs; needs PID retry/selection | 2026-02-15 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1666](https://github.com/altstoreio/AltStore/issues/1666) | ios26 can't us jit | 2025-10-26 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1644](https://github.com/altstoreio/AltStore/issues/1644) | No such command 'mounter' on MacOS 26 developer beta 4 | 2025-08-21 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1595](https://github.com/altstoreio/AltStore/issues/1595) | AltJIT failure | 2025-04-29 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1593](https://github.com/altstoreio/AltStore/issues/1593) | error trying to enable JIT | 2025-04-17 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1591](https://github.com/altstoreio/AltStore/issues/1591) | Support TCP-Based JIT Activation for iOS 18.2+ (QUIC Deprecated) | 2025-04-02 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1589](https://github.com/altstoreio/AltStore/issues/1589) | Can't enable JIT on iPadOS 17.5.1 | 2025-03-23 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1588](https://github.com/altstoreio/AltStore/issues/1588) | Please someone help me, im trying to enable JIT function on Dolphin for Ipad, but it says this: The URL to donwload the Developer disk image could not be determined. | 2025-03-14 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1545](https://github.com/altstoreio/AltStore/issues/1545) | AltJIT Failing with ConnectionError | 2025-03-06 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1543](https://github.com/altstoreio/AltStore/issues/1543) | Error Enabling JIT For All Apps | 2025-01-06 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1542](https://github.com/altstoreio/AltStore/issues/1542) | JIT could not be enabled(iOS18.2) | 2025-03-23 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1528](https://github.com/altstoreio/AltStore/issues/1528) | Error 0 when enabling JIT iPad mini 7 | 2025-02-18 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1503](https://github.com/altstoreio/AltStore/issues/1503) | AltServer.DeveloperDiskError 0 | 2024-08-06 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1497](https://github.com/altstoreio/AltStore/issues/1497) | Documentation on enabling JIT is outdated | 2024-08-16 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1488](https://github.com/altstoreio/AltStore/issues/1488) | Jit problem | 2024-06-23 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1487](https://github.com/altstoreio/AltStore/issues/1487) | JIT Could not be enabled for Altstore | 2025-04-14 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1483](https://github.com/altstoreio/AltStore/issues/1483) | Could not attach debugger to PojavLauncher. The process 'lldb' timed out. | 2024-07-17 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1474](https://github.com/altstoreio/AltStore/issues/1474) | JIT could not be enabled for DolphiniOS | 2024-05-25 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1470](https://github.com/altstoreio/AltStore/issues/1470) | Error: The URL to the developer disk image could not be determinded | 2024-05-19 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1467](https://github.com/altstoreio/AltStore/issues/1467) | Can't enable JIT on M4 iPad Pro | 2024-07-24 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1448](https://github.com/altstoreio/AltStore/issues/1448) | AltJIT not enabling for dolphinIOS | 2024-04-30 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1445](https://github.com/altstoreio/AltStore/issues/1445) | This is what happened to mine | 2024-05-17 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1424](https://github.com/altstoreio/AltStore/issues/1424) | [Error]The process 'altjit' failed with code 1. The process 'python3' failed with code 1. IndexError: list index out of range | 2024-04-17 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1420](https://github.com/altstoreio/AltStore/issues/1420) | Mobile image mounter error -256 | 2024-04-12 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1415](https://github.com/altstoreio/AltStore/issues/1415) | JIT could not be enabled for AltStore. ERROR Cannot enable developer-mode when passcode is set. | 2024-04-06 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1403](https://github.com/altstoreio/AltStore/issues/1403) | How to fix this problem? | 2025-01-10 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1398](https://github.com/altstoreio/AltStore/issues/1398) | error: externally-managed-environment | 2024-09-19 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1391](https://github.com/altstoreio/AltStore/issues/1391) | AltJIT not working? | 2024-03-09 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1388](https://github.com/altstoreio/AltStore/issues/1388) | Apple TV 4K > no JIT? | 2024-02-23 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1380](https://github.com/altstoreio/AltStore/issues/1380) | The process 'altjit' failed with code 1. Could not connect to device . The process 'python3' returned unexpected output. KeyError: EnumIntegerString.new(3, 'PUBLIC_KEY') | 2025-10-18 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1374](https://github.com/altstoreio/AltStore/issues/1374) | Is Altstore Jit enabled supported on older macbook air (2014)? Error on iphone ios 17.2.1 | 2024-04-20 | question | `tracked-merged` | `ISSUE-20260811-004` |
| [#1373](https://github.com/altstoreio/AltStore/issues/1373) | Unable to install jit using altstore (altserver ) | 2025-03-22 | question | `tracked-merged` | `ISSUE-20260811-004` |
| [#1372](https://github.com/altstoreio/AltStore/issues/1372) | [Error][AltServer.ProcessError 0] Now getting Python error along with altjit error. | 2024-12-21 | support | `tracked-merged` | `ISSUE-20260811-004` |
| [#1371](https://github.com/altstoreio/AltStore/issues/1371) | [Error]The process 'altjit' failed with code 1. The process 'python3' failed with code 1. stream.tell() failed | 2024-08-28 | support | `tracked-merged` | `ISSUE-20260811-004` |
| [#1368](https://github.com/altstoreio/AltStore/issues/1368) | Error code 2101 - 6s Plus on iOS 15.8 | 2024-01-23 | bug | `tracked-merged` | `ISSUE-20260811-004` |
| [#1358](https://github.com/altstoreio/AltStore/issues/1358) | No such command 'mounter'. | 2026-07-09 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1356](https://github.com/altstoreio/AltStore/issues/1356) | Unable to enable JIT (iOS 17.2 Beta (21C5054b)) | 2024-04-13 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1349](https://github.com/altstoreio/AltStore/issues/1349) | `The URL to download the Developer Disk image could not be determined` when trying to enable JIT on iOS17 | 2024-08-09 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1345](https://github.com/altstoreio/AltStore/issues/1345) | pymobiledevice3 update to 2.31.0 breaks enabling JIT | 2025-07-04 | bug | `tracked-merged` | `ISSUE-20260811-004` |
| [#1337](https://github.com/altstoreio/AltStore/issues/1337) | Failed to enable JIT for {app} / The Developer disk image could not be installed | 2024-04-14 | support | `tracked-merged` | `ISSUE-20260811-004` |
| [#1336](https://github.com/altstoreio/AltStore/issues/1336) | AltJIT timeouts too early while attempting to connect to device, resulting in python3 timed out. AltServer.ProcessError 0 | 2024-04-19 | bug | `tracked-merged` | `ISSUE-20260811-004` |
| [#1324](https://github.com/altstoreio/AltStore/issues/1324) | JIT could not be enabled:  developer_disk_image.exceptions.GithubRateLimitExceededError | 2023-11-08 | support | `tracked-merged` | `ISSUE-20260811-004` |
| [#1319](https://github.com/altstoreio/AltStore/issues/1319) | AltJIT activation fails (iPhone 15 Pro Max, ios17, MacOS Sonoma) | 2023-11-29 | support | `tracked-merged` | `ISSUE-20260811-004` |
| [#1317](https://github.com/altstoreio/AltStore/issues/1317) | AltJIT not working (URL Developer disk Image) | 2025-05-24 | support | `tracked-merged` | `ISSUE-20260811-004` |
| [#1315](https://github.com/altstoreio/AltStore/issues/1315) | AltJit activation fails: Syntax error | 2024-02-24 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1306](https://github.com/altstoreio/AltStore/issues/1306) | Can't Enable AltJIT on iOS 17 | 2024-08-19 | support | `tracked-merged` | `ISSUE-20260811-004` |
| [#1304](https://github.com/altstoreio/AltStore/issues/1304) | The process 'altjit' failed with code 1. Incompatible Architecture have x86_64, need Arm64 | 2024-04-03 | support | `tracked-merged` | `ISSUE-20260811-004` |
| [#1303](https://github.com/altstoreio/AltStore/issues/1303) | Developer disk image error. | 2023-10-07 | support | `tracked-merged` | `ISSUE-20260811-004` |
| [#1239](https://github.com/altstoreio/AltStore/issues/1239) | Could not use AltJIT on iOS 15.7.7 | 2023-10-19 |  | `tracked-merged` | `ISSUE-20260811-004` |
| [#1228](https://github.com/altstoreio/AltStore/issues/1228) | [Known Issue] Windows support for JIT on iOS 17 | 2024-03-13 | bug | `tracked-merged` | `ISSUE-20260811-004` |
| [#1208](https://github.com/altstoreio/AltStore/issues/1208) | Unable to refresh AltStore from device after enabling JIT and disconnecting the phone from PC | 2023-06-20 | support | `tracked-merged` | `ISSUE-20260811-004` |
| [#1084](https://github.com/altstoreio/AltStore/issues/1084) | Jit doesn't work on IOS 12.5 | 2023-01-11 | support | `tracked-merged` | `ISSUE-20260811-004` |
| [#1063](https://github.com/altstoreio/AltStore/issues/1063) | cannot install app - "You don't have permission" | 2023-05-24 | bug | `tracked-merged` | `ISSUE-20260811-004` |

## 复核规则

- 上游状态或证据变化时，更新机器审计后重新生成本页。
- 只有共同所有者、风险和完成门禁一致时才继续合并；出现独立根因时拆出新的本地 Issue。
- 不在仓库复制正文、评论、附件、作者、Apple ID、UDID、证书或其他敏感材料。
