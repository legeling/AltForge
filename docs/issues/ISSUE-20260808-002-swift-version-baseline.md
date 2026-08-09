# ISSUE-20260808-002：Swift 版本基线口径不一致

- 状态：Resolved
- 优先级：P2
- 发现日期：2026-08-08
- 解决日期：2026-08-09

## 问题

README 写明 Swift 6，但 Xcode project 的 target build setting 当前为 `SWIFT_VERSION = 5.0`。Xcode 26 工具链可以编译 Swift 5 language mode，因此两者并非同一概念。

## 需要决策

1. README 改为 “Xcode 26 / Swift 5 language mode”；或
2. 计划迁移 Swift 6 language mode，并建立 concurrency warning/error 清理任务。

## 解决标准

README、project settings、CI 和文档使用一致口径；若迁移，相关 target 编译与测试通过。

## 解决结果

采用方案 1：英文与简体中文 README 均明确写为 “Xcode 26 toolchain / Swift 5.0 language mode”，与当前 project build setting 一致。未来是否迁移 Swift 6 language mode 仍可讨论，但必须作为独立 change 评估 concurrency diagnostics、兼容性和测试，不再与当前构建基线混写。
