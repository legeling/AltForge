# Documentation Sync Rules

## 触发矩阵

| 变化 | 必须同步 |
|---|---|
| 用户行为/验收变化 | requirements、verification、tasks、change |
| 模块/协议/数据边界变化 | design、knowledge/structure、verification、ADR（有取舍时） |
| install/refresh/source 状态规则变化 | knowledge/behavior、verification、coverage map |
| target、依赖、最低系统变化 | README、design、reference、CI、verification |
| 用户可见文本/localization 变化 | requirements（若行为变）、test matrix、README（若能力变） |
| README 中的项目事实、安装或发布说明变化 | `README.md`、`README.zh-CN.md`、change、相关 workflow/knowledge |
| bugfix | completed change、对应 issue、回归 test、coverage map |
| release | releases、README、issues/known risks |
| submodule commit/remote 变化 | design、knowledge/structure、ADR/change |
| 工程规则/提交约定变化 | rules index、AGENTS、change、相关 workflow/knowledge |

## Converge 检查

实现完成后：

1. 代码行为与 `FR`/`DES` 一致。
2. 实际执行的测试更新到 verification；未执行项明确保留。
3. 长期事实写回 knowledge，不只留在 change。
4. Active change 移到 completed/legacy。
5. 已解决 issue 更新状态；新增残余风险登记 issue。
6. README/AGENTS/topology 路由保持有效。
7. 新增规则已进入 rules index，且没有与更高优先级规则冲突。

禁止声称未实际执行的 build/test 通过。
