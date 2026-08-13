<p align="center">
  <img src="assets/brand/altforge-wordmark.png" width="520" alt="AltForge">
</p>

# AltForge Documentation

本目录是 AltForge 的长期文档源。文档采用分层结构，避免把项目目标、当前设计、单次变更和历史记录混在一起。

仓库简介：[English](../README.md) | [简体中文](../README.zh-CN.md)

## 阅读顺序

1. [项目背景与边界](workflow/00-intake/README.md)
2. [需求与验收标准](workflow/01-requirements/README.md)
3. [当前系统设计](workflow/02-design/README.md)
4. [长期项目上下文](knowledge/context/README.md)
5. [模块与集成结构](knowledge/structure/README.md)
6. [关键行为与失败路径](knowledge/behavior/README.md)
7. [实施路线](workflow/03-implementation/README.md)
8. [验证计划与质量门禁](workflow/04-verification/README.md)
9. [当前任务](workflow/05-tasks/README.md)

## 文档分层

| 层级 | 用途 | 入口 |
|---|---|---|
| Workflow | 当前项目要做什么、怎么做、怎么验证 | [`docs/workflow/`](workflow/) |
| Knowledge | 长期稳定的术语、结构、行为和参考资料 | [`docs/knowledge/`](knowledge/) |
| Changes | 单次需求、修复或流程变更的生命周期 | [`docs/changes/`](changes/) |
| Records | Issue、ADR、发布、归档和工程规则 | [`docs/issues/`](issues/)、[`docs/adr/`](adr/)、[`docs/releases/`](releases/)、[`docs/archive/`](archive/)、[`docs/rules/`](rules/) |

上游 AltStore Issue 的完整审计位于 [`docs/issues/upstream/`](issues/upstream/)：审计方法、范围与处置、15 份主题报告、645 条逐项附录和机器数据彼此分离，根目录 Issue Register 只维护 AltForge 自身风险。

## 当前基线

- 产品形态：AltStore Classic 派生项目，由 iOS 端 AltForge 与 macOS 端 AltServer 协作完成侧载。
- 主分支：`marketplace`，但当前发布配置明确构建 Classic 版本，不嵌入 Marketplace extension。
- 构建入口：`AltStore.xcworkspace`。
- 工具链：Xcode 26；项目当前 `SWIFT_VERSION` 为 5.0，两份根 README 均已明确区分工具链版本和 Swift language mode。未来迁移 Swift 6 language mode 需要独立 change 与验证。
- 最低系统：iOS 17.4、macOS 11；`AltJIT` 最低 macOS 13。
- 发布产物：未签名 IPA、未公证的 macOS AltServer、未签名的 Windows AltServer ZIP、`apps.json`、三类自有远程配置 JSON 与校验和；标签流水线只创建 Draft。
- 本地 macOS 试装：[DMG 构建、安装与清理指南](guides/local-macos-validation.md)。
- Release CDN：[版本固定对象、Actions 变量、完整性与回滚要求](guides/release-cdn.md)。
- 已知重点：Unicode IPA 兼容、简体中文、本地构建可复现性、签名安装链路测试。

## 维护规则

- 当前事实写入 workflow 或 knowledge，不用新文件制造第二份真相。
- 新功能、bugfix、重构和流程变化必须创建 change 记录，并同步需求、设计和验证文档。
- 未解决风险进入 [`docs/issues/`](issues/)，关键技术取舍进入 [`docs/adr/`](adr/)。
- 默认工程治理规则从 [`docs/rules/README.md`](rules/README.md) 进入；提交前至少检查 [提交规则](rules/commit-rules.md) 和 [Definition of Done](rules/definition-of-done.md)。
- 文档路由以 [`spec-init.topology.yml`](../spec-init.topology.yml) 和 [`docs/rules/document-routing-rules.md`](rules/document-routing-rules.md) 为准。
