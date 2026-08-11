# Troubleshooting

## 简体中文

请使用 AltForge 或 AltServer 显示的错误域和数字错误码搜索 Issue：

https://github.com/legeling/AltForge/issues

提交问题前，请记录 AltForge/AltServer 版本、两端操作系统版本、连接方式、复现步骤和首个完整错误。移除 Apple ID、验证码、设备标识、证书、描述文件、Cookie、令牌、anisette 数据和私有 IPA 内容。

安装文件来自最新的已公开 GitHub Release。Draft Release 不会更新公开的 `releases/latest` 端点。

macOS Server 的下载窗口会显示已下载量、总大小、实时速度和当前线路。自动模式优先使用 release metadata 声明的自有 CDN（如已配置），随后顺序尝试 GitHub 和两个固定公共镜像；也可以从下拉菜单立即切换线路。切换会取消旧任务，不会并发下载多个 IPA。每一份非 GitHub 内容都以官方 source 或 GitHub API 发布的文件大小和 SHA-256 校验；全部候选失败时不会进入签名或设备安装。镜像只接收公开下载 URL，不接收 Apple ID、密码、设备标识或签名材料。CDN 发布配置见 [Release CDN 指南](release-cdn.md)。

macOS 钥匙串授权框要求的是当前 Mac 登录钥匙串的密码，不是 Apple ID 密码。AltForge Server 只在用户勾选“记住密码”且 Apple 认证成功后，把账号与可选密码写入本机 `ThisDeviceOnly` Keychain；不会写入 App bundle、UserDefaults 或普通文件。认证窗口一次读取完整的有界账号 archive，切换历史账号不会再次读取。源码构建和当前未 Developer ID 签名的发行包在二进制变化后仍可能需要一次新的系统授权；“允许”只授权本次访问，“始终允许”只适用于 macOS 当前认可的应用身份。稳定的跨版本身份仍依赖 Developer ID 签名与 notarization。

## English

Use the error domain and numeric code shown by AltForge or AltServer when searching the issue tracker:

https://github.com/legeling/AltForge/issues

Before filing a report, record the AltForge/AltServer version, operating systems, connection type, reproduction steps, and the first complete error. Remove Apple IDs, verification codes, device identifiers, certificates, provisioning profiles, cookies, tokens, anisette data, and private IPA contents.

Installation downloads come from the latest published GitHub Release. Draft releases do not update the public `releases/latest` endpoint.

The macOS download window shows transferred bytes, total size, live speed, and the active source. Automatic mode prefers a repository-configured CDN when present, then tries GitHub and two fixed public mirrors in sequence; the source menu can restart the single active task on another route immediately. Every non-GitHub response is checked against the size and SHA-256 from the official source or GitHub API, and signing does not begin if validation fails. Mirrors receive only the public URL, never Apple IDs, passwords, device identifiers, or signing material. See the [Release CDN guide](release-cdn.md) for publishing requirements.

The macOS Keychain prompt asks for the current Mac login-keychain password, not the Apple ID password. AltForge Server writes an account and optional password to this Mac's `ThisDeviceOnly` Keychain only after the user enables Remember Password and Apple authentication succeeds; it never uses the app bundle, UserDefaults, or a regular file. The authentication window reads its bounded account archive once, so switching saved accounts does not read Keychain again. Source builds and releases without a stable Developer ID identity may still require one new authorization after the binary changes: Allow grants one access, while Always Allow applies only to the app identity macOS currently recognizes. Stable cross-version identity still requires Developer ID signing and notarization.
