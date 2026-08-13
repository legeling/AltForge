# ISSUE-20260811-004：AltJIT 依赖与新系统运行时兼容缺少验证

- 状态：Open
- 优先级：P1
- 发现日期：2026-08-11
- 关联：`FR-012`、`DES-003`、`TEST-014`、`T-009`

## 问题

当前 JIT 覆盖在 verification map 中仍为 Unknown，缺少 macOS、iOS/iPadOS、Developer Disk、隧道方式和目标进程选择的兼容矩阵。AltJIT 调用链依赖 `pymobiledevice3` 与系统运行时行为；依赖命令、TLS 能力、RemoteXPC 端口或进程枚举变化时，用户只能看到通用执行失败。

## 上游证据

最后核对：2026-08-11。

- [AltStore #1358](https://github.com/altstoreio/AltStore/issues/1358) 为 Open，`pymobiledevice3` 缺少 `mounter` 命令，最后更新 2026-07-09。
- [AltStore #1711](https://github.com/altstoreio/AltStore/issues/1711) 为 Open，报告 iPadOS 26.x 下系统 Python、LibreSSL、隧道命令和动态 RSD 端口造成多种失败，创建于 2026-02-15。
- [AltStore #1710](https://github.com/altstoreio/AltStore/issues/1710) 为 Open，报告同名多进程时选择不可 attach 的 PID，创建于 2026-02-15。

该主题的 55 条开放报告、逐条处置与完整本地映射见 [`upstream/topics/05-altjit-runtime.md`](upstream/topics/05-altjit-runtime.md)。

## 风险

- 相同 AltForge Server build 在不同 Mac 上因系统 Python 环境而产生不可复现结果。
- 新系统可发现设备但无法挂载 Developer Disk、建立隧道或 attach 正确进程。
- 无界重试、错误 PID 或失效端口可能留下进程、隧道和调试会话。

## 临时规避

失败时返回具体阶段、受控命令退出码和可操作前置条件，不自动安装或升级用户的全局 Python 环境，不终止非本任务创建的进程，也不要求关闭 VPN 或系统安全机制。

## 关闭条件

1. 建立 `TEST-014` 矩阵，至少覆盖支持的最低 macOS、当前 macOS、iOS/iPadOS 17.4 与当前主版本、USB/Wi-Fi 和 Developer Disk 状态。
2. 固定并验证 `pymobiledevice3`/Python 运行时来源，或在启动前验证所需命令与 TLS 能力；不得隐式依赖用户任意全局环境。
3. 动态发现 RemoteXPC/RSD 端口，并对隧道建立、超时、有限重试和清理进行自动或受控 fixture 验证。
4. 多 PID 场景使用有界候选选择，失败不得 attach 任意无关进程；所有 task-owned debugserver、隧道和子进程均被回收。
5. 用脱敏真机完成一次成功和至少三类可控失败，再把覆盖结果写回 verification map 与 `T-009`。

## 回滚

JIT 兼容修复必须保持在 `AltJIT`/pymobiledevice3 适配层，不改变安装签名协议。若依赖更新造成回归，回退到已固定并验证的工具版本，同时保留明确的系统不支持错误。
