# Change Index

单次新需求、bugfix、重构或流程变化先进入 `active/`，完成收敛后移动到 `completed/YYYY/MM/`，放弃或被替代时进入 `legacy/YYYY/MM/`。

## Active

| ID | 标题 | 状态 |
|---|---|---|
| [`CHG-20260808-003`](active/CHG-20260808-003-upstream-maintenance-fixes/README.md) | 上游维护修复筛选与移植 | In progress |

## Completed

| ID | 标题 | 完成日期 |
|---|---|---|
| [`CHG-20260808-001`](completed/2026/08/CHG-20260808-001-spec-baseline/README.md) | 建立 Spec Init 文档基线 | 2026-08-08 |
| [`CHG-20260808-002`](completed/2026/08/CHG-20260808-002-unicode-ipa-compatibility/README.md) | Unicode IPA 安装兼容 | 2026-08-08 |
| [`CHG-20260808-004`](completed/2026/08/CHG-20260808-004-project-governance/README.md) | 补齐项目工程治理与提交规则 | 2026-08-08 |
| [`CHG-20260809-001`](completed/2026/08/CHG-20260809-001-bilingual-readme/README.md) | 建立中英双语 README 与项目改动说明 | 2026-08-09 |

## 记录要求

- change key 使用 `CHG-YYYYMMDD-NNN-short-name`。
- 至少记录背景、范围、需求/设计/测试/任务映射、实际验证、影响和残余风险。
- completed change 不承担当前事实；当前事实必须回写 workflow/knowledge/rules。
