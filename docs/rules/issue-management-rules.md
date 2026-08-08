# Issue Management Rules

## 何时登记

以下事项进入 `docs/issues/`：

- 已知缺陷、回归风险、技术债或兼容性缺口无法在当前 change 完成。
- 缺少设备、凭据、外部服务、平台或自动化设施，导致关键验证尚未执行。
- 上游状态、版本基线或产品范围需要后续决策。

当前正在执行的步骤留在 tasks/change；已经完成的事实留在 completed change；关键技术选择留在 ADR，不用 issue 代替它们。

## 内容与状态

- ID 使用 `ISSUE-YYYYMMDD-NNN-short-name`，并加入 `docs/issues/README.md` 索引。
- 至少记录状态、严重度/优先级、影响范围、证据、复现或触发条件、临时规避、完成条件和关联 `FR/DES/TEST/T/CHG/ADR`。
- 状态使用 `Open`、`Blocked`、`In progress`、`Resolved` 或 `Won't fix`。`Blocked` 必须写清解除条件和所有者。
- 外部 GitHub issue 作为关联证据，不替代仓库内的长期风险记录；记录 repository、issue/PR URL 和最后核对日期。

## 更新与关闭

- 新证据、严重度、规避方式或阻塞条件变化时更新原 issue，不创建重复文件。
- 关闭前必须满足完成条件，链接实现 commit/change 和实际验证；不能因“暂时未复现”直接标记 resolved。
- 关闭后从 active index 移到 resolved 区或保留明确状态，长期事实同步回 workflow/knowledge/verification。
- 被替代或不再适用时说明原因与替代记录，不静默删除历史。
