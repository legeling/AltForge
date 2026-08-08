# Review And Pull Request Rules

## Review 顺序

1. 正确性、数据完整性、安全与权限。
2. 用户可见回归、兼容性、迁移和失败恢复。
3. 资源生命周期、并发、性能和可观测性。
4. 测试缺口、文档收敛和可维护性。
5. 风格与非必要建议。

- Finding 必须给出文件/行、触发条件、影响和可执行修复方向，并按严重度排序。
- 不把个人偏好写成 blocker；无法证实的问题标成 question/assumption。
- Review 不应顺手重写作者代码或扩大 scope。需要额外重构时单独建 issue/change。

## PR 内容

- 标题遵循 [提交规则](commit-rules.md)，正文说明背景、行为变化、风险、验证、截图/日志脱敏情况和关联 change/issue/ADR。
- PR 只包含一个逻辑目标；submodule PR/commit 和 superproject gitlink 更新必须互相链接。
- CI 必须与受影响 target 匹配。真实设备、签名、公证等无法在 CI 验证的项目要列为明确手工门禁。
- 不隐藏 skipped test、known failure、未公证产物或兼容限制；Draft 状态用于尚未达到 review 门禁的工作。
- 合并策略服从仓库维护者约定；没有明确要求时不擅自 force-push、squash、merge 或关闭 review thread。
