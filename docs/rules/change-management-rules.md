# Change Management Rules

## 开始前

- 检查 root 与相关 submodule 的 status，区分用户已有改动。
- 新功能、bugfix、重构或流程变化创建 `docs/changes/active/<change-key>/`。
- 至少建立一条 `FR -> DES -> TEST -> T` 链；阻塞性 `[待确认]` 未解决前不做大规模实现。
- Bug 修复、依赖升级和 release 分别同时遵循对应专项规则；小改动也不能跳过风险与文档同步判断。

## 实现中

- 修改限制在真实所有者：UI、Core、Shared、Server、AltSign 或 native dependency。
- 公共协议、Core Data schema、entitlement、bundle ID 和 submodule remote 属于高影响变更，必须评估迁移与兼容。
- 不覆盖用户已有 dirty changes，不做无关格式化。

## Submodule

1. 在 nested repo 创建/选择正确 branch。
2. 只提交 nested scope，并推送到可获取的 remote。
3. 在 superproject 更新 gitlink 和必要的 `.gitmodules`。
4. 验证 clean recursive clone 能获取 commit。

## 完成后

- 运行风险匹配的测试与 diff check。
- 回写 workflow/knowledge/verification/issues/ADR。
- Change 移到 completed 或 legacy。
- 提交遵循 [提交规则](commit-rules.md)，并只包含本 change 的逻辑范围。
- 未经用户要求不提交、推送、创建 tag、PR 或 release。
