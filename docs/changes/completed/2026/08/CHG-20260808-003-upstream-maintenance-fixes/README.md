# CHG-20260808-003：上游维护修复筛选与移植

- 状态：Completed with residual test gaps
- 日期：2026-08-08
- 类型：Bugfix / Maintenance

## 背景

上游积累了大量 Issue 和 PR。本 change 只移植与当前 Classic 版本一致、改动局部且能在本地验证的修复，不整批合并陈旧、草稿或会改变签名/entitlement 契约的分支。

## 实际实现

- 客户端和 AltServer 支持 organization developer team fallback。
- 已过期应用显示天数下限为零，不显示负数。
- macOS 错误详情保留 attributed formatting，同时允许选择和复制文本。
- 发现并记录 AltSign Classic 基线不匹配；未留下 dirty submodule 或不可复现 gitlink。

## 追踪

`FR-008`, `FR-011`, `FR-017` -> `DES-003`, `DES-008` -> `TEST-016`, `TEST-017` -> `T-010`

## 复杂度与资源

团队 fallback 最多扫描三次小型团队数组，时间复杂度为 `O(n)`、额外空间为 `O(1)`。其余两项为 `O(1)` UI 状态调整。没有新增依赖、网络请求、缓存、后台进程或长期资源。

## 实际验证

- `git diff --check` 通过。
- AltStore iOS Simulator 构建及 `AltTests/AltTests/testSourceID` 通过。
- AltServer macOS Debug build 通过。
- 完整 `AltTests` 在简体中文 simulator 上执行，但 12 个既有错误描述测试因空格假设失败，见 `ISSUE-20260808-007`。

## 残余风险与回滚

真实 organization account/设备未执行，随 AltSign Classic 基线迁移一起处理，见 `ISSUE-20260808-006`。三个行为修复相互独立，可分别回退对应 Swift 行；没有数据迁移或持久格式变化。
