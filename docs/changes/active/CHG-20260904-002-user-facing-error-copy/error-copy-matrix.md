# Error Copy Matrix

## 展示规则

- 主提示只包含用户能理解的标题、实际失败原因和下一步。
- domain、code、源码位置、底层错误、原始进程输出只进入“更多详情”和诊断报告。
- 已知自定义错误按 domain/code 重新本地化；未知系统错误保留真实系统原因，并使用不猜测原因的恢复建议。
- 取消操作不是失败，不主动弹出错误。

## AltSign 与 Apple API

| Domain / code | 简体中文原因 | 下一步 |
|---|---|---|
| `AltSign.Error 0` | 无法确定 App 签名失败的原因 | 更新客户端与 Server 后重试 |
| `AltSign.Error 1` | App 无效 | 重新取得完整 IPA |
| `AltSign.Error 2` | IPA 不含 App 包 | 重新取得完整 IPA |
| `AltSign.Error 3` | App 缺少 Info.plist | 重新取得完整 IPA |
| `AltSign.Error 4` | 找不到匹配的描述文件 | 重新登录以创建描述文件 |
| `AltSign.Error 5` | 找不到 Apple 根签名证书 | 更新系统受信任证书 |
| `AltSign.Error 6` | 签名证书无效或过期 | 重新登录以创建签名资料 |
| `AltSign.Error 7` | 描述文件无效或过期 | 重新登录以创建签名资料 |
| `AppleDeveloperError 3000` | Apple 开发者服务返回未知错误 | 更新后重试 |
| `3001` | 请求参数无效 | 更新后重试 |
| `3002` | Apple ID 或密码错误 | 检查账号和密码 |
| `3003` | 需要 App 专用密码 | 在 Apple ID 网站创建后登录 |
| `3004` | 没有可用开发者团队 | 检查开发者服务资格与协议 |
| `3005` | UDID 无效 | 重连、解锁并信任电脑 |
| `3006` | 设备已注册 | 重新尝试安装 |
| `3007` | 证书请求无效 | 重新登录并创建证书 |
| `3008` | 请求的证书不存在 | 重新登录并创建证书 |
| `3009` | App 名称含无效字符 | 使用完整、未经修改的 IPA |
| `3010` | Bundle ID 无效 | 使用完整、未经修改的 IPA |
| `3011` | Bundle ID 已注册 | 使用可信 IPA，必要时更换账号 |
| `3012` | App ID 不存在 | 重新安装以重建记录 |
| `3013` | 七天内 App ID 注册数已达上限 | 等待到期或使用付费账号 |
| `3014` | App Group 无效 | 重新安装以重建记录 |
| `3015` | App Group 不存在 | 重新安装以重建记录 |
| `3016` | 描述文件标识符无效 | 重新安装以重建记录 |
| `3017` | 描述文件不存在 | 重新安装以重建记录 |
| `3018` | 需要双重认证 | 输入最新六位验证码 |
| `3019` | 验证码错误 | 重新登录并获取新验证码 |
| `3020` | Apple 认证响应无法读取 | 检查网络/时间并更新 Server |
| `3021` | Mac 的 Apple 认证数据缺失或无效 | 检查时间并更新 Server |
| `3022` | Apple 开发者响应无法读取 | 检查网络并更新两端 |

## Server 与设备

| Domain / codes | 原因范围 | 下一步 |
|---|---|---|
| `AltServer.ServerError 0` | Server 未返回可识别原因 | 重试并携带诊断码反馈 |
| `1-6` | 连接、设备、请求或响应失败 | 信任/解锁/重连；协议错误更新两端 |
| `7-8` | IPA 无效或设备安装失败 | 重新取得 IPA；查看设备安装详情 |
| `9` | 免费账号活跃 App 达上限 | 停用一个侧载 App |
| `10` | 系统版本不支持 | 更新系统或选择兼容版本 |
| `11-12` | 两端不支持请求/响应 | 更新到匹配版本 |
| `13` | Apple 认证数据无效 | 检查时间并更新 Server |
| `14` | 旧邮件插件不可用 | 启动并启用插件 |
| `15` | 找不到描述文件 | 重新登录创建描述文件 |
| `16` | 设备无法移除 App | 解锁并在设备上移除 |
| `100` | 目标 App 未在前台运行 | 打开目标 App 后重试 |
| `101` | 开发者磁盘不兼容 | 更新 Server 下载匹配版本 |
| `AltServer.ConnectionError 0-6` | 未知、锁定、协议、usbmuxd、SSL 或超时 | 分别重连、解锁、更新两端或确认信任 |

## iOS 与业务错误

| Domain / codes | 原因范围 | 下一步 |
|---|---|---|
| `OperationError 1000-1014` | 未知结果、超时、未登录、App/UDID/参数/限额/软件源/权限 | 按具体 code 登录、重连、重新选 IPA 或添加软件源 |
| `OperationError 1200-1202` | 找不到 Server、连接失败或中断 | 检查 USB/Wi-Fi 与 Server |
| `OperationError 1401-1402` | 赞助资格缺失或失效 | 在设置中重新连接相应账号 |
| `OperationError 1501` | Marketplace ID 无法确定 | 停止安装并检查可信来源 |
| `SourceError 0-7, 101-102` | 软件源格式、重复、安全封禁、标识变化、元数据或公证状态异常 | 修正软件源或联系维护者；安全错误不继续安装 |
| `VerificationError 2-3, 101-105, 201-202, 301` | 系统/地区、身份/hash/版本、权限或来源不匹配 | 停止安装并从可信原始来源重新下载 |
| `AuthenticationError 0-3` | 团队、证书或私钥缺失 | 检查账号团队并重新登录 |
| `RefreshError 0` | 没有需要刷新的 App | 无需处理，不显示失败弹窗 |
| `BatchError 0` | 批量操作含一个或多个具体错误 | 逐项显示去重后的具体原因 |
| `PatchAppError 0` | 找不到当前 iOS 的 OTA 资源 | 更新两端后重试 |
| `MergeError 0-2` | 版本或权限缓存与软件源不一致 | 刷新软件源，必要时稍后重试 |
| `PatreonAPIError 0-4` | 未知、未连接、token、限流或未配置 | 检查账号/网络；未配置时不发请求 |
| `MastodonError 0-4`、`BlueskyError 0-7` | 认证、HTTP、账号或内容不存在 | 检查账号和网络 |
| `JITError 0-1`、`MountError 0` | 目标未运行、依赖缺失或磁盘已挂载 | 打开目标 App 或安装所需依赖 |
| `ProcessError 0-3` | 进程失败、超时、输出异常或退出 | 主提示不显示原始输出；详情保留进程与退出码 |

## Windows 专属

| Domain / codes | 原因范围 | 下一步 |
|---|---|---|
| `AltServer.OperationError 0-4` | 取消、团队/私钥/证书/Info.plist 缺失 | 取消不提示；其余重新登录或重新取得 IPA |
| `AltServer.AppleProgramError 0-6` | iTunes/iCloud 或 Apple Application Support 组件缺失/无效 | 使用 Apple 官方安装程序修复组件 |
| `AltServer.WindowsError 1` | Windows Defender 阻止通信 | 在安全设置中仅放行 AltForge Server，不建议关闭整体实时防护 |
| `AltServer.DeveloperDiskError 0-2` | 下载地址、系统支持或归档内容异常 | 更新 Server 或选择受支持设备 |

Windows 的 `AltSign.Error` 与 `AppleDeveloperError` 现与 Apple 平台显式使用同一数值，避免 3013-3017 被解释成错误原因。
