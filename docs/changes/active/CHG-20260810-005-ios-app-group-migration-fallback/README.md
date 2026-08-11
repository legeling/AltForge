# CHG-20260810-005 iOS App Group 迁移降级修复

- 状态：In progress
- 日期：2026-08-10
- 类型：Bugfix / Data safety

## 背景

`v2.4.0` IPA 在部分免费开发者重签环境首次启动时保留了 `ALTAppGroups` 元数据，但系统没有授予对应 App Group container。客户端因此回退到应用沙盒的 `Library/Application Support`，启动迁移却只检查元数据存在，随后尝试用 `Apps` 目录替换其自身，触发 `NSCocoaErrorDomain 512` / `NSPOSIXErrorDomain 22` 并阻断启动。

## 范围

- 数据迁移必须以系统实际返回 App Group container 为前提，而不是只相信 Info.plist 元数据。
- container 不可用时继续使用既有 application sandbox，不搬移、不删除数据库或 Apps 目录，也不把迁移标记为完成。
- 迁移前再次比较标准化源/目标路径，禁止任何 self-replace。
- 不修改 provisioning、签名、App Group identifier 或安装协议。

## 追踪

| Requirement | Design | Verification | Task |
|---|---|---|---|
| `FR-032` | `DES-018` | `TEST-031` | `T-020` |

## 复杂度与资源

启动只增加一次 container URL 解析和常数次标准化 URL 比较，时间与空间复杂度均为 `O(1)`，不新增网络、线程、缓存或后台进程。迁移仍由既有 `NSFileCoordinator` 串行执行；无 container 时在任何文件写入前返回。

## 验证计划

- 用历史源码运行 repository contract，证明缺少真实 container 与 self-replace 两个保护时测试失败。
- 用当前源码运行 repository contract。
- 构建 AltStore iOS Simulator Debug target。
- 在无有效 App Group container 的 simulator/真实重签设备上验证首次启动与重试路径；真实设备不得记录 UDID、profile 或账号。

## 当前结果与残余风险

源码修复和持久静态回归已加入。历史源码按新增 contract 验证会失败，当前源码通过；AltStore iOS Simulator Debug build 成功，临时 iOS 26.5 simulator 首次启动后进程持续存活并进入主界面/系统通知授权提示，没有出现数据库迁移错误。smoke wrapper 最后的可选 simulator `log show` 查询不受支持并返回 65，不影响此前已完成的进程与截图检查；临时 simulator、DerivedData 和截图均已清理。公开的 `v2.4.0` IPA 不包含此修复，必须构建新的 patch release 后才能替换用户已下载的产物。真实免费开发者重签设备仍需复测，因此 change 保持 `In progress`。
