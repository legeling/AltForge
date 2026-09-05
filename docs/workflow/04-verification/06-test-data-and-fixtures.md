# Test Data And Fixtures

## 目录策略

- App/Source/Error XCTest fixture：优先放 `AltTests/Fixtures/`。
- AltSign 独立 archive fixture：优先放 AltSign 自己的 test target，避免 superproject 才能运行底层测试。
- 临时运行输出：使用系统 temporary directory 或 CI runner temp，不提交仓库。

## 必备 Unicode fixture

| Fixture | 内容 | 预期 |
|---|---|---|
| `unicode-display-name` | `CFBundleDisplayName=音乐` | App ID name 为合法 ASCII，display name 不变 |
| `utf8-flagged-path` | UTF-8 `音乐.png` + bit 11 | 正确解压与 round trip |
| `unicode-extra-path` | legacy raw name + valid `0x7075` | 使用 extra field path |
| `gbk-path` | raw GBK `音乐.png`，无 UTF-8 flag | 无损 fallback 为正确 path |
| `invalid-extra-crc` | Unicode Path CRC 不匹配 | 不信任 extra field |
| `zip-slip` | `../outside` | 拒绝且目录外无写入 |

## 数据生成

- Fixture generator 必须确定性输出；固定 entry 顺序、timestamp 或在 hash 说明中排除 timestamp 差异。
- Raw filename bytes 使用十六进制常量，不依赖 shell locale。
- 每个 binary fixture 附 SHA-256 与生成脚本版本。

## 敏感数据

GSA 传输 fixture 位于 `AltTests.swift`：合成 plist、HTML 和 URLError 通过每个 ephemeral session 专用的 URLProtocol 返回，未注册请求直接失败，不访问 Apple。唯一请求标识隔离场景；注入单调时钟与调度器验证 1/2/4/8 秒退避、60 秒预算及剩余请求超时，无须真实等待或账号。每次尝试必须收到 session invalidation，测试结束注销 handler。

禁止把以下内容放入 fixture：真实 Apple ID、密码、2FA code、UDID、device name、certificate、private key、mobileprovision、Cookie、anisette data、Patreon token。

需要 profile/schema 测试时使用自签名或完全虚构且不可用于生产的最小数据，并在文件头说明来源。

## 清理

- 每个测试拥有唯一临时目录。
- `tearDown`/`defer` 删除文件、关闭 archive/connection、恢复 global provider。
- 测试失败也必须执行清理；清理失败作为独立断言报告。
