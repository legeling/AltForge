# 上游 Issue 范围与处置规则

## 合并原则

上游报告只有同时满足以下条件时才合并到同一个本地 Issue：

1. 由相同模块或维护责任边界处理。
2. 影响和失败阶段可以由同一组验证门禁覆盖。
3. 关闭条件、回滚策略和资源清理要求一致。
4. 合并不会掩盖独立的安全、数据完整性或兼容性风险。

标题相似但根因、所有者或完成条件不同的报告不得强行合并。单个第三方 App 的支持请求只有能复现到共享解析、签名、安装或运行路径时，才升级为 AltForge 风险。

## 处置状态

| 状态 | 数量 | 含义 | 后续动作 |
|---|---:|---|---|
| `tracked-merged` | 429 | 已合并到一个或多个本地 Issue | 按本地完成条件实施与验证 |
| `covered-by-existing-requirements` | 71 | 既有需求、设计和测试已覆盖风险 | 出现回归时关联具体 TEST/change |
| `not-currently-planned` | 52 | 产品建议尚未进入当前路线 | 需求和验收明确后再建 change |
| `out-of-scope` | 47 | 不属于当前 Classic 平台或分发模型 | 保留证据，不形成兼容承诺 |
| `insufficient-actionable-evidence` | 46 | 缺少可判断的步骤、环境或实际结果 | 信息补全后重新分类 |
| **合计** | **645** | 全部开放 Issue 均有处置 | 与审计 JSON 数量保持一致 |

## 当前产品边界

AltForge 当前维护 AltStore Classic 的 iOS/iPadOS 客户端，以及 macOS/Windows AltServer。`marketplace` 是历史分支名，不代表 release 嵌入 Marketplace extension 或 entitlement。

因此以下领域不进入当前实现计划：

- AltStore PAL、Marketplace notarized distribution 和 Patreon 商业入口
- 越狱、AltDaemon、TrollStore、SparseBox 等旁路安装环境
- Apple TV/tvOS
- Linux 或永久远程 AltServer
- Android 客户端

范围外不等于上游报告无效，只表示它不能作为当前 AltForge Classic 的交付承诺。

## 升级为本地 Issue 的条件

满足以下任一条件时，应从主题报告提升为新的或既有本地 Issue：

- 在当前最低系统或受支持平台上可以稳定复现。
- 影响共享解析、签名、认证、安装、刷新、设备连接或安全边界。
- 现有 `FR/DES/TEST/T` 无法覆盖其完成条件。
- 风险的所有者、回滚或验证矩阵与现有本地 Issue 明显不同。

升级后必须记录上游仓库、URL、最后核对日期、影响、规避方式、完成条件和验证关联；不得只粘贴外部讨论。

## 增量同步

后续同步只需获取新增、重新打开、关闭或更新时间变化的条目，但每次发布前仍应验证：

- JSON 记录数与唯一编号数一致。
- 主题报告合计数与 JSON `count` 一致。
- 所有本地映射文件存在。
- 已关闭上游 Issue 不会让尚未验证的本地风险自动变成 Resolved。
