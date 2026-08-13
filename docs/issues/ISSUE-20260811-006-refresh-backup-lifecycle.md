# ISSUE-20260811-006：刷新、停用、备份与失败清理缺少完整回归

- 状态：Open
- 优先级：P1
- 发现日期：2026-08-11
- 关联：`FR-008`、`DES-001`-`DES-003`、`TEST-015`、`TEST-017`、`T-008`、`T-010`

## 问题

完整上游审计将 49 条开放 Issue 归入 refresh、deactivate、backup/restore、App ID、到期时间和失败清理。AltForge 已有到期天数下限、安装恢复日志和部分清理防护，但 `TEST-015` 仍缺失，不能证明刷新取消、部分失败、停用恢复和缓存清理在当前系统上保持原子与幂等。

## 代表性证据

- [#1158](https://github.com/altstoreio/AltStore/issues/1158)：应用早于预期到期。
- [#1203](https://github.com/altstoreio/AltStore/issues/1203)：Windows refresh 路径失败。
- [#1439](https://github.com/altstoreio/AltStore/issues/1439)：到期天数显示为负数。
- [#1526](https://github.com/altstoreio/AltStore/issues/1526)：刷新后已安装应用不可用。
- [#1594](https://github.com/altstoreio/AltStore/issues/1594)：侧载应用刷新耗时异常。

该主题的 49 条开放报告和逐条处置见 [`upstream/topics/04-refresh-backup-and-lifecycle.md`](upstream/topics/04-refresh-backup-and-lifecycle.md)。

## 风险

- 部分刷新失败后，数据库、App ID、备份目录和设备实际状态不一致。
- 取消或断线留下缓存、临时 IPA、重复队列或不可恢复的停用状态。
- 到期、证书或团队信息过时，使 UI 声称成功但应用无法启动。

## 完成条件

1. 为 `TEST-015` 建立 fixture，覆盖 refresh 成功、用户取消、单 App 失败、多 App 部分失败、Server 断线和应用终止恢复。
2. 覆盖 deactivate 后 restore、backup 缺失/损坏、App extension 变化和 App ID 上限；不得损坏原安装或删除无关备份。
3. 验证失败和取消均清理 task-owned 临时文件、连接和 operation context，同一记录不会重复恢复。
4. 到期天数、证书有效期和团队类型使用同一已确认数据源，不显示负数或错误成功状态。
5. 在 macOS/Windows 中至少各完成一次脱敏刷新路径，并将结果写回 `TEST-015`、`TEST-017` 与 tasks。

## 回滚

测试和清理防护不得改变数据库 schema 或 Server Protocol。若新的恢复策略误伤有效数据，回退恢复写入，同时保留失败 fixture、资源所有权和诊断覆盖。
