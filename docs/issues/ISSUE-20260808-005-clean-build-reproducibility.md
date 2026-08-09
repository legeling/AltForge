# ISSUE-20260808-005：干净 checkout 完整构建尚未验证

- 状态：Open
- 优先级：P1
- 发现日期：2026-08-08
- 关联：`FR-014`、`DES-009`、`TEST-011`、`TEST-012`、`T-002`

## 现状

- 首次 hosted Apple build 已运行，但 runner 自带 CocoaPods 1.17.0 与 `Podfile.lock` 的 1.16.2 不一致，构建在依赖恢复阶段失败。
- tag-driven Release workflow 现已固定安装 CocoaPods 1.16.2，并定义递归 submodule、Swift package resolution、source ID test、unsigned iOS build 和 AltServer build；修复尚待下一版本标签复验。
- 本地 `swift build` AltSign 曾因 OpenSSL header 集成方式失败；workspace 依赖解析曾受网络下载阻塞。
- 这些环境失败不证明产品代码失败，也不能替代干净 workspace 构建。

## 解决标准

在干净 clone 或 CI 上执行锁定命令并保存摘要；确认所有 submodule commit 可从配置 remote 获取，且失败任务没有遗留 process、DerivedData 或临时服务。
