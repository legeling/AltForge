# CHG-20260808-001：建立 Spec Init 文档基线

- 状态：Completed
- 日期：2026-08-08
- 类型：Documentation / Process

## 背景

仓库已有成熟代码、README 和构建配置，但缺少 requirements、design、verification、tasks、knowledge、issues、ADR、release 与工程规则的稳定文档入口。

## 实际范围

- 建立 layered `docs/` 拓扑和 `spec-init.topology.yml`。
- 基于当前 workspace、targets、核心调用链、tests、dependencies、CI/release 配置编写项目文档。
- 建立项目级 `AGENTS.md` 和 README 文档导航。
- 登记 Unicode、build、distribution、Windows 和 Swift version 风险。

## 追踪

本 change 不修改产品 FR；它建立并验证了既有 `FR -> DES -> TEST -> T` 映射。

## 验证

- Markdown 相对链接检查。
- 追踪 ID 引用检查。
- `spec-init.topology.yml` 路由与实际文件检查。
- `git diff --check`。

## 收敛

当前事实已写入 workflow/knowledge/rules；本文件只保留初始化历史。
