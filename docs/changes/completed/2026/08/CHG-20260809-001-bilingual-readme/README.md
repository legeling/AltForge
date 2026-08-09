# CHG-20260809-001：建立中英双语 README 与项目改动说明

- 状态：Completed
- 日期：2026-08-09
- 类型：Documentation / Localization

## 背景

根 README 原本只有英文，且项目改动、上游差异、构建语言模式和当前限制散落在不同段落。中文用户无法直接切换到等价的仓库说明，后续更新也缺少双语同步约束。

## 实际范围

- 重写 `README.md`，明确 AltForge 相对上游的品牌、Unicode IPA、App ID、简体中文、开发团队、维护修复、CI/release 和文档治理变化。
- 新增 `README.zh-CN.md`，与英文版保持相同结构、能力边界、命令、下载方式和已知限制。
- 在两份 README 顶部提供 English/简体中文切换入口。
- 澄清 Xcode 26 是工具链版本，项目当前仍使用 Swift 5.0 language mode。
- 在 context、localization rule、doc sync rule 和文档入口中固化双语 README 的长期维护方式。
- 采用 Xcode 26 / Swift 5.0 language mode 的当前口径并解决 `ISSUE-20260808-002`；未来 Swift 6 migration 保留为独立决策。

## 追踪

本 change 不修改产品运行时需求或设计。README 对现有 `FR-004` 至 `FR-007`、`FR-014` 至 `FR-017` 和已完成 change 进行对外说明，不新增产品 `FR/DES/TEST/T`。

## 验证

- 检查两份 README 的章节和关键事实对齐。
- 检查全部本地 Markdown 链接与语言切换链接。
- 检查命令、artifact 名称、bundle identifier、系统要求和外部 URL 一致。
- 执行 Markdown whitespace/final-newline 与 `git diff --check`。

## 影响与未执行项

- 仅修改项目文档，不改变应用、签名、安装、构建或发布行为。
- 未运行 Xcode build/test；现有运行时验证状态和残余风险按 verification 与 issue register 原样披露。
