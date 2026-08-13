# AltStore 上游 Issue 审计

本目录保存 AltForge 对 [`altstoreio/AltStore`](https://github.com/altstoreio/AltStore) 开放 Issue 的完整审计。它不是一个长页面的摘要，而是一套可导航、可复核、可增量更新的文档。

## 文档入口

| 文档 | 内容 |
|---|---|
| [`METHODOLOGY.md`](METHODOLOGY.md) | 数据获取、完整性校验、自动分类、人工复核和隐私处理 |
| [`SCOPE-AND-DISPOSITION.md`](SCOPE-AND-DISPOSITION.md) | 合并原则、处置状态、AltForge 范围与升级条件 |
| [`topics/`](topics/) | 15 份主题报告；每份包含完整条目清单和本地映射 |
| [`altstore-open-issue-audit.md`](altstore-open-issue-audit.md) | 645 条记录的单表附录，便于全文检索和交叉核对 |
| [`altstore-open-issue-audit.json`](altstore-open-issue-audit.json) | 机器可读的审计源，用于校验和重新生成主题报告 |

## 当前快照

- 审计日期：2026-08-11
- 状态范围：Open
- 上游 Issue：645 条
- 主题：15 个
- `tracked-merged`：429 条
- `covered-by-existing-requirements`：71 条
- `not-currently-planned`：52 条
- `out-of-scope`：47 条
- `insufficient-actionable-evidence`：46 条

这里的“合并”是把相同责任边界和验证门禁的上游报告汇总为本地长期风险，不是删除、关闭或宣称解决上游 Issue。每条上游记录仍可在主题报告、完整附录和 JSON 中追溯。

## 本地风险

真正影响 AltForge 当前交付的风险继续使用稳定的 `ISSUE-YYYYMMDD-NNN` 文件维护，并由 [`../README.md`](../README.md) 索引。上游主题报告提供证据，不替代本地 Issue 的影响、规避措施和关闭条件。
