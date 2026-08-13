# ISSUE-20260811-005：设备发现与 AltServer 连接缺少跨平台实机矩阵

- 状态：Open
- 优先级：P1
- 发现日期：2026-08-11
- 关联：`DES-002`、`TEST-019`、`TEST-026`、`TEST-030`、`TEST-035`、`T-012`、`T-016`、`T-019`、`T-024`

## 问题

完整上游审计将 34 条开放 Issue 归入设备发现与连接：设备未出现、AltServer 找不到、USB/Wi-Fi 行为不一致、配对或信任失败、传输中断和 socket reset。AltForge 当前已有 discovery/transport 设计和连接类型诊断，但没有覆盖 macOS、Windows、USB、Wi-Fi、锁屏、断线和多设备的统一真机矩阵。

## 代表性证据

- [#292](https://github.com/altstoreio/AltStore/issues/292)：连接到 AltServer 时中断。
- [#1605](https://github.com/altstoreio/AltStore/issues/1605)：Windows Classic Wi-Fi 找不到 AltServer。
- [#1606](https://github.com/altstoreio/AltStore/issues/1606)：Windows 显示没有连接设备。
- [#1756](https://github.com/altstoreio/AltStore/issues/1756)：与设备通信失败。
- [#1769](https://github.com/altstoreio/AltStore/issues/1769)：刷新时 socket connection reset。

该主题的 34 条开放报告和逐条处置见 [`upstream/topics/03-device-discovery-and-connectivity.md`](upstream/topics/03-device-discovery-and-connectivity.md)。这些报告可能包含不同根因，本 issue 只合并共同的发现、连接、超时、错误可见性和资源释放门禁。

## 风险

- UI 显示设备存在，但实际选中了不可用或错误的 Server/连接方式。
- Wi-Fi 与 USB fallback 行为不同，断线后留下无限进度、迟到回调或重复任务。
- Windows 与 macOS 使用不同设备服务，单平台 smoke 不能代表另一平台。

## 完成条件

1. 建立 macOS 与 Windows、USB 与 Wi-Fi、单设备与多设备的有界矩阵；记录连接类别但不记录 UDID、设备名、Server ID 或配对材料。
2. 覆盖设备锁定、拔线、Wi-Fi 切换、Server 退出、发现超时和协议不兼容；均返回明确阶段与可恢复错误。
3. 同一设备重复操作只保留一条 activity；断线、取消和失败释放连接、临时文件、进度窗口与任务锁。
4. 验证 Server 选择不会被 stale discovery 结果覆盖，迟到回调不能完成新任务。
5. 把结果写回 `TEST-019`、`TEST-026`、`TEST-030`、`TEST-035` 与对应 tasks。

## 回滚

本 issue 不要求改变 Server Protocol。若 discovery 调整造成回归，应恢复既有匹配逻辑并保留新增的超时、诊断和资源清理测试。
