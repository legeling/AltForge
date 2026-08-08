# Dependency And Submodule Rules

## 依赖选择

- 优先使用 Apple SDK、标准库和仓库已有依赖；简单问题不引入大型框架或重复能力。
- 新依赖必须评估维护状态、license、security、平台/最低系统兼容、二进制体积、构建时间、运行成本和替代方案。
- 依赖版本使用项目既有锁定机制：CocoaPods 对应 `Podfile.lock`，SwiftPM 对应 workspace `Package.resolved`，submodule 对应 gitlink。
- 依赖升级不与无关功能混合，必须阅读 release notes，验证受影响 target，并记录 breaking change 与回滚版本。

## Submodule 工作流

1. 检查 root 和 nested repository 的 branch、status、remote 与 gitlink。
2. 在真实所有者 submodule 内做最小修改与验证，不在 superproject 复制实现。
3. Nested commit 必须存在于团队可访问 remote；fork 的存在理由和 upstream 关系写入 ADR/change。
4. 再更新 superproject gitlink、`.gitmodules`、文档和相关集成验证。
5. 使用 clean recursive clone 或等价检查确认依赖 commit 可获取。

## AltForge 约束

- `Dependencies/AltSign` 当前使用 `legeling/AltSign` fork；上游为 `rileytestut/AltSign`。同步前比较 fork commit 与 upstream 差异。
- 其他 submodule 默认保持既有 remote，除非有明确维护需求和 ADR/change。
- 不提交 dirty submodule、不可获取 commit、临时本地 URL 或包含凭据的 remote。
- 修改依赖源码的 patch 必须说明为何不能在上层解决，以及如何回馈或跟踪上游。
