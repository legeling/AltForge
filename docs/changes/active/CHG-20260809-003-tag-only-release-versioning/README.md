# CHG-20260809-003：收敛 tag-only 构建与统一版本

- 状态：In progress
- 日期：2026-08-09
- 类型：Build / Release

## 背景

仓库版本只通过 GitHub Release 对外分发，因此自动构建不再由普通 branch push 或 pull request 触发。此前 iOS、macOS AltServer 和 Windows AltServer 分别保留 `2.3.12`、`1.7.2b` 与 `1.7.4.0`，容易让同一套发布产物被理解为不同产品版本。

## 范围

- 以根目录 `VERSION` 的纯数字 `X.Y.Z` 作为三平台产品版本唯一来源；首个包含本地化和三平台统一交付能力的 AltForge 功能版本定为 `2.4.0`。
- 从 `2.4.0` 起独立按语义版本递增；上游产品版本只记录为 provenance，上游同步不直接改变 AltForge 版本。
- 删除 branch/PR CI workflow，只允许匹配 `v*` 的 Release workflow 自动构建；preflight 要求 tag 严格等于 `v${VERSION}`。
- 用脚本检查 Xcode、Windows resource 与 vcpkg manifest 的产品版本 contract；CI build number 继续使用 GitHub run number。
- 把原 CI 的 source identity test 和 metadata contract 纳入标签流水线，避免取消普通 CI 后丢失关键发布门禁。
- 固定 CocoaPods 1.16.2，并在 Windows workspace 检出 `vcpkg.json` 声明的固定 commit，修复 hosted run 暴露的 runner 工具漂移和已 deindex port 问题。

## 追踪

`FR-020` -> `DES-010` -> `TEST-020` -> `T-013`

## 复杂度与资源

版本检查只读取固定数量的小型文本/JSON 文件，时间与文件字节数线性相关，内存有界。删除普通 push/PR workflow 后不会产生日常 runner 消耗；每个标签最多启动一个 prepare、一个 Apple、一个 Windows 和一个 publish job，各 job 保持明确超时。固定依赖会增加一次 CocoaPods gem 安装和一次 vcpkg checkout，但换取可复现的工具版本。

## 风险与回滚

- tag-only 模式会降低合并前反馈速度，维护者必须在打标签前运行本地 preflight 和受影响平台测试。
- 当前开发机不能完成 Windows MSBuild；固定 vcpkg 的修复必须由下一次明确授权的标签构建验证。
- 回滚时可恢复 branch/PR CI 并删除 tag-only 限制，但不得放宽 tag 与产品版本一致性后静默替换已发布产物。

## 收敛门禁

- [x] 根版本与 iOS、macOS、Windows 产品版本完成统一。
- [x] 只保留 tag-triggered GitHub Actions workflow。
- [x] 关键 metadata/source identity 门禁进入 Release workflow。
- [ ] 下一版本标签完成 Apple 与 Windows hosted build。
- [ ] 发布完成后新增对应 release record，并更新相关 issue/task 状态。

## 已执行验证

- `ruby Scripts/check_release_version.rb --tag v2.4.0`：通过；使用不匹配标签的负向用例按预期拒绝，确认当前产品版本为 `2.4.0`。
- `ruby Scripts/test_release_metadata.rb`：通过。
- `ruby -c Scripts/check_release_version.rb`、Ruby YAML parser、`plutil -lint AltStore.xcodeproj/project.pbxproj` 与 `git diff --check`：通过。
- `actionlint 1.7.7`：忽略其尚未收录的 GitHub-hosted `macos-26` label 后通过；该 runner 已在首次 hosted run 实际启动。
- 本机未安装 PowerShell/MSBuild，未执行 Windows build；真实标签构建尚未执行，不能据此声称三平台发布已通过。
