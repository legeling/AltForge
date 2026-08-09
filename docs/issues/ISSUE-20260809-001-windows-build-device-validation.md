# ISSUE-20260809-001：Windows 构建与真实设备验证待完成

- 状态：Open
- 优先级：P1
- 发现日期：2026-08-09

## 问题

Windows AltServer 已进入源码、CI 和 Release contract，但当前开发机为 macOS，不能本地执行 MSBuild，也未在 Windows 10/11 + Apple 官网版 iTunes/iCloud 环境完成真实设备安装、刷新和 Wi-Fi discovery smoke test。

前三次 hosted Windows build 暴露并逐步收敛了可复现性问题：第一次使用 runner 系统 vcpkg，无法解析固定 baseline；`v2.4.0` 第一次标签构建选用的 2026-08 vcpkg revision 已移除 `cpprestsdk`；第二次标签构建完成固定依赖恢复后，Apple `mDNSResponder-2881.0.25` 的 Windows client stub 因使用未定义的 `LOG_ERR` 而编译失败。manifest 已固定到 cpprestsdk deindex 前的 `d015e31e90838a4c9dfa3eed45979bc70d9357fc`，workflow 从 manifest 读取相同 revision；mDNS build 仅在该子构建进程中定义 `LOG_ERR=kDebugLevelError` 并恢复原 `CL` 环境，尚待标签构建复验。

## 完成条件

- GitHub `windows-2025` CI 完成固定依赖恢复、Win32 Release build 和 ZIP runtime contract。
- 在脱敏 Windows 10/11 环境解压 Release ZIP，验证启动、USB 发现、Install AltForge、refresh 和同网段 discovery。
- 确认日志与 artifacts 不含 Apple ID、verification code、UDID、certificate 或 anisette data。

关联：`FR-018`、`FR-019`、`DES-011`、`TEST-018`、`TEST-019`、`T-012`、`CHG-20260809-002`。
