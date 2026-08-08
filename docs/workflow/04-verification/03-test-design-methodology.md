# Test Design Methodology

## 等价类与边界值

### IPA filename

- ASCII、合法 UTF-8、UTF-8 但 flag 缺失。
- Unicode Path extra field：有效 CRC、错误 CRC、截断字段、未知 version。
- GB18030/GBK、Big5、Shift-JIS、EUC-KR。
- 0 bytes、最大 ZIP filename 长度、超长 path component。
- directory trailing slash、`__MACOSX`、绝对路径、`.`、`..`。

### App ID name

- 纯 ASCII、带重音拉丁字符、纯中文、中英混合。
- 中文父 app + 英文 extension、leading/trailing/multiple whitespace。
- punctuation only、empty result、极长名称。

### Source ID

- scheme、default/non-default port、query、fragment、大小写、duplicate slash、IDN/emoji、relative URL。

## 状态机

安装状态至少覆盖：

```text
selected -> downloaded -> verified -> provisioned -> signed -> sent -> installed
                       \-> failed
```

每个 transition 都要验证失败不会越级写入后续成功状态；retry 必须幂等或明确替换旧临时状态。

Refresh 覆盖 active/inactive、即将到期、已过期、server missing、device disconnected 与部分 app 失败。

## 决策表

对安装至少组合：source/local IPA、existing/new App ID、free/paid team、main app/extension、server preferred/fallback、Unicode/ASCII name。

## 安全设计

- Path traversal 与 archive bomb：拒绝非法 path；对 entry 数、声明大小与磁盘容量建立后续上限测试。
- Credential handling：检查 OSLog privacy 和 Codable sanitization。
- Release supply chain：锁定 dependency、校验产物 hash、最小 GitHub token permission。

## 并发与资源

- 取消 download/operation group 时任务能结束并清理临时文件。
- 多 app refresh 不产生无界 task fan-out。
- 连接断开、timeout 和 completion 重入只完成一次。
- archive 失败后文件可删除，表明 handle 已释放。

## 契约测试

- `ServerProtocol` 编码/解码前后语义一致。
- 新字段的 optional/default 行为明确。
- `apps.json` 与 AltStore source model 能双向约束关键字段。
- Git submodule commit 在 fork remote 可获取。
