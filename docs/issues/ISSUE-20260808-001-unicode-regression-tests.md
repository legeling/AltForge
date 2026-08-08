# ISSUE-20260808-001：Unicode IPA 修复缺少持久自动化测试

- 状态：Open
- 优先级：P1
- 发现日期：2026-08-08
- 关联：`FR-004`、`FR-005`、`DES-005`、`TEST-003`、`TEST-005`-`TEST-007`、`T-001`

## 问题

AltSign 已支持 Unicode App ID sanitize、UTF-8/Unicode Path/legacy East Asian filenames 与 UTF-8 ZIP 输出。GBK 解压和 UTF-8 round trip 曾通过临时 harness，但测试程序与 fixture 未进入版本控制。

## 风险

上游同步、minizip 更新或 archive 重构可能静默恢复中文包安装失败；路径安全和资源释放也没有长期回归门禁。

## 解决标准

- 建立可独立运行的 AltSign test target 或等价受控 harness。
- 覆盖 `TEST-003`、`TEST-005`、`TEST-006`、`TEST-007`。
- Fixture 符合脱敏、确定性生成与清理规则。
