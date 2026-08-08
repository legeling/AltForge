# CHG-20260808-003：上游维护修复筛选与移植

- 状态：In progress
- 日期：2026-08-08
- 类型：Bugfix / Maintenance

## 背景

上游积累了大量 Issue 和 PR。本 change 只移植与当前 Classic 版本一致、改动局部且能在本地验证的修复，不整批合并陈旧、草稿或会改变签名/entitlement 契约的分支。

## 范围

- 客户端和 AltServer 支持 organization developer team fallback。
- 已过期应用显示天数下限为零，不显示负数。
- macOS 错误详情保留 attributed formatting，同时允许选择和复制文本。
- 记录 AltSign Classic 基线不匹配为独立 P0 issue，不留下无法复现的 submodule 改动。

## 追踪

`FR-008`, `FR-011`, `FR-017` -> `DES-003`, `DES-008` -> `TEST-016`, `TEST-017` -> `T-010`

## 复杂度与资源

团队 fallback 最多扫描三次小型团队数组，时间复杂度为 `O(n)`、额外空间为 `O(1)`。其余两项为 `O(1)` UI 状态调整。没有新增依赖、网络请求、缓存、后台进程或长期资源。

## 计划验证

- `git diff --check` 与文档链接/追踪检查。
- iOS Simulator AltStore build/test。
- macOS AltServer build。
- 真实 organization account 仍需后续脱敏设备测试。

## 回滚

三个行为修复相互独立，可分别回退对应 Swift 行；没有数据迁移或持久格式变化。
