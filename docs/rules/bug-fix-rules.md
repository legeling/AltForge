# Bug Fix Rules

## 修复前

- 记录可复现输入、期望、实际结果、环境、错误链和首次已知版本；敏感输入必须脱敏或重建最小 fixture。
- 从真实调用链确定所有者模块，不在上层用字符串替换、重试或吞错掩盖底层缺陷。
- 搜索本仓库、submodule、上游 issue/PR/commit 和现有测试；引用外部结论时保留稳定链接与适用版本。
- 建立 active change。长期未解决、无法本轮验证或需要上游协调的风险同时登记 issue。

## 修复中

- 先形成失败测试或最小可重复 harness，再实施最小正确修改。
- 同时覆盖正常、边界、失败和清理路径。Archive、路径、URL、签名和外部响应必须包含恶意或畸形输入。
- 不通过降低验证、放宽权限、静默丢数据或无限重试换取“可用”。
- 修复跨模块契约时，生产者和消费者必须一起验证；修复 submodule 时遵循 [依赖与 Submodule 规则](dependency-and-submodule-rules.md)。

## 回归与收敛

- P0/P1 或曾在真实用户路径出现的 bug 应补持久自动化回归。暂时只能用 harness/手工验证时，创建测试缺口 issue 并写明转自动化条件。
- 验证应证明“修复前失败、修复后通过”，并检查相邻兼容路径没有回归。
- 把长期行为回写 requirements/design/knowledge/verification，实际过程写入 completed change；不要只留 commit message。
- 上游已有修复时记录来源、差异和后续同步策略，避免未来 merge 重复实现。
