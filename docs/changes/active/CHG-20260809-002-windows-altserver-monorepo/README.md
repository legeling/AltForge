# CHG-20260809-002：将 Windows AltServer 纳入单仓库交付

- 状态：In progress
- 日期：2026-08-09
- 类型：Feature / Build / Release

## 背景

AltForge 需要由同一仓库维护 iOS 客户端、macOS AltServer 和 Windows AltServer，用户只从本仓库的 GitHub Release 下载配套产物。Windows 实现以官方 `AltServer-Windows` 1.7.4 分支为基线，不使用额外产品分支，也不把上游仓库作为根级 submodule。

## 范围

- 把 Windows AltServer 的实际构建源码导入 `AltServer-Windows/`，保留上游来源和许可证说明。
- 将官方 source、bundle identifier 和用户可见安装名称切换为 AltForge。
- 用有界、可重复的 PowerShell 脚本获取上游原本使用的两个 gitlink 依赖、三个 libimobiledevice 源码树及 Apple mDNSResponder，并用 vcpkg 提供 cpprestsdk、OpenSSL、PCRE2 与 zlib。
- 不导入禁止再分发的 Apple corecrypto Windows binary/header；以 OpenSSL 和带 ISC 归属的 SRP-6a 实现替代。
- 提供 Windows Release ZIP 打包脚本，将 Windows 构建加入 tag-driven Release。
- 对账号会话、anisette、设备标识、证书和本地路径相关调试输出做脱敏，避免凭据或个人数据进入日志。
- 更新中英 README、需求、设计、验证、任务和原 Windows 范围 Issue。

## 非范围

- 本次不承诺代码签名、MSI 签名或 Windows 自动更新 feed。
- 本次导入保留上游 Windows 通知区域界面的英文文本；Windows 桌面端本地化不与 iOS 语言切换完成度混为一项。
- 不把 Apple Mobile Device Support、iTunes 或 iCloud 重新分发进 Release。
- 不修改 iOS/macOS 与 Windows 共用的 wire protocol。

## 追踪

`FR-018`, `FR-019` -> `DES-011` -> `TEST-018`, `TEST-019` -> `T-012`

## 复杂度与资源

依赖引导对六个固定仓库各执行一次有界 fetch，网络和磁盘成本与固定依赖快照大小线性相关，不产生无界并发或缓存。Windows 构建使用单个 Win32 Release configuration；CI job 上限 60 分钟。发布打包只遍历构建输出和依赖许可证目录，时间为 `O(files + bytes)`，额外磁盘空间约为一次未压缩输出和一个 ZIP。

## 风险与回滚

- 当前本机为 macOS，无法执行 MSBuild 或 Windows 设备安装；workflow 必须在 GitHub Windows runner 验证，真实设备仍需人工 smoke test。
- Windows 运行时仍要求 Apple 官网版 iTunes/iCloud 所带的设备与 Bonjour 服务。
- 回滚时可移除 `AltServer-Windows/`、Windows workflow job 和 Windows release artifact contract，不影响现有 iOS/macOS target 或数据。

## 收敛门禁

- [x] Windows 源码、固定依赖、许可证和品牌/source identity 完成静态检查。
- [x] PowerShell bootstrap/build/package 脚本完成 delimiter smoke；OpenSSL SRP-6a 通过独立 reference vector。
- [ ] GitHub Windows runner 完成 Release build 和 ZIP 打包。
- [x] release metadata dry run 覆盖 Windows ZIP checksum。
- [x] README、workflow、verification、tasks 和 issue 状态同步。
- [x] 无遗留进程或任务临时目录；既有工作区改动保持不变。

## 已执行验证

- `AppleSRP.cpp` 以 C++17、OpenSSL 3.6 headers 和 warnings-as-errors 完成语法检查，并与独立 Ruby 大数/SHA-256 reference vector 对比 `A`、`M1`、session key 和 `M2`。
- vcpkg JSON、MSBuild XML、workflow YAML、Ruby release metadata syntax 与本地 project file references 均通过静态验证。
- `actionlint 1.7.7` 已检查初始 CI/Release workflows；五项 Release 产物 metadata/checksum fixture 通过。前三次 hosted Windows run 依次暴露 runner vcpkg 漂移、`cpprestsdk` 被 deindex、Apple mDNSResponder Windows stub 未定义 `LOG_ERR`。manifest 现固定到 deindex 前的 `d015e31e90838a4c9dfa3eed45979bc70d9357fc`，workflow 从 manifest 读取相同 revision；mDNS compiler workaround 只作用于该子构建并恢复原环境，等待下一标签复验。
- 本机没有 PowerShell、MSBuild、Windows SDK 或设备环境，因此 PowerShell AST parser、完整 Windows link/package 与真实设备安装保留给 hosted runner/人工门禁。
