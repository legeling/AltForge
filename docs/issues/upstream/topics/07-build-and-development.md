# 源码构建与开发环境

- 上游仓库：[`altstoreio/AltStore`](https://github.com/altstoreio/AltStore)
- 最后核对：2026-08-11
- 开放 Issue：6 条
- 分类键：`build-development`
- 处置分布：`tracked-merged` 6 条
- 本地映射：[`ISSUE-20260808-005`](../../ISSUE-20260808-005-clean-build-reproducibility.md)

## 主题边界

Xcode、submodule、AltSign clone、版本字段、开发构建和仓库提问规范。

## 合并依据

可执行构建故障合并到干净 checkout 可复现性；纯提问和仓库模板不创建产品风险。

## AltForge 处置

维护构建基线，但不把一般支持请求自动升级为缺陷。

本分类是维护分流，不声称所有上游报告具有同一根因；本地实施仍需复现、定位并关联 `FR/DES/TEST/T/CHG`。

## 全部上游条目

| Issue | 标题 | 更新日期 | Labels | 处置 | 本地 Issue |
|---:|---|---|---|---|---|
| [#1651](https://github.com/altstoreio/AltStore/issues/1651) | Failed to run on iOS 26 Devices using Xcode 26 | 2025-09-09 |  | `tracked-merged` | `ISSUE-20260808-005` |
| [#1421](https://github.com/altstoreio/AltStore/issues/1421) | What is the best way to build and run my own local app in AltStore? | 2024-04-19 |  | `tracked-merged` | `ISSUE-20260808-005` |
| [#694](https://github.com/altstoreio/AltStore/issues/694) | Cannot clone `AltSign` | 2023-01-13 | support | `tracked-merged` | `ISSUE-20260808-005` |
| [#617](https://github.com/altstoreio/AltStore/issues/617) | READ BEFORE CREATING NEW ISSUE | 2023-01-13 | Announcement | `tracked-merged` | `ISSUE-20260808-005` |
| [#356](https://github.com/altstoreio/AltStore/issues/356) | unable to Build AltServer | 2020-09-21 | bug | `tracked-merged` | `ISSUE-20260808-005` |
| [#246](https://github.com/altstoreio/AltStore/issues/246) | Consider CFBundleVersion string | 2020-06-05 | enhancement | `tracked-merged` | `ISSUE-20260808-005` |

## 复核规则

- 上游状态或证据变化时，更新机器审计后重新生成本页。
- 只有共同所有者、风险和完成门禁一致时才继续合并；出现独立根因时拆出新的本地 Issue。
- 不在仓库复制正文、评论、附件、作者、Apple ID、UDID、证书或其他敏感材料。
