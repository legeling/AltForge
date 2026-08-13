# CHG-20260812-001：重签名时保留 HealthKit 能力

## 背景

AltSign 会从原应用的 entitlement 推导需要在 Apple Developer Portal App ID 上启用的 feature，再生成新的 provisioning profile。当前映射覆盖 App Groups 和 Inter-App Audio，但没有识别基础 HealthKit entitlement `com.apple.developer.healthkit`，因此带 HealthKit 的 IPA 在重签名后可能得到不包含 HealthKit 能力的 profile。

本变更选择性移植 [AltStore #1762](https://github.com/altstoreio/AltStore/pull/1762) 与 [AltSign #45](https://github.com/rileytestut/AltSign/pull/45) 的通用修复到 AltForge 维护的 AltSign fork，不直接采用上游 submodule gitlink。

## 范围

- 在 AltSign 中加入 `com.apple.developer.healthkit` 与 Apple App ID feature `HK421J6T7P` 的双向映射。
- 只映射基础 Boolean entitlement；`com.apple.developer.healthkit.access` 等次级 entitlement 不是 App ID feature 值，不纳入映射。
- 在 AltTests 中覆盖双向映射和次级 entitlement 不被误映射的回归。
- 不修改 Server Protocol、Core Data schema、Apple ID 凭据处理、HealthKit 数据访问或应用自身 entitlement 内容。

## 追踪链

- Requirement `FR-038`：重签包含基础 HealthKit entitlement 的应用时，生成的 App ID feature 集合必须包含 `HK421J6T7P`，且不得把次级 HealthKit entitlement 当作 App ID feature。
- Design `DES-024`：能力映射继续由 `Dependencies/AltSign/AltSign/Capabilities/ALTCapabilities` 统一维护，使用现有双向纯函数，不在 AltStore 或 AltServer UI 层重复判断。
- Verification `TEST-037`：验证 entitlement 到 feature、feature 到 entitlement 的双向映射，并验证 `com.apple.developer.healthkit.access` 返回无映射；完成无签名 iOS 构建。真机 profile 生成与安装另行验证。
- Task `T-026`：移植映射、补回归、验证 build，并按 submodule 交付顺序提交 AltSign 后更新 superproject gitlink。

## 复杂度与资源

每次映射仍是固定数量字符串比较，时间和空间复杂度均为 `O(1)`；不增加网络请求、并发任务、缓存、进程、端口或长期文件。App ID 注册和 profile 获取次数保持不变。

## 验证计划

- 运行包含 `testHealthKitCapabilityMapping` 的 AltTests。
- 构建 AltSign Swift package 或受影响的 iOS target，确认 Objective-C 常量可从 Swift 正确导入。
- 执行 `git diff --check`，并检查 nested repo 与 superproject 差异范围。
- 使用包含 HealthKit entitlement 的脱敏测试 App 在真机完成 App ID、profile、重签和安装验证；在此之前不宣称设备链路已验证。

## 已执行验证

- 2026-08-12：`testHealthKitCapabilityMapping` 在 iOS 26.5 Simulator 通过，覆盖双向映射和次级 entitlement 不被映射。
- 2026-08-12：该定向测试同时完成 AltSign、AltStore、AltStoreCore、AltWidgetExtension 与 AltTests 的 Debug Simulator build。
- 2026-08-12：`ruby Scripts/test_repository_contract.rb`、root/submodule `git diff --check` 通过。
- 2026-08-13：`v2.4.1` Release workflow 将 `testHealthKitCapabilityMapping` 纳入 hosted iOS 定向回归，避免只依赖本机历史结果；标签 CI 完成后回填 hosted 结果。

## 当前状态

代码与自动化验证完成，真机 App ID、profile、重签和安装验证待执行。完成真机验证前 change 保持 active。

## 回滚

先在 AltSign fork 回退 HealthKit 常量和双向映射，再更新 superproject gitlink；同时移除对应回归测试。该回滚不会更改已注册 App ID、profile、数据库或设备数据。
