# Document Archive Rules

## 分类

- Workflow、knowledge、rules、README 和 `AGENTS.md` 是当前状态入口。内容过时应在原路径修正，不能按日期复制“新版”。
- Change、issue、ADR、release 和 archive record 是历史记录，必须有稳定 ID 和索引。
- `docs/archive/` 只保存已替代、已废弃或迁移后仍有历史参考价值的文档，不承载当前生效事实。

## 归档步骤

1. 确认旧文档不再是当前入口，并识别所有引用。
2. 将仍有效内容回写到 workflow、knowledge、rules 或 README/AGENTS。
3. 更新引用到替代文档，再移动旧文档。
4. 在 archive 记录原路径、归档日期、原因、替代文档、关联 change/issue/ADR 和迁移负责人。
5. 更新 `docs/archive/README.md` 与其他受影响索引，并执行链接检查。

## 限制

- 不把 build 产物、DerivedData、截图、PDF、数据库 dump、完整测试报告或大日志放入 `docs/archive/`。
- 不归档仍被构建、CI、README、AGENTS、topology 或当前 spec 引用的文件。
- 不用删除历史来“整理”文档；含敏感数据的历史应先按安全流程净化，并评估 Git 历史处理。
- 无历史价值且未被引用的临时草稿可以删除，但要在关联 change 中记录清理范围。
