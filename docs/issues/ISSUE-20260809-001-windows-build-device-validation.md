# ISSUE-20260809-001：Windows 构建与真实设备验证待完成

- 状态：Open
- 优先级：P1
- 发现日期：2026-08-09

## 问题

Windows AltServer 已进入源码、CI 和 Release contract，但当前开发机为 macOS，不能本地执行 MSBuild，也未在 Windows 10/11 + Apple 官网版 iTunes/iCloud 环境完成真实设备安装、刷新和 Wi-Fi discovery smoke test。

首次 hosted Windows build 已运行，但 runner 系统 vcpkg checkout 无法解析 manifest 固定 baseline，构建在依赖恢复阶段失败。Release workflow 现改为在 workspace 检出并 bootstrap 完全相同的 vcpkg commit，尚待下一版本标签复验。

## 完成条件

- GitHub `windows-2025` CI 完成固定依赖恢复、Win32 Release build 和 ZIP runtime contract。
- 在脱敏 Windows 10/11 环境解压 Release ZIP，验证启动、USB 发现、Install AltForge、refresh 和同网段 discovery。
- 确认日志与 artifacts 不含 Apple ID、verification code、UDID、certificate 或 anisette data。

关联：`FR-018`、`FR-019`、`DES-011`、`TEST-018`、`TEST-019`、`T-012`、`CHG-20260809-002`。
