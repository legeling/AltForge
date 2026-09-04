# CHG-20260904-002：统一错误码与用户提示

- 状态：v2.4.2 release candidate / Windows CI pending
- 日期：2026-09-04
- 类型：Bugfix / UX / Localization / Cross-platform contract

## 背景

同一认证阶段的失败曾直接显示 `NSCocoaErrorDomain 3840` 与“格式不正确”，让用户误以为 IPA 损坏。审查进一步发现：远端 Server 可把英文错误文案固化后传回中文客户端；部分界面直接显示系统错误、进程输出或源码位置；Windows Apple API 错误码从 3013 起与 Apple 平台定义错位。

## 范围

- 审查 AltForge、AltForge Server、AltSign 与 Windows Server 的全部产品自定义错误码。
- 用户提示统一为“短标题 + 与 domain/code 对应的原因 + 可执行的下一步”；错误域、代码、底层错误与原始进程输出只保留在错误详情。
- Apple/Server provider 错误在显示前按客户端当前语言重新本地化，避免远端英文覆盖简体中文。
- 为网络、文件与数据解析等外部错误提供按系统 domain/code 分类的稳定兜底，不猜测未确认原因。
- 对齐 Apple 与 Windows 的 AltSign 0-7、Apple API 3000-3022 编码；不修改 Server Protocol schema。

## 映射

- Requirement：`FR-042`、`AC-031`
- Design：`DES-028`
- Verification：`TEST-041`
- Task：`T-041`
- 文案矩阵：[error-copy-matrix.md](error-copy-matrix.md)

## 复杂度与资源

展示适配只检查固定数量的 domain/code 分支，单次错误为 `O(1)` 时间与空间；不新增网络请求、重试、缓存、后台进程或持久数据。错误详情仍使用既有有界日志。

## 验证计划

- XCTest 枚举 AltSign、Apple API、Server、连接与既有本地错误 fixture，要求标题、原因和恢复建议均非空。
- 定向断言认证解析错误 3020 不再显示 Cocoa 3840 文案，进程输出不进入主提示。
- repository contract 检查跨平台编码、统一展示入口与英中 catalog。
- 构建 iOS AltStore 与 macOS AltServer；Windows 仅做静态编码审查，本机不冒充 MSBuild 或真实设备验证。

## 当前验证

- `ruby Scripts/test_repository_contract.rb` 通过，覆盖统一展示入口、认证 3020、进程输出隔离、简体中文 key 与 Windows/Apple code 对齐。
- 两份主 catalog 可解析；扫描到的 iOS 288 条、macOS 198 条错误相关 source string 均有非空简体中文值。
- AltStore `build-for-testing` 通过并编译 AltTests；临时 iOS 26.5 Simulator 上 `testAllKnownErrorsHaveCompleteUserFacingPresentations` 与 `testAuthenticationParsingErrorUsesAuthenticationCopy` 通过。
- AltServer Debug generic macOS build 通过；仅出现已有依赖搜索路径与 Sendable/deprecation 警告。
- `v2.4.2` 标签流水线已纳入完整错误提示与认证解析两项定向 XCTest；Windows 编译由同一 Release workflow 执行。
- `v2.4.2` 本地预发布的 9 项定向 XCTest 全部通过，包含 `testAllKnownErrorsHaveCompleteUserFacingPresentations` 与 `testAuthenticationParsingErrorUsesAuthenticationCopy`。
- Windows 未执行 MSBuild 或设备验证；本机仅完成 C++ 源码与 repository contract 静态检查。

## 回滚

恢复共享 presentation、调用点、provider 文案与编码定义即可回滚。没有数据库、协议 schema 或用户数据迁移。

## 残余风险

- Apple、设备安装服务和 Foundation 仍可能返回未登记的新错误码；此时只显示保守兜底和诊断码，不推测具体原因。
- 简体中文真实设备/每 App 语言切换仍需手工确认排版；自动化已覆盖文案存在性与语义映射。
- Windows 源码编码已静态对齐，但本机没有 Windows MSBuild 与设备安装环境。
