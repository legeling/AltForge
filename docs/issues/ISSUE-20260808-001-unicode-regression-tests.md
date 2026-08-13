# ISSUE-20260808-001：Unicode IPA 修复缺少持久自动化测试

- 状态：Open
- 优先级：P1
- 发现日期：2026-08-08
- 关联：`FR-004`、`FR-005`、`DES-005`、`TEST-003`、`TEST-005`-`TEST-007`、`T-001`

## 问题

AltSign 已支持 Unicode App ID sanitize、UTF-8/Unicode Path/legacy East Asian filenames 与 UTF-8 ZIP 输出。GBK 解压和 UTF-8 round trip 曾通过临时 harness，但测试程序与 fixture 未进入版本控制。

## 风险

上游同步、minizip 更新或 archive 重构可能静默恢复中文包安装失败；路径安全和资源释放也没有长期回归门禁。

## 上游证据

最后核对：2026-08-11。以下 `altstoreio/AltStore` Issue 均仍为 Open，说明这不是只存在于 AltForge fixture 中的理论风险：

- [#1056：Windows Unicode code page 无法映射](https://github.com/altstoreio/AltStore/issues/1056)，最后更新 2025-02-09。
- [#1108：中文 display name 导致 “The app is invalid”](https://github.com/altstoreio/AltStore/issues/1108)，最后更新 2023-01-11。
- [#1150：App 名称包含无效字符](https://github.com/altstoreio/AltStore/issues/1150)，最后更新 2024-08-30。
- [#1240：Windows 无法处理 IPA 内不允许的路径字符](https://github.com/altstoreio/AltStore/issues/1240)，最后更新 2024-04-16。

这些条目只作为外部复现证据；AltForge 仍以自己的 Unicode/ZIP fixture 和安全路径测试作为关闭门禁。IPA、签名和归档主题的 81 条开放报告与逐条处置见 [`upstream/topics/02-ipa-signing-and-packaging.md`](upstream/topics/02-ipa-signing-and-packaging.md)。

## 解决标准

- 建立可独立运行的 AltSign test target 或等价受控 harness。
- 覆盖 `TEST-003`、`TEST-005`、`TEST-006`、`TEST-007`。
- Fixture 符合脱敏、确定性生成与清理规则。
