# ISSUE-20260811-001：macOS 安装进度真机回归待验证

- 状态：Open
- 优先级：P0
- 发现日期：2026-08-11
- 关联：`FR-031`、`DES-017`、`TEST-030`、`T-019`、`CHG-20260810-004`

## 问题

真机反馈显示两条已修复但尚未在修复后复测的路径：快速 Release 下载只停留在 0% 后跳到下一阶段；手机已经出现 AltForge 后，macOS 窗口仍停留在“正在安装”。代码根因分别是依赖不可靠的 `URLSessionTask.progress` KVO，以及未以 installation_proxy 的 `Status == Complete` 作为成功终态。

## 当前防护

- 下载改用 `URLSessionDownloadDelegate.didWriteData` 的实际写入字节，UI 更新间隔下限为 0.1 秒并保证完成样本。
- 线路切换以 generation 丢弃迟到回调，并清理旧 delegate session 与临时文件。
- 设备回调显式解析 `Status`；`Complete` 无论是否同时带 100% 都完成事务、填满进度并释放 completion/activity。
- repository contract 固定以上结构，macOS Universal Debug build 已通过。

## 关闭条件

使用脱敏真实设备完成以下复测且不保存账号、UDID、设备名或 IPA 内容：

1. 正常网络下载至少出现一个 0% 与 100% 之间的实际进度样本；极快下载至少正确到达 100%，不得长期停留在 0%。
2. installation_proxy 返回完成后窗口持续显示“安装完成”，用户可用原生关闭按钮关闭；关闭后允许同一设备重新发起安装。
3. 手动切换一次线路和制造一次失败，确认旧回调不覆盖新线路，临时文件与设备 activity 均释放。

完成条件满足后，把结果写回 `TEST-030` 与 `CHG-20260810-004`，再将本 issue 标记为 Resolved。
