<p align="center">
  <img src="../docs/assets/brand/altforge-wordmark.png" width="420" alt="AltForge">
</p>

# Release Remote Configuration

本目录是 AltForge Classic 远程配置的受版本控制来源。标签流水线校验这些 JSON，并将其复制到 Draft Release；客户端只读取最新已公开 Release 中的同名资产。

- `flags.json`：feature flags。默认空对象，不允许从上游产品配置继承值。
- `sources.json`：可信与封禁 source。默认只信任 AltForge 官方 source，不封禁第三方 source。
- `recommended-sources.json`：推荐 source 集合。默认空数组。
- `developerdisks.json`：macOS/Windows 共用的 Developer Disk 下载索引。索引由本仓库发布，实际 disk/archive 属于外部兼容依赖。

修改这些文件等同于修改运行时策略，必须经过代码审查、JSON/contract 验证和 Release 说明披露。Developer Disk 条目必须使用 HTTPS，只允许 `github.com` 或 `raw.githubusercontent.com`，并且每项只能使用 `archive` 或 `disk` + `signature`。配置失败时客户端保留本地已有值或安全默认行为；不要在此存放凭据、用户数据或无限增长的列表。
