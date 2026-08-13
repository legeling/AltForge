# Linux 与远程 AltServer

- 上游仓库：[`altstoreio/AltStore`](https://github.com/altstoreio/AltStore)
- 最后核对：2026-08-11
- 开放 Issue：3 条
- 分类键：`linux`
- 处置分布：`out-of-scope` 3 条
- 本地映射：无

## 主题边界

Linux AltServer、永久远程 Server 和非本地网络部署。

## 合并依据

当前实现与发布只覆盖 macOS 和 Windows，远程 Server 还会改变认证、网络与信任边界。

## AltForge 处置

当前范围外；不能作为现有桌面端的隐式兼容承诺。

本分类是维护分流，不声称所有上游报告具有同一根因；本地实施仍需复现、定位并关联 `FR/DES/TEST/T/CHG`。

## 全部上游条目

| Issue | 标题 | 更新日期 | Labels | 处置 | 本地 Issue |
|---:|---|---|---|---|---|
| [#1515](https://github.com/altstoreio/AltStore/issues/1515) | Permanent non-local AltServer | 2024-09-21 |  | `out-of-scope` | - |
| [#712](https://github.com/altstoreio/AltStore/issues/712) | AltStore for Linux | 2024-06-14 | enhancement | `out-of-scope` | - |
| [#6](https://github.com/altstoreio/AltStore/issues/6) | Req: AltServer on linux | 2026-07-23 | enhancement | `out-of-scope` | - |

## 复核规则

- 上游状态或证据变化时，更新机器审计后重新生成本页。
- 只有共同所有者、风险和完成门禁一致时才继续合并；出现独立根因时拆出新的本地 Issue。
- 不在仓库复制正文、评论、附件、作者、Apple ID、UDID、证书或其他敏感材料。
