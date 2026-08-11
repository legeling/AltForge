# CHG-20260811-005：收敛 macOS DMG Finder 布局

- 状态：Completed
- 日期：2026-08-11
- 类型：Bugfix / Packaging / UX

## 背景

现有 DMG 直接从 staging 目录压缩，未包含 Finder 窗口元数据。用户打开映像时，Finder 会沿用本机最近窗口尺寸，导致只有两个安装项目却出现接近全屏的大窗口和大量空白。

## 范围

- 在任务专属可写中间映像中生成 `.DS_Store`，固定首次打开窗口为 520 × 300 pt。
- 使用 88 pt 图标并显式放置 `AltForge Server.app` 与 `Applications` 快捷方式。
- 隐藏工具栏、状态栏和路径栏，并请求 Finder 隐藏 App 的 `.app` 扩展名；用户启用“显示所有文件扩展名”时仍尊重其全局偏好。
- Finder 元数据未写入时打包失败，不发布尺寸不可预测的 DMG。
- 配置完成后推出可写映像，再转换为现有 UDZO 压缩发布格式并执行 `hdiutil verify`。

## 非范围

- 添加营销背景图、许可协议、自动安装或覆盖 `/Applications` 中的现有应用。
- 改变 Developer ID、notarization 或现有签名策略。

## 追踪

- Requirement：`FR-025`、`AC-016`
- Design：`DES-013`
- Verification：`TEST-025`、Regression Suite G
- Task：`T-015`

## 复杂度与资源

打包仍按 App bundle 总字节数执行一次 staging 复制、一次可写映像创建和一次压缩转换，时间与磁盘复杂度均为 `O(app bytes)`。Finder 配置只有两个固定项目，为 `O(1)`；AppleScript 超时由 Finder IPC 控制，不启动常驻轮询。脚本在挂载前拒绝同名现有卷，避免修改用户已有挂载；trap 在成功、失败和中断时只推出捕获到的本任务设备并清理中间映像。

## 回滚

恢复为直接从 staging 目录创建 UDZO 映像即可；不涉及已安装 App、用户数据或发布 metadata 迁移。已发布 DMG 不应被同名静默覆盖。

## 验证计划

- `bash -n Scripts/package_macos_dmg.sh` 与 repository contract。
- 使用当前 Universal Debug App 生成临时 DMG，验证 image、签名、bundle 和 Applications symlink。
- 挂载并检查 `.DS_Store`，由 Finder 截图确认首次窗口约 520 × 300 pt、图标位置稳定且无大块空白。
- 推出任务挂载并删除临时 DMG，不影响用户已有挂载。

## 当前结果与残余风险

使用已安装的 Universal `AltForge Server.app` 完成 deep ad-hoc staging 签名、UDRW 配置、UDZO 转换、`hdiutil verify`、只读挂载与 strict signature 验证；挂载内容包含 `.DS_Store`、App 和 Applications symlink，主 executable 同时包含 `arm64` 与 `x86_64`。Finder 实测 bounds 为 `{120, 120, 640, 420}`，内容区域 520 × 300 pt；两个图标位置分别为 `{145, 135}` 与 `{375, 135}`，工具栏、状态栏和路径栏均为隐藏状态。用户于 2026-08-11 完成第二轮截图视觉确认，确认窗口比例、留白和图标排布正常；截图中的 `.app` 后缀来自当前 Finder 的全局扩展名显示偏好，不影响安装。

若 GitHub hosted runner 的 Finder 会话不可用，脚本将明确失败而不是生成无布局的 Release。不同 macOS 版本可能对标题栏高度和阴影有轻微差异；新布局的真实 tag artifact 仍需在下一次发布时按 `TEST-025` 复验。
