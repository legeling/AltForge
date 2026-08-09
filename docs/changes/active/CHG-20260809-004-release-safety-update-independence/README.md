# CHG-20260809-004：发布安全与更新独立性

- 状态：In progress
- 日期：2026-08-09
- 类型：Security / Release / Maintenance

## 背景

审查确认官方 IPA source 已指向本仓库，但标签成功后会直接公开发布；Classic 启动仍从上游 CDN读取 feature flags 与 source 信任数据；用户支持、隐私和社交入口仍混用上游身份；release source 只包含一个 latest 版本。此外，Classic 本地 build number 与 source build number 的 nil/非 nil 差异可能产生伪更新。

## 范围

- 标签流水线只创建 Draft Release，公开发布保留人工审核门禁。
- 生成 tag 固定 IPA URL，并从上一正式 source 有界继承版本历史。
- 将 flags、known sources 和 recommended collections 作为本仓库 Release 资产，并停用上游官方 patron 列表同步。
- 修复 Classic 首次启动 buildVersion 对齐和 AltForge 离线 fallback identity。
- 将 GitHub、支持、隐私、FAQ、错误查询与桌面发布入口迁移到本仓库；隐藏不存在的官方社交/赞助入口。
- 在 Apple runner 上传前验证 IPA/DMG 的结构、身份、版本、Universal 架构和当前 non-Developer-ID policy（允许 Xcode linker ad-hoc、拒绝意外签名团队），并在创建 Draft 前复核全部 checksum。
- 保留 Apple 服务和开发者磁盘上游 CDN 等不可替代兼容依赖，并在文档中明确边界。

## 非范围

- 本次不实现 Sparkle、WinSparkle 或后台自动安装桌面更新。
- 不自建 Apple DeveloperDisk 镜像、Patreon OAuth 服务或社交网络账号。
- 不创建或发布真实 tag，不把本地静态检查描述为三平台构建通过。

## 追踪

`FR-021`-`FR-024` -> `DES-012` -> `TEST-021`-`TEST-024` -> `T-014`

## 复杂度与资源

source 合并只解析上一正式 `apps.json`，时间和内存均为 `O(versions + bytes)`，输出限制为当前版本加 19 个历史版本；远程配置是固定小文件。标签流水线仍保持 Apple/Windows job 各 60 分钟上限，Draft 不产生额外常驻进程或服务。网络调用沿用系统 URLSession 有界超时；配置失败时保留本地安全默认值。

## 风险与回滚

- Draft 未人工发布前 `releases/latest` 不可用，这是审核门禁的预期行为。
- 清空上游推荐/封禁列表会失去上游实时治理，应由 AltForge 维护者自行审查并更新本仓库配置。
- 回滚可恢复上一 source/入口配置，但不得恢复自动公开发布或无披露的上游远程控制。

## 收敛门禁

- [x] release workflow 只创建 Draft。
- [x] metadata contract 覆盖 tag URL、历史合并、20 条上限、去重和远程资产 checksum。
- [x] 启动期远程配置不再指向上游产品 CDN。
- [x] buildVersion 与离线 identity 已进入 repository contract，iOS 定向测试/构建与 macOS arm64 Release build 通过。
- [x] 用户可见支持/隐私/FAQ/仓库入口完成迁移并加入静态回归。
- [x] 本地验证结果与真实标签缺口同步到 verification。
- [x] Apple artifact verifier 与发布前 checksum verification 已接入 tag workflow。

## 已执行验证

- `ruby Scripts/test_release_metadata.rb`
- `ruby Scripts/test_repository_contract.rb`
- `ruby Scripts/check_release_version.rb --tag v2.4.0`
- `bash -n Scripts/verify_apple_release_artifacts.sh`
- 按 workflow 参数完成 macOS Universal Release build；Xcode 输出为无 Team ID/Authority 的 linker ad-hoc signature。使用该 App、临时 IPA 和正式 DMG packager 执行 Apple artifact verifier，通过 identity/version/build/architecture/image/signing-policy 检查。
- Ruby syntax check（release/version/policy scripts）
- iPhone 17 Pro Simulator 上运行 `testSourceID` 与 `testAltForgeSourceDeepLink`，2 项通过
- `AltServer` macOS arm64 Release build 通过；产物 Info.plist 为 `2.4.0 (88)`

未创建 tag，未触发真实 universal Apple/Windows job，因此新的 CI artifact verifier 尚未在 hosted runner 执行；GitHub Draft 页面、Windows 构建、入口点击或真实设备安装仍待验证。本地 DerivedData 已清理。
