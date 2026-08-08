# Document Routing Rules

## 路由

| 语义 | 路径 |
|---|---|
| 项目为什么存在 | `docs/workflow/00-intake/README.md` |
| 做什么、验收什么 | `docs/workflow/01-requirements/README.md` |
| 当前怎么实现 | `docs/workflow/02-design/README.md` |
| 先做什么后做什么 | `docs/workflow/03-implementation/README.md` |
| 如何证明正确 | `docs/workflow/04-verification/` |
| 当前具体任务 | `docs/workflow/05-tasks/README.md` |
| 长期术语/角色/边界 | `docs/knowledge/context/` |
| 长期模块/集成结构 | `docs/knowledge/structure/` |
| 长期流程/业务规则 | `docs/knowledge/behavior/` |
| 协议/命令/fixture 参考 | `docs/knowledge/reference/` |
| 单次变化 | `docs/changes/active/<change-key>/` 及其归档位置 |
| 未解决风险 | `docs/issues/` |
| 技术决策理由 | `docs/adr/` |
| 对外版本事实 | `docs/releases/` |
| 被替代历史 | `docs/archive/` |
| 项目默认工程约束 | `docs/rules/`，入口为 `docs/rules/README.md` |

## 边界

- Workflow 和 knowledge 描述当前真相，路径稳定；内容过时直接更新。
- Change、issue、ADR、release 和 archive 是记录型文档，使用稳定 ID。
- Rules 描述长期默认做法，不保存单次执行日志、任务状态或历史讨论。
- 任务不写进 design，技术选型不写进 requirements，单次命令日志不写进长期 verification。
- `docs/archive/` 不承载当前生效方案，也不保存运行产物。

## 编号

- Change：`CHG-YYYYMMDD-NNN-short-name`
- Issue：`ISSUE-YYYYMMDD-NNN-short-name`
- ADR：`ADR-YYYYMMDD-NNN-short-name`

## 同步

目录或路由变化时，同时更新：

- `docs/README.md`
- `AGENTS.md`
- `spec-init.topology.yml`
- 本文件
