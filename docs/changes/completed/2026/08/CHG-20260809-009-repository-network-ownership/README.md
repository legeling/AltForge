# CHG-20260809-009 Repository Network Ownership

## 背景

AltForge 已把官方 source、Classic 远程配置和桌面更新入口切换到 `legeling/AltForge`，但代码扫描仍发现 Developer Disk 索引、遗留 Mail plug-in 和 OAuth callback 依赖上游控制面。依赖仓库、Apple/Patreon API、第三方 source 与 Developer Disk 文件本身又不能通过简单替换域名变成本仓库服务，因此需要先定义所有权边界，再收敛实现和自动检查。

## 范围

- 在 workflow/knowledge/release 文档中建立自有控制面、外部服务、构建依赖和 provenance 的分类。
- 将 macOS/Windows Developer Disk 索引纳入 AltForge Release；disk 文件仍使用经审核的第三方 HTTPS 来源。
- 统一 Classic flags、known sources、recommended collections 到本仓库 Release。
- 在 Classic 中关闭上游 Fediverse/CloudKit metadata 与交互更新路径。
- 移除未使用的遗留 Mail plug-in 更新/下载网络路径，只保留检测与卸载。
- 移除上游 Patreon callback；默认配置不完整时隐藏入口并在网络请求前失败。
- 扩展 repository/release contract 和双语 Release 文档。

## 非目标

- 不镜像或再分发 Apple Developer Disk 文件。
- 不把 Apple、Patreon 或第三方依赖 URL 伪装成 AltForge URL。
- 不启用或承诺当前 Classic Release 不包含的 Marketplace 服务。
- 不把历史 Marketplace/Fediverse API 的上游 URL 机械改成不兼容的 GitHub URL；Classic 通过编译条件和 fail-closed guard 保证不可达。
- 不批量改写上游版权、许可证、测试 fixture 和历史 provenance。

## 追踪链

`FR-028 -> DES-015 -> TEST-027 -> T-017`

## 实施顺序

1. 先补齐需求、设计、行为、reference、验证和本 change 文档。
2. 加入受版本控制的 Developer Disk 索引并接入两平台服务器和 Release。
3. 收敛 Classic 配置、遗留 plug-in 与 Patreon 默认行为。
4. 扩展 contract，运行 Ruby 检查、plist/JSON 解析与受影响 Apple build。
5. 将验证事实回写文档并 converge 到 completed。

## 复杂度与资源

- repository contract 对选定文本和 JSON 做单次扫描，时间复杂度 `O(repository text bytes)`，不引入网络请求。
- Developer Disk 索引解析为 `O(entries + bytes)`，输入由 Release 审核且规模有界。
- 运行时不增加重试或并发；索引仍是单次请求，实际文件下载保持原有单任务生命周期和临时目录清理。

## 风险与回滚

- 首次公开 Release 前 `releases/latest/download/developerdisks.json` 返回 404，JIT/旧系统 disk 下载不可用；发布前由 Draft 检查拦截，回滚可恢复上一版索引端点但会重新引入上游控制风险。
- 社区 Developer Disk URL 可能失效或内容变化；允许 host/schema 检查不能替代文件来源审查，更新索引必须单独 review。
- 默认 OAuth fail-closed 会让 pledge-protected source 无法连接 Patreon，直到维护者配置自有应用；这是避免冒用上游 callback 的有意安全行为。

## 验证计划

- `ruby Scripts/test_repository_contract.rb`
- `ruby Scripts/test_release_metadata.rb`
- `ruby Scripts/check_release_version.rb`
- `plutil -lint AltStoreCore/Resources/PatreonAPI.plist`
- 受影响 iOS Simulator 与 macOS AltServer build；Windows 由现有 CI build contract 覆盖，当前 macOS 主机不冒充 MSBuild 结果。

## 实际验证

- `ruby Scripts/test_repository_contract.rb`、`ruby Scripts/test_release_metadata.rb` 和 `ruby Scripts/check_release_version.rb` 通过。
- 四个 Release 配置 JSON 与三个受影响 string catalog 通过 Ruby JSON 解析；`PatreonAPI.plist` 通过 `plutil -lint`。
- `Scripts/test_repository_contract.rb`、metadata generator、DMG packager 和 Apple artifact verifier 通过语法检查；`git diff --check` 通过。
- `AltStore` Debug generic iOS Simulator build 与 `AltServer` Debug generic macOS build 均在关闭 code signing 后通过。
- 当前 macOS 主机未执行 Windows MSBuild 或真实设备网络验证；Windows endpoint 仅由静态 contract 覆盖。

## 结果与残余风险

- Classic 自有 metadata 和桌面更新入口已归属 `legeling/AltForge`；Fediverse/CloudKit、上游 patron 列表和遗留 plug-in 下载在 Classic 中不可达。
- Apple、Patreon、第三方 source、构建依赖和 Developer Disk 文件继续使用真实提供方；这类 URL 不是仓库控制面，不能伪装为 AltForge 托管。
- 首次公开 Release 前，`releases/latest/download/*` 仍可能返回 404；发布门禁必须先审核 Draft 中的完整 metadata 和 checksum。
- 历史 Marketplace/Fediverse 实现仍保留用于上游同步，但当前工程不定义 `MARKETPLACE`。未来启用需要自有兼容后端、凭据和新的 change。

## 收敛清单

- [x] workflow 与 knowledge 文档先行
- [x] Runtime/Release 实现完成
- [x] Contract 与 build 验证完成
- [x] 验证事实和残余风险已回写
- [x] 移入 `completed/2026/08/`
