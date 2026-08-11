# CHG-20260811-003：修复 iOS 系统崩溃报告与公开品牌残留

## 背景

iOS 主应用虽然已将 `CFBundleDisplayName` 改为 AltForge，但 `CFBundleName` 和实际 executable 仍由历史 target 名 `AltStore` 派生。应用崩溃时，系统问题报告因此仍显示“AltStore 意外退出”。同时，部分 storyboard、string catalog、证书/App Group 描述和诊断日志仍向用户暴露 AltStore 或 AltServer。

## 范围

- 主应用的 `CFBundleName` 与 Debug/Release executable 改为 `AltForge`，AltTests 同步指向新的 executable。
- 保留 `AltStore` target、scheme、Swift module、`AltStore.app` 包目录、兼容 URL scheme、Core Data 名称、旧 bundle identifier 和协议符号，避免破坏上游同步、storyboard module、IPA packaging 与用户数据兼容。
- 扫描 iOS storyboard、XIB、string catalog、公开元数据、证书/App Group 新建名称和诊断文本；当前产品统一使用 AltForge / AltForge Server。
- `AltStore PAL`、`AltStore 2.0`、第三方 source、上游致谢和旧 AltStore 证书识别继续保留其真实名称。
- AltSign 仍使用历史本地化 key 的错误通过主 App catalog 覆盖显示值，不修改或污染 submodule。

## 映射

- Requirement：`FR-035`
- Design：`DES-021`
- Verification：`TEST-034`
- Task：`T-023`

## 复杂度与资源

运行时只读取固定 bundle metadata，时间与空间均为 `O(1)`，不增加网络、并发、缓存或持久资源。仓库回归扫描按 storyboard/XIB/string catalog 总字节线性执行，时间为 `O(resource bytes)`，只保留当前文件的解析结果，空间受仓库内有限本地化资源约束。

## 验证记录

- repository contract 在实现前因旧 `CFBundleName`/executable 失败；实现后 `ruby Scripts/test_repository_contract.rb` 与 `ruby Scripts/test_release_metadata.rb` 通过。
- 全部 iOS string catalog 和 AltServer catalog 通过 JSON 解析；`AltStore/Info.plist` 与 pbxproj 通过 `plutil -lint`；`git diff --check` 通过。
- 有界 `xcodebuild build` 在 `generic/platform=iOS Simulator` 通过；产物 `AltStore.app/Info.plist` 的 `CFBundleDisplayName`、`CFBundleName`、`CFBundleExecutable` 均为 `AltForge`，`AltStore.app/AltForge` 为 arm64/x86_64 Universal Mach-O。
- `xcodebuild build-for-testing` 通过，AltTests host 能随新的 AltForge executable 完成链接。构建仍报告项目既有的 deprecated API、Sendable 和 classic linker warnings，本 change 未扩大处理范围。
- 首次 build 暴露同一 dirty worktree 中 interrupted-operation 记录的访问级别与 `JSONDecoder` 歧义；仅补 `fileprivate` 和 `Foundation.JSONDecoder` 后通过，不改变其持久化行为。
- 未在用户设备上主动制造崩溃；系统问题报告标题仍需真机或受控 crash 手工确认。metadata 与实际 process executable 已自动化覆盖。

## 回滚

恢复 `CFBundleName`、`EXECUTABLE_NAME`、AltTests host 和公开字符串即可。未修改 bundle ID、entitlement、协议或数据库，不需要数据迁移；回滚 executable 时必须同时恢复 AltTests 路径。
