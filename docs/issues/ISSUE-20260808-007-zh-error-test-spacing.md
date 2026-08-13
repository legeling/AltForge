# ISSUE-20260808-007：简体中文环境下错误描述测试存在空格假设

- 状态：Open
- 优先级：P1
- 发现日期：2026-08-08

## 问题

完整 `AltTests` 在首选语言为 `zh-Hans` 的 iOS Simulator 上有 12 个错误桥接测试失败。失败集中在 `localizedFailure` 与 `localizedFailureReason` 的连接空格：测试固定期望英文式单空格，而 Foundation 在中文 locale 下生成无空格描述；部分 wrapped/serialized error 又显式添加空格，造成往返不一致。

## 影响

- 不影响本轮 source identity 定向测试和 iOS/macOS 编译。
- 错误结构化字段仍存在，但完整测试无法作为简体中文回归门禁。
- 直接给中文翻译加前导空格会污染 UI，不能作为修复。

iOS 运行时、UI 与本地化主题的 59 条开放报告与逐条处置见 [`upstream/topics/08-ios-runtime-ui-and-localization.md`](upstream/topics/08-ios-runtime-ui-and-localization.md)。

## 解决标准

明确错误描述的跨 locale 契约，并让 `ALTLocalizedError`、`ALTWrappedError`、`CodableError` 与测试使用同一连接规则；在英文和 `zh-Hans` simulator 上运行完整 `AltTests` 均通过。
