# CHG-20260810-004 macOS 可见安装进度与可靠 Release 下载

- 状态：In progress
- 日期：2026-08-10
- 类型：Bugfix / UX / Network / Security

## 背景

macOS AltForge Server 在 Apple ID 认证成功后关闭账号窗口，但下载、签名和设备安装期间没有持续可见状态。GitHub `release-assets.githubusercontent.com` 超时会在 IPA 尚未下载时直接进入最终错误，用户容易误以为手机安装阶段失败。状态菜单重复点击同一设备也没有桌面流程级去重。

复现错误为 `NSURLErrorDomain -1001`，底层失败发生在本仓库 `v2.4.0/AltForge.ipa` 的 GitHub Release asset 下载；发布资产存在且 metadata 可读取，问题位于大文件传输链路而非 Apple 认证或设备服务。

## 范围

- Apple ID 成功后显示团队、设备、证书、下载、签名和安装阶段。
- 下载使用 `URLSessionDownloadDelegate` 的实际写入字节，底层设备写入使用真实 `NSProgress` 百分比；UI 更新最多每 0.1 秒一次并保证完成样本。
- 进度条使用对称的全宽布局；下载显示已下载量、总大小、平滑实时速度、当前线路和手动线路选择。
- 每个 device identifier 同时只允许一条安装链路；重复触发聚焦现有窗口。
- GitHub 直连失败后有限回退两个 HTTPS Release 反向代理。
- Release metadata 可声明最多四个自有 HTTPS CDN URL；自动模式优先 CDN，用户切换线路时取消旧 task 并以 generation 隔离迟到回调。
- 固定公共镜像仅代理本仓库 tag-fixed Release URL；仓库配置 CDN URL 只能来自官方 source metadata，二者均以 source/GitHub API 的 asset size 与 SHA-256 流式校验。
- 失败和取消立即释放设备 activity；成功立即释放底层安装资源，并在用户关闭完成窗口后释放用于持有该窗口的 UI activity。下载临时文件仍按单任务生命周期清理。
- 设备安装以 installation_proxy 的 `Status == Complete` 作为成功终态，而不是依赖最终响应是否省略百分比；成功后显示简洁的完成状态，同时提供明确的本地化“关闭”按钮和原生标题栏关闭按钮，并等待用户主动关闭，不再按固定计时器消失。
- 已确认 Apple 团队类型只在账号选择器右侧显示，未知旧账号不再显示“类型待确认”。

## 追踪

| Requirement | Design | Verification | Task |
|---|---|---|---|
| `FR-031` | `DES-017` | `TEST-030` | `T-019` |

## 复杂度与资源

连接设备 activity 字典的空间上限等于当前连接设备数，查找均摊 `O(1)`。Source metadata 最多接受四个配置 CDN，再加 GitHub 和两个固定公共镜像；自动模式顺序执行，手动切换取消旧 task，不并发扇出、不无限重试。SHA-256 以 1 MiB 块扫描，单候选时间 `O(bytes)`、总时间 `O(sum(attempted bytes))`、额外内存 `O(1 MiB)`；请求 idle timeout 45 秒，总下载上限 600 秒。速度以 0.25 秒以上样本更新并做指数平滑，不创建 timer 或轮询。

下载 delegate session 与设备进度 KVO 在 completion 中失效；线路切换取消旧 session，旧 delegate 下载的临时文件也会删除。失败与取消分支立即释放窗口 activity，成功分支在用户关闭完成窗口时释放。第三方镜像只传输公开 Release 文件，不接收 Apple ID、密码、session、UDID、证书或 token。

## 验证计划

- repository contract：设备去重、对称进度布局、delegate 实际字节、installation_proxy `Complete` 终态、传输量/速度、手动切源取消、配置 CDN 上限、两个固定镜像、digest、大小/hash 校验、请求/资源 timeout。
- `plutil` 与 `xcstringstool`：project 和英文/简体中文 catalog。
- macOS AltServer Debug build：arm64/x86_64。
- 网络 smoke：GitHub API asset metadata、直连失败复现、镜像 range 和完整 SHA-256。
- 真实设备：重复点击、GitHub/CDN/公共镜像手动切换、旧回调隔离、签名、安装成功、超时、hash 不匹配、断连与再次发起。

## 当前结果与残余风险

代码和静态回归已实现；用户真机反馈确认 IPA 已安装但窗口停留在安装阶段，同时快速下载只显示 0%。根因分别是旧回调未检查 installation_proxy 明确的 `Complete` 状态，以及 `URLSessionTask.progress` KVO 没有提供可靠的中间下载字节。现已改为状态名终态和 download delegate 写入回调，并在完成状态增加明确的双语关闭按钮；repository contract、string catalog 与按钮改动后的 macOS Universal Debug build 通过。此前 macOS Universal Release build、release metadata/contract、hosted run 31453742913、checksum、Apple artifact 和 Windows archive 检查仍有效。修复后的真机完成窗口、手动线路切换和失败清理需要复测，因此保持 `In progress`。当前仓库尚未配置自有 CDN endpoint；只有设置 Actions Variable 并先上传同字节对象后，未来 release metadata 才会发布 CDN 线路。免费公共镜像没有可用性 SLA，任一候选失败时自动模式只会顺序继续，不降低完整性校验。完整 IPA、真实 Apple 账号和设备测试结果不得进入仓库。
