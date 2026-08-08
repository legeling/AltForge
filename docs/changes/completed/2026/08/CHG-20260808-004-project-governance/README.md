# CHG-20260808-004：补齐项目工程治理与提交规则

- 状态：Completed
- 日期：2026-08-08
- 类型：Documentation / Process

## 背景

初始 Spec Init 基线已经覆盖 workflow、knowledge、changes 和 verification，但 `docs/rules/` 只包含文档、测试、变更和完成门禁，尚不足以指导日常编码、提交、Bug 修复、澄清、Issue、依赖、发布和资源生命周期。

## 实际范围

- 新增编码、提交、Bug 修复、澄清、Issue、归档、安全、资源、依赖/Submodule、Localization、Review/PR 与发布规则。
- 重组 rules index，明确规则优先级、适用方式和文档边界。
- 在项目级 `AGENTS.md` 固化提交格式、精确暂存、验证和授权边界。
- 更新文档入口、同步规则、路由和 Definition of Done。

## 追踪

本 change 不改变产品需求或运行时设计，因此不新增产品 `FR/DES/TEST/T`。它补齐所有 change 在 analyze、implement、converge 和 commit 阶段的治理门禁。

## 验证

- 检查全部 Markdown 相对链接及规则索引覆盖。
- 检查 `spec-init.topology.yml` 中全部路由目标。
- 检查既有 `FR -> DES -> TEST -> T` 映射未被破坏。
- 执行 whitespace/final-newline 和 staged diff 范围检查。

## 影响与回滚

- 仅影响项目文档与后续协作约定，不改变应用运行时行为。
- 如某条规则不适合未来工作流，应通过新的 process change 修改并保留原因，不直接删除历史记录。

## 未执行项

- 未运行 Xcode build/test；本 change 只修改 Markdown 与项目文档入口，不触及构建或运行时代码。
