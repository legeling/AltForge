# Key Behaviors

## 安装 AltForge

1. AltServer 发现已连接设备并读取设备类型、UDID 和系统版本。
2. 用户选择 Install AltForge，AltServer 获取官方 source 并选择与设备兼容的版本。
3. AltServer 获取 anisette data、认证 Apple ID、选择 team、注册 device、获取 certificate。
4. IPA 被下载到临时位置并解压。
5. AltServer 为主应用和 extensions 注册 App IDs、配置 capabilities、获取 profiles。
6. AltSign 重签 app，设备服务执行安装。
7. 成功或失败后释放 connection、archive handle 与临时文件。

规则：最低系统不满足时可以提示最后一个兼容版本；不能静默安装不兼容版本。

## 从 AltForge 安装应用

1. 用户从 source 或 Files 选择 IPA。
2. AltForge 验证 app metadata、权限、来源与系统兼容性。
3. `AppManager` 创建 operation graph，下载/读取并准备 app。
4. `FindServerOperation` 发现 AltServer，`SendAppOperation` 发送请求和 payload。
5. AltServer 完成 provisioning、resign、install，并返回结构化结果。
6. 客户端更新 Core Data、active app 状态与 UI。

部分失败规则：在设备安装确认前，不把应用写成成功安装；错误应保留底层原因。

## Unicode 名称

- `CFBundleDisplayName` 是用户可见名称，可以为中文或其他 Unicode。
- Apple App ID description 是独立字段，必须转换为 Apple 接受的 ASCII；纯 Unicode 名称使用 `App` fallback。
- IPA entry 如果有 UTF-8 flag，按 UTF-8 解码。
- 如果存在有效的 Info-ZIP Unicode Path extra field，校验 filename CRC 后使用其 UTF-8 path。
- 旧式无标志 entry 只接受无损编码检测结果。
- 输出 IPA entry 一律标记 UTF-8。
- 绝对路径或包含 `..` 的 archive path 必须拒绝。

## Refresh

1. AltForge 读取 active installed apps 与 expiration date。
2. 用户触发或 background task 选择需要刷新的 app。
3. 多个 app 可组成 refresh group，但网络和 signing fan-out 必须有界。
4. 每个 app 重新获取 profile、签名并安装。
5. `RefreshAttempt` 记录结果；失败不应删除上一份可用应用状态。

## Source

- Source URL 规范化时忽略 scheme、query、fragment、leading `www`、大小写与重复 slash 的差异。
- 非默认 port 与有效 path 属于 source identity。
- 解析成功后才写入 Core Data；权限或 schema 错误必须可见。
- 官方 source 的 latest download URL 是稳定入口，具体版本信息来自生成的 `apps.json`。

## 错误传输

- 本地 error 保留 domain 和 code。
- `ALTLocalizedError` 提供 failure、reason 和 recovery suggestion。
- `CodableError` 只编码允许的数据类型；unsupported userInfo 不跨进程传输。
- 客户端收到错误后优先显示可操作的恢复建议，详细诊断进入 error log。

## Release

1. 维护者创建 `v<semver>` tag。
2. workflow 在有限 timeout 下 resolve dependencies、构建 iOS/macOS。
3. iOS `.app` 以 `Payload/AltStore.app` 结构打包为 `AltForge.ipa`。
4. Ruby 脚本读取实际文件大小和 hash，生成 `apps.json` 与 `SHA256SUMS.txt`。
5. 只有全部步骤成功后创建 GitHub Release。

## 状态与清理

- 下载 task 完成后删除 URLSession 临时文件。
- 解压/重签使用单次任务临时目录；成功和失败路径均需清理。
- CI 使用 runner temporary directory 和 bounded job timeout。
- 只清理当前任务创建的资源，不终止用户已有 AltServer、VPN、代理或设备服务。
