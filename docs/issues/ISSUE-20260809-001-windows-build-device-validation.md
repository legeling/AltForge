# ISSUE-20260809-001：Windows 构建与真实设备验证待完成

- 状态：Open
- 优先级：P1
- 发现日期：2026-08-09

## 问题

Windows AltServer 已进入源码、CI 和 Release contract，但当前开发机为 macOS，不能本地执行 MSBuild，也未在 Windows 10/11 + Apple 官网版 iTunes/iCloud 环境完成真实设备安装、刷新和 Wi-Fi discovery smoke test。

六次 hosted Windows build 暴露并逐步收敛了可复现性问题：第一次使用 runner 系统 vcpkg；`v2.4.0` 前五次标签构建依次发现所选 vcpkg revision 已移除 `cpprestsdk`、Apple `mDNSResponder-2881.0.25` Windows stub 未定义 `LOG_ERR`、完整 solution 缺少 `dirent` include/OpenSSL compatibility opt-in/`NOMINMAX`、两处连接代码仍直接依赖 Windows `min` macro，以及 vcpkg 中 zlib 1.3.2 已将 Windows import/runtime 名改为 `z.lib`/`z.dll`。manifest、compiler workarounds 和 zlib 产物契约已最小化修正，尚待标签构建复验。

## 完成条件

- GitHub `windows-2025` CI 完成固定依赖恢复、Win32 Release build 和 ZIP runtime contract。
- 在脱敏 Windows 10/11 环境解压 Release ZIP，验证启动、USB 发现、Install AltForge、refresh 和同网段 discovery。
- 确认日志与 artifacts 不含 Apple ID、verification code、UDID、certificate 或 anisette data。

关联：`FR-018`、`FR-019`、`DES-011`、`TEST-018`、`TEST-019`、`T-012`、`CHG-20260809-002`。
