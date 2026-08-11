# CHG-20260810-004 macOS 可见安装进度与可靠 Release 下载

- 状态：In progress
- 日期：2026-08-10
- 类型：Bugfix / UX / Network / Security

## 背景

macOS AltForge Server 在 Apple ID 认证成功后关闭账号窗口，但下载、签名和设备安装期间没有持续可见状态。GitHub `release-assets.githubusercontent.com` 超时会在 IPA 尚未下载时直接进入最终错误，用户容易误以为手机安装阶段失败。状态菜单重复点击同一设备也没有桌面流程级去重。

复现错误为 `NSURLErrorDomain -1001`，底层失败发生在本仓库 `v2.4.0/AltForge.ipa` 的 GitHub Release asset 下载；发布资产存在且 metadata 可读取，问题位于大文件传输链路而非 Apple 认证或设备服务。

## 范围

- Apple ID 成功后显示团队、设备、证书、下载、签名和安装阶段。
- 下载和底层设备写入使用真实 `NSProgress` 百分比。
- 进度条使用对称的全宽布局；下载显示已下载量、总大小、平滑实时速度、当前线路和手动线路选择。
- 每个 device identifier 同时只允许一条安装链路；重复触发聚焦现有窗口。
- GitHub 直连失败后有限回退两个 HTTPS Release 反向代理。
- Release metadata 可声明最多四个自有 HTTPS CDN URL；自动模式优先 CDN，用户切换线路时取消旧 task 并以 generation 隔离迟到回调。
- 固定公共镜像仅代理本仓库 tag-fixed Release URL；仓库配置 CDN URL 只能来自官方 source metadata，二者均以 source/GitHub API 的 asset size 与 SHA-256 流式校验。
- 成功、失败和取消均释放设备 activity；下载临时文件仍按单任务生命周期清理。
- 已确认 Apple 团队类型只在账号选择器右侧显示，未知旧账号不再显示“类型待确认”。

## 追踪

| Requirement | Design | Verification | Task |
|---|---|---|---|
| `FR-031` | `DES-017` | `TEST-030` | `T-019` |

## 复杂度与资源

连接设备 activity 字典的空间上限等于当前连接设备数，查找均摊 `O(1)`。Source metadata 最多接受四个配置 CDN，再加 GitHub 和两个固定公共镜像；自动模式顺序执行，手动切换取消旧 task，不并发扇出、不无限重试。SHA-256 以 1 MiB 块扫描，单候选时间 `O(bytes)`、总时间 `O(sum(attempted bytes))`、额外内存 `O(1 MiB)`；请求 idle timeout 45 秒，总下载上限 600 秒。速度以 0.25 秒以上样本更新并做指数平滑，不创建 timer 或轮询。

进度 KVO 在 download/device completion 中失效；窗口和 activity 在所有 completion 分支释放。第三方镜像只传输公开 Release 文件，不接收 Apple ID、密码、session、UDID、证书或 token。

## 验证计划

- repository contract：设备去重、对称进度布局、传输量/速度、手动切源取消、配置 CDN 上限、两个固定镜像、digest、大小/hash 校验、请求/资源 timeout。
- `plutil` 与 `xcstringstool`：project 和英文/简体中文 catalog。
- macOS AltServer Debug build：arm64/x86_64。
- 网络 smoke：GitHub API asset metadata、直连失败复现、镜像 range 和完整 SHA-256。
- 真实设备：重复点击、GitHub/CDN/公共镜像手动切换、旧回调隔离、签名、安装成功、超时、hash 不匹配、断连与再次发起。

## 当前结果与残余风险

代码和静态回归已实现；macOS Universal Debug build、string catalog、release metadata/contract 测试通过。Release prepare job 会递归检出 submodule，再执行需要检查 AltSign manifest 的 repository contract；首次 `v2.4.0` 重新发行尝试暴露并修复了 prepare 未检出 submodule 的 CI 缺陷。公开 `apps.json` 中原 `v2.4.0` 的 size/SHA-256 与 GitHub API 完全一致；此前 `gh-proxy.com` 完整流式下载也得到同一 SHA-256，验证过程未把 IPA 落盘。真实设备上的手动线路切换、窗口视觉检查和完整安装尚未完成，因此保持 `In progress`。当前仓库尚未配置自有 CDN endpoint；只有设置 Actions Variable 并先上传同字节对象后，未来 release metadata 才会发布 CDN 线路。免费公共镜像没有可用性 SLA，任一候选失败时自动模式只会顺序继续，不降低完整性校验。完整 IPA、真实 Apple 账号和设备测试结果不得进入仓库。
