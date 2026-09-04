# CHG-20260904-003：macOS 检查更新直接下载并打开安装器

- 状态：Released in v2.4.3 / manual update UI pending
- 日期：2026-09-04
- 类型：Feature / macOS / Update UX / Security

## 背景

现有 AltForge Server 能识别新版本，但弹窗主操作只有“打开发布页面”，用户仍需在浏览器中寻找 DMG、下载并手动打开。该流程把本可由客户端可靠完成的步骤推给用户，也没有在下载前验证 Release asset 完整性。

## 范围

- latest metadata 同时读取版本、Release 页面和 macOS DMG asset 的名称、URL、size 与 digest。
- 更新可用弹窗提供“下载更新”，随后显示有界原生进度窗口和取消操作。
- 只下载当前 tag 下的本仓 GitHub DMG，并在落盘前校验 size 与 SHA-256。
- 校验成功后保存到用户“下载”文件夹并自动打开 DMG；打不开时允许在访达定位。
- 检查、下载、失败重试和兜底入口提供英文与简体中文。

## 非范围

- 不静默覆盖或删除 `/Applications/AltForge Server.app`，不在运行中自我替换。
- 不把 ad-hoc 签名描述为 Developer ID/notarization，也不绕过 Gatekeeper。
- 不新增 Sparkle feed、更新签名密钥、提权 helper、后台自动轮询或 Windows 自动更新。

## 映射

- Requirement：`FR-043`、`AC-032`
- Design：`DES-029`
- Verification：`TEST-042`
- Task：`T-042`

## 复杂度与资源

一次用户触发最多发出一个 metadata 请求和一个 DMG 下载。下载上限 512 MiB，超时分别为 45/600 秒；SHA-256 以 1 MiB block 流式计算，时间为 `O(bytes)`、额外内存为 `O(1)`。同名冲突最多检查 100 个候选文件。取消、失败、完成或 App 退出都会结束 URLSession；成功文件作为用户请求的安装器保留在“下载”文件夹。

## 验证计划

- repository contract 检查固定 host/path、size/digest、流式 SHA-256、超时、单任务、取消、Downloads 和自动打开边界。
- 解析 string catalog 与 PBX project，构建 AltServer Debug/Release。
- 对公开 latest metadata 和 DMG 执行不落凭据的 size/digest/range probe。
- 使用临时低版本构建手工覆盖下载进度、取消、重复点击、校验失败、Downloads 重名和自动打开 DMG；验证结束后清理本轮文件与挂载。

## 当前验证

- `ruby Scripts/test_repository_contract.rb`、version/release metadata contracts、Swift frontend parse、PBX/XML catalog parse 与 root/submodule `git diff --check` 通过。
- Xcode 26.6 下 AltServer Release generic macOS build 通过；构建产物包含直接下载按钮、固定 DMG asset 和进度窗口文案，仅出现已有的依赖搜索路径、Sendable、通知 API 与 script phase 警告。
- 受控公开网络 probe 读取 latest metadata 并下载 `v2.4.2` DMG；实测 `8,780,364` bytes，SHA-256 `7d19efaee18a66ac3ea4991afaad98ec2e71005eb7d91273f808b44a52424fd1` 与 GitHub API 完全一致，临时文件已删除。
- iOS、macOS 与 Windows 产品版本已统一进入 `2.4.3`，由标签流水线构建同一 commit 的三平台产物。
- 版本同步后再次完成 AltServer Release generic macOS build；产物为 `2.4.3 (1000)` 并包含直接下载、固定 DMG 和进度窗口文案。
- GitHub Actions run `33863304381` 的 Apple、Windows 与 publish jobs 通过；公开 `v2.4.3 (21)` 的九项资产通过 checksum，DMG 内正式二进制及简体中文资源包含更新闭环，latest API/source/下载端点回读通过。
- 未启动或操作 GUI，低版本弹窗、进度、取消、重名复用和自动挂载仍需手工矩阵；不能仅凭 build 与网络 probe 声称界面闭环已验收。

## 回滚

恢复 AppDelegate 中只比较 tag 并打开 Release 页面，移除 `ServerUpdateController` 及新增文案即可。没有数据库、协议、偏好或用户数据迁移；已下载 DMG 是用户可见文件，不由回滚静默删除。

## 残余风险

- 当前 DMG 没有 Developer ID/notarization，自动打开后仍需用户按系统安装界面完成替换。
- 没有 GUI 授权时只能完成静态、构建和网络验证，不能把自动挂载窗口声称为已人工验收。
