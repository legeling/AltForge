# Test Strategy And Quality Gates

## 测试层级

| 层级 | 用途 | 默认触发 |
|---|---|---|
| Unit | URL normalization、encoding、metadata、错误映射 | 所有纯逻辑变化 |
| Integration | Operation graph、Core Data、client/server Codable contract、archive round trip | 跨模块契约变化 |
| Build | iOS Simulator、macOS app、extension embedding、localization catalog | 每个 PR 与 `marketplace` push |
| Packaging | IPA layout、source JSON、checksums、universal archive | release workflow 或发布脚本变化 |
| Manual E2E | Apple auth、provisioning、device install、refresh、JIT | signing/device/OS compatibility 变化 |

## 风险等级

- **P0**：凭据泄露、签名损坏、路径穿越、错误 release、数据破坏。
- **P1**：无法安装/刷新、Unicode 包失败、协议不兼容、Core Data migration 失败。
- **P2**：source/UI/localization/Widget/诊断退化。
- **P3**：非关键视觉或维护性改动。

## 合并门禁

- P0/P1 修复必须有失败前可复现、失败路径断言和回归用例；无法自动化时要有 issue 与明确手工步骤。
- 所有代码改动必须通过 `git diff --check` 和相关 target 编译。
- `Shared/` 协议变化必须同时验证 client 与 server。
- `AltStoreCore` model 变化必须验证 migration 或说明无 schema 变化。
- `Dependencies/AltSign` 变化必须在 nested repo 验证并更新 superproject gitlink。
- 用户可见字符串变化必须通过 string catalog 构建并检查英文/简体中文 fallback。
- release workflow 变化必须使用临时 artifact 进行 dry run，不得用真实 tag 作为第一次测试。

## 准出标准

- 高优先级 FR 有对应 TEST，且状态不是未知。
- CI build 与选定 XCTest 通过。
- 未执行的真实设备测试和残余风险已记录。
- 无敏感 fixture、日志或凭据进入 diff。
- 当前 change 完成 converge，相关 issues/coverage map 已更新。
