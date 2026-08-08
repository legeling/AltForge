# Definition Of Done

一个 AltForge 变更完成需要满足适用项：

- [ ] 范围能回链到需求、设计、验证和任务 ID。
- [ ] 修改位于正确模块，没有复制已有体系。
- [ ] 公共协议、schema、entitlement、bundle ID 和 submodule 影响已评估。
- [ ] P0/P1 变化有自动化回归；无法自动化时有 issue 与手工验证记录。
- [ ] iOS/macOS 受影响 target 已构建，或明确报告未执行原因。
- [ ] 用户可见文本已本地化。
- [ ] 敏感数据未进入代码、日志、fixture、docs 或 commit。
- [ ] 临时文件、DerivedData、process、port、connection 和 device session 已清理。
- [ ] `git diff --check` 通过，未混入用户无关改动。
- [ ] Staged file list 和 staged diff 已复核；commit message 与实际行为一致。
- [ ] Workflow、knowledge、verification、issues、ADR、README/AGENTS 已按需同步。
- [ ] 新增/修改规则已进入 rules index，记录型文档已进入对应 index。
- [ ] Change 已归档到 completed/legacy，active 不残留已完成事项。
- [ ] 残余风险、未执行测试和回滚路径已记录。
