# Security And Privacy Rules

## 敏感数据

- Apple ID、密码、2FA code、session、Cookie、anisette data、UDID、certificate、private key、provisioning profile 和 signing token 不得进入代码、日志、fixture、文档或 commit。
- 错误和诊断信息仅保留定位所需字段；设备名称、路径、账户、bundle ID 或服务响应可能识别用户时必须脱敏。
- Keychain 与系统凭据存储沿用现有封装，不创建明文 fallback，不在调试构建中绕过访问控制。

## 不可信输入

- IPA、ZIP、plist、source JSON、URL、server response、XPC payload 和环境变量在验证前均视为不可信。
- Archive extraction 必须验证 path traversal、absolute path、symlink、filename encoding、条目数量、单项/总大小和失败清理。
- 网络 URL 必须验证 scheme、host/redirect 策略和响应大小；解析错误应可诊断但不能泄露响应中的秘密。
- XPC 与本地服务调用验证调用方、参数类型、长度和状态，不以“本机通信”为信任依据。

## 签名与发布

- 不自行实现密码学；使用平台和现有成熟库。
- Entitlement、application identifier、team、certificate 和 profile 变化属于高风险，需要最小权限、兼容检查和真实设备验证计划。
- Release artifact 生成 checksum；签名/公证状态必须准确披露，不把未签名或未公证产物描述成生产签名版本。
- 安全修复的公开说明避免提前暴露可利用细节；必要时先在私有渠道协调并保留审计记录。
