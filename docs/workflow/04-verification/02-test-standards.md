# Test Standards

## 命名与结构

- XCTest 使用 `test<Behavior>_<Condition>_<Expected>` 或项目已有可读命名。
- 每个测试聚焦一个行为；多个输入等价类可使用表驱动循环。
- Bug 回归测试在注释或 change 记录中关联 `TEST-*` 和 Issue，不依赖外部链接才能理解。

## 断言

- 不只断言“无错误”；同时断言输出 path、metadata、flags、状态写入和副作用。
- Error 测试断言 domain、code、failure reason 和 recovery suggestion。
- Archive 测试断言目标目录外没有写入，file handle 可再次打开/删除。
- Release 测试断言 JSON schema 关键字段、文件大小与 SHA-256。

## 隔离

- 使用测试创建的唯一临时目录；`defer`/tearDown 中只清理该目录。
- 不读写真实用户 Keychain、Core Data store、Apple ID 或 app group。
- 外部网络默认替换为 fixture 或 URLProtocol；真实 Apple/设备调用只能在明确的 manual suite。
- 测试不得依赖执行顺序或共享 mutable singleton 状态；必须恢复 NSError provider 等全局 hook。

## Fixture

- 使用最小自制 bundle/archive，不提交第三方完整 IPA。
- 二进制 fixture 提供生成方式和 hash。
- Encoding fixture 同时记录 raw bytes 与预期 Unicode，不依赖当前文件系统自动编码。

## 失败报告

- 报告实际命令、target、destination、Xcode 版本和首个根因。
- 不粘贴含 Apple ID、UDID、token、Cookie 或 certificate 的完整日志。
- 环境/依赖失败与产品测试失败分开记录。
