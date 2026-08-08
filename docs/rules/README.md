# Engineering Rules

本目录定义 AltForge 项目级默认规则。它补充但不降低用户或全局 `AGENTS.md` 中的安全、性能、资源和 Git 要求。

## 日常开发

- [编码标准](coding-standards.md)
- [Bug 修复规则](bug-fix-rules.md)
- [澄清与决策规则](clarification-rules.md)
- [测试标准](testing-standards.md)
- [Localization 规则](localization-rules.md)
- [安全与隐私规则](security-and-privacy-rules.md)
- [进程与资源规则](process-and-resource-rules.md)

## 协作与交付

- [变更管理](change-management-rules.md)
- [提交规则](commit-rules.md)
- [Review 与 PR 规则](review-and-pr-rules.md)
- [Issue 管理](issue-management-rules.md)
- [依赖与 Submodule 规则](dependency-and-submodule-rules.md)
- [发布规则](release-rules.md)
- [Definition of Done](definition-of-done.md)

## 文档治理

- [文档路由](document-routing-rules.md)
- [文档同步](doc-sync-rules.md)
- [文档归档](document-archive-rules.md)

## 适用方式

- 先服从用户指令与仓库根目录 `AGENTS.md`，再应用本目录中与任务相关的规则。
- 多条规则同时适用时采用更严格且不破坏正确性的要求；存在真实冲突时记录取舍，而不是静默选择。
- 规则定义默认工程行为，不替代 requirements、design、verification、change、issue 或 release 记录。
- 不适用的检查应标记为 `N/A` 并说明原因，不能伪装成已经通过。

规则变化属于流程变更，必须建立 change 记录，并同步项目级 `AGENTS.md` 与必要的 workflow 文档。
