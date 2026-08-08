# Coding Standards

## 基本原则

- 优先沿用目标目录已有的 Swift/Objective-C/C/C++ 风格、命名、错误类型、日志和测试设施。
- 修改应落在真实所有者模块：UI 在 `AltStore/`，服务端安装在 `AltServer/`，领域与持久化在 `AltStoreCore/`，跨进程契约在 `Shared/`，签名与 archive 在 `Dependencies/AltSign`。
- 不为单点修复增加大依赖、全局状态或跨层捷径。新增抽象必须消除真实重复或隔离明确边界。
- 公共 API、XPC contract、Core Data schema、entitlement 和 signing 行为变化必须评估兼容与迁移。

## Swift 与 Objective-C

- 使用项目支持的 language mode 和 API availability；不要把 Xcode 工具链版本误写成 Swift language mode。
- 新代码避免无依据的 force unwrap、force cast 和 `try!`。不可恢复的不变量必须通过前置验证或清晰断言表达。
- 错误保留底层原因和用户可行动信息；不要仅记录后吞掉，也不要在 UI 暴露凭据、路径或服务响应全文。
- 异步 completion、Task、Operation、XPC reply 和 file handle 必须在成功与失败路径都完成一次并释放资源。
- 用户可见字符串进入既有 string catalog，不在业务代码拼接不可本地化句子。

## 数据与性能

- 下载、IPA/ZIP、日志和设备响应按不可信且可能很大处理；优先流式或有界处理，避免无意义的整包复制和重复解析。
- 循环内网络、磁盘、Keychain、Core Data fetch 和序列化需要检查是否可批处理、缓存或移出循环。
- 缓存必须有容量和失效边界；并发和重试必须有上限、超时与明确失败行为。
- 性能相关调整需记录输入规模和测量结果；没有证据时优先简单正确的实现。

## 可维护性

- 注释解释不直观的约束和原因，不复述代码。
- 修改生成文件前确认其源文件和生成方式；项目依赖的 `.pbxproj`、string catalog 等应与源变更保持一致。
- 无关格式化、批量重命名和历史 `AltStore`/`ALT` 符号清理不与功能修改混合。
- 测试与文档要求分别见 [测试标准](testing-standards.md) 和 [文档同步规则](doc-sync-rules.md)。
