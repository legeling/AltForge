# Commit Rules

## 权限与边界

- 只有用户明确要求时才创建 commit。Push、tag、PR、release 和历史改写需要各自明确授权，不能从“提交”自动推断。
- 提交前检查 root 与相关 submodule 状态，区分本任务、用户已有修改和生成产物。
- 脏工作区使用 `git add -- <explicit-paths>` 或等价的精确暂存方式；禁止用 `git add -A`、`git add .` 混入无关改动。
- 一个 commit 只包含一个可解释、可审查、可回滚的逻辑变化。功能、无关重构、格式化和文档清理不得捆绑。

## 提交信息

默认格式：

```text
<type>(<optional-scope>): <imperative summary>
```

允许的 `type`：`feat`、`fix`、`docs`、`refactor`、`test`、`build`、`ci`、`chore`、`revert`。

- Summary 使用简洁英文祈使语气，首字母小写，不加句号，建议不超过 72 个字符。
- Scope 只在能提高定位效率时使用，例如 `altserver`、`altsign`、`docs`、`ci`。
- 高风险行为、兼容性取舍、迁移、submodule 更新或未完成验证必须写 body；简单且自解释的文档提交可省略 body。
- Body 解释 why、behavior、verification 和 residual risk，不逐行复述 diff。
- 不加入秘密、个人信息、内部路径、无关 issue，也不自动添加 AI attribution 或未经确认的 co-author。

示例：

```text
fix(altsign): preserve Unicode archive paths
docs: establish project governance rules
test(altstorecore): cover malformed source URLs
```

## 提交前门禁

1. 运行与改动风险匹配的测试、build、静态检查或可重复验证。
2. 执行 `git diff --cached --check`。
3. 审查 `git diff --cached --stat`、`git diff --cached` 和 staged file list。
4. 确认 staged 内容没有凭据、设备信息、证书、profile、Cookie、构建目录或用户无关修改。
5. 确认 change、issue、verification、README/AGENTS 等已按 [文档同步规则](doc-sync-rules.md) 收敛。
6. 未执行测试或残余风险写入 change/issue，并在交付说明中明确报告。

## Submodule 提交

1. 先在 nested repository 提交其真实代码变更。
2. 确认目标 remote 能获取 nested commit；需要交付时先推送 nested commit。
3. 再在 superproject 提交 gitlink 与必要的 `.gitmodules`、文档或测试调整。
4. Superproject commit body 记录 nested commit ID、remote/fork 原因和验证状态。

禁止提交 dirty submodule 指针、只存在本机的 nested commit，或把 nested diff 伪装成普通目录变更。

## 提交后

- 核对 `git show --stat --oneline HEAD` 与预期范围一致。
- 保留用户未纳入本 commit 的修改，不回滚、不清理、不声称工作区整体 clean。
- Push 前再次确认分支、remote、upstream 和是否需要先推送 submodule。
