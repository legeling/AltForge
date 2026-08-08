# Implementation Plan

## 当前阶段

AltForge 已有完整产品代码，不采用重写策略。当前实施重点是把维护型 fork 从“能构建的代码快照”推进为“有明确需求、验证门禁、发布流程和上游同步策略的可持续项目”。

## 里程碑

### M0：文档基线

- 建立 workflow、knowledge、changes、issues、ADR、releases、archive 与 rules。
- 记录当前 Classic 构建边界、最低系统、依赖、模块和真实测试缺口。
- 建立高优先级 `FR -> DES -> TEST -> T` 追踪链。

完成标准：文档不依赖聊天上下文即可指导下一轮修复。

### M1：构建与发布收敛

- 验证 CI 的 iOS Simulator、AltTests 和 macOS AltServer 构建。
- 验证 release metadata 脚本的输入校验、JSON 内容和 SHA-256。
- 明确 Xcode/Swift language mode 口径。

完成标准：干净 checkout 能使用锁定依赖完成 CI；失败不遗留不完整发布。

### M2：Unicode 与安装回归自动化

- 将中文显示名、UTF-8 filename、Unicode Path extra field、GBK filename、超长 filename 和 path traversal 变成受版本控制的 fixture。
- 在 AltSign 或可独立运行的 test target 中覆盖解压与 round trip。
- 使用真实 Apple ID/设备完成一次脱敏的安装验证记录。

完成标准：`FR-004`、`FR-005` 不再只依赖手工复测。

### M3：维护能力

- 建立定期上游同步与冲突审查流程。
- 提升 signing/install/refresh 的失败路径覆盖。
- 决定 notarization、Windows 与 Marketplace 目标的中期范围。

## 顺序与依赖

1. 文档与测试矩阵先于新兼容改动。
2. 本地可重复构建先于发布自动化承诺。
3. 自动化 archive fixture 先于继续扩展编码 fallback。
4. 真实设备 smoke test 只在代码级测试通过后执行，避免浪费 Apple 账户与设备资源。

## 容量与资源

- CI job 当前上限为 45 分钟，release job 为 60 分钟，并启用 concurrency cancellation。
- Swift package 与 CocoaPods 下载属于主要网络成本，应复用 runner cache 时评估一致性，不得使用无限缓存。
- IPA 处理成本与 archive entries 和总字节线性相关；测试 fixture 保持小型但覆盖格式边界。
- 真实设备、Apple ID、证书和 App ID quota 是稀缺资源，验证应有明确步骤和清理计划。

## 回滚

- 通用兼容修复回滚：恢复 AltSign gitlink 到上一已知提交，并同步 `.gitmodules`/ADR/change 记录。
- CI/release 回滚：撤回 workflow 变更，不删除已发布 tag；错误 release 通过 GitHub Release 标记或新 patch release 纠正。
- 数据模型变化必须提供 Core Data migration；当前文档初始化不涉及数据迁移。
