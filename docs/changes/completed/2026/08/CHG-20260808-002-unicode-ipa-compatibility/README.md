# CHG-20260808-002：Unicode IPA 安装兼容

- 状态：Completed with residual test gap
- 日期：2026-08-08
- 类型：Bugfix
- AltForge commit：`32096f9f`
- AltSign commit：`4b4a585a`

## 背景

中文 `CFBundleDisplayName`、IPA 内部中文资源路径及无正确 UTF-8 标志的 legacy ZIP 会导致 App ID 注册或 archive extraction 失败，而其他 sideload 工具可以安装同一包。

## 实际实现

- App ID description 仅保留 ASCII 字母、数字和普通空格；trim 后为空使用 `App`。
- ZIP reader 支持 UTF-8 flag、Info-ZIP Unicode Path extra field 与常见东亚 legacy encoding fallback。
- 移除固定 512-byte filename buffer，writer 设置 UTF-8 flag。
- 拒绝 absolute/`..` archive path，修复失败路径 file handle cleanup。
- AltSign fork 与 superproject gitlink 已推送。

## 追踪

`FR-004`, `FR-005` -> `DES-005` -> `TEST-003`, `TEST-005`-`TEST-007` -> `T-001`

## 实际验证

- macOS/iOS SDK 对修改源文件执行严格 syntax check。
- 临时 harness 验证 raw GBK `音乐.png` extraction 与 UTF-8 ZIP round trip。
- 完整 workspace build 和真实设备安装未在该 change 中完成。

## 残余风险

持久自动化测试仍缺失，见 `ISSUE-20260808-001`。
