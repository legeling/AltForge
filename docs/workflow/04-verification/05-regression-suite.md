# Regression Suite

## Suite A：快速逻辑回归

触发：Source、error model、URL normalization、纯 Swift/ObjC helper 变化。

```sh
xcodebuild test \
  -workspace AltStore.xcworkspace \
  -scheme AltStore \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=latest" \
  CODE_SIGNING_ALLOWED=NO
```

## Suite B：跨目标构建

触发：project settings、Shared、AltStoreCore、localization、dependency、submodule 变化。

```sh
xcodebuild build \
  -workspace AltStore.xcworkspace \
  -scheme AltStore \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO

xcodebuild build \
  -workspace AltStore.xcworkspace \
  -scheme AltServer \
  -configuration Debug \
  -destination "generic/platform=macOS" \
  CODE_SIGNING_ALLOWED=NO
```

## Suite C：Unicode archive

触发：AltSign ZIP、application name、resign、download/install path 变化。

- 运行 `TEST-003`、`TEST-005`、`TEST-006`、`TEST-007`。
- round trip 后用 ZIP reader 验证 bit 11。
- 删除临时目录并确认无 handle/process 遗留。

在这些测试进入仓库前，Suite C 仍是残余风险，不能标记为 automated。

## Suite D：Release dry run

触发：release workflow、metadata script、bundle ID、minimum OS、source URL 变化。

- 运行 `ruby Scripts/check_release_version.rb`，确认根版本与三平台产品版本一致。
- 运行 `ruby Scripts/test_release_metadata.rb` 和 `ruby Scripts/test_repository_contract.rb`。
- 在临时 artifact 目录准备最小 IPA、macOS DMG 和 Windows ZIP。
- 运行 metadata script。
- 解析 `apps.json` 与三个远程配置 JSON，复算全部 size/hash，验证历史不超过 20 条。
- 解析 `developerdisks.json`，校验 version 1 schema、HTTPS 和允许 host；扫描 Classic 控制端点，确认没有回退到上游 CDN、staging bucket 或上游 OAuth callback。
- 验证遗留 Mail plug-in manager 无网络 URL，默认 Patreon 配置在发起请求前 fail closed，release build settings 未定义 `MARKETPLACE`。
- 验证 Classic 启动不调度 Fediverse operation、source 刷新不查询上游 CloudKit，交互 UI 固定关闭。
- 不创建 tag、不发布 Release。

## Suite E：真实设备

触发：Apple API、provisioning、signing、device install、JIT、最低系统变化。

- 使用脱敏测试账户与设备。
- 执行 `TEST-002` 和受影响路径。
- 不将凭据、UDID 或 profile 保存为 artifact。

## Suite G：macOS DMG

触发：macOS build setting、AltServer bundle、DMG 打包脚本或 release asset 变化。

- 运行 `bash -n Scripts/package_macos_dmg.sh` 与 repository contract。
- 运行 `bash -n Scripts/verify_apple_release_artifacts.sh`；tag workflow 在 Apple runner 上用实际版本和 build number 执行该脚本。
- 使用独立 DerivedData 构建 Release AltServer，并通过脚本生成新的输出路径；本地与 CI Release 都使用 `--ad-hoc-sign` 密封 DMG 内的 staging App，不修改原构建输出。
- 执行 `hdiutil verify`，只读挂载后检查 `AltForge Server.app`、Applications symlink、bundle identifier、版本和目标架构。
- CI verifier 同时检查 IPA Payload/identity/version、DMG 的 arm64+x86_64 架构和当前 non-Developer-ID policy；App 必须通过 `codesign --verify --deep --strict` 且保持 ad-hoc/no Team ID/no Authority，linker-only 或无效嵌套签名必须 fail closed。publish job 在创建 Draft 前执行 checksum manifest verification。
- 验证后推出本次挂载、清理 DerivedData 与 staging；保留 DMG 仅限用户需要试装时。
- 本地 ad-hoc 签名不得替代 Developer ID、notarization 或另一台 Mac 的 Gatekeeper 验证。

## Suite H：macOS 菜单与设置

触发：AltForge Server 公开名称、About/版权、状态菜单、设备发现、检查更新、图标、设置或 macOS 本地化变化。

- 静态检查 Info.plist、storyboard、string catalogs 和用户可见源码，不允许 About/菜单回退到旧公开名称。
- 构建 AltServer Release，检查 `CFBundleDisplayName`、版权、19/38 px template 菜单图标和完整 AppIcon slots。
- 无设备时显示可理解 placeholder；USB、Wi-Fi 与同时连接分别显示正确标签，双连接优先 USB。
- 确认设置项直接位于状态菜单子菜单中且不会打开独立窗口；切换登录启动后显示“已开启/已关闭/需要批准”并与系统登录项一致，签名或注册失败时出现可恢复错误；切换跟随系统、English、简体中文后出现重启提示，立即重启后检查菜单、About 和错误文案。
- 确认 Install AltForge 使用安装图标，三个设备子菜单均未被标记成 Recent Documents，也不显示系统注入的时钟图标。
- 更新检查覆盖更新可用、已最新、404/离线、超时、无效 JSON 与非 GitHub URL；不得自动下载或替换 App。
- 遗留邮件插件未安装时入口隐藏；存在时只显示明确的清理文案。
- 无历史账号时可手工输入；成功认证后账号进入最近使用列表，未勾选记住密码时重新选择账号不预填密码。
- 勾选记住密码后只检查本机 Keychain，不检查 UserDefaults、日志或发布产物；忘记账号同时移除可选密码。
- 密码眼睛按钮在 secure/plain 间无损切换，Caps Lock 开关实时显示/隐藏提示，关闭窗口后 local event monitor 已释放。
- 损坏、超限或不可访问的 Keychain archive fail closed，仍允许手工认证且不显示账号、密码或底层 Keychain 详情。

## Suite F：Windows AltServer

触发：`AltServer-Windows/`、Windows dependency pin、CI/release workflow 或 Windows artifact contract 变化。

```powershell
.\AltServer-Windows\Scripts\build-release.ps1 -OutputDirectory "$env:TEMP\AltForge-Windows"
```

- 使用固定 revision 恢复依赖，存在不同 checkout 时必须失败而不是覆盖。
- 构建 Win32 Release，并验证 ZIP 至少包含 AltServer、ldid、libimobiledevice、usbmuxd、plist、DNS-SD、cpprestsdk 和 VC runtime。
- 使用 Apple 官网版 iTunes/iCloud 做 `TEST-019`；不得把 Apple 安装包或敏感数据加入 artifact。
- macOS/Linux 上的 XML/YAML/parser 检查不等同于 MSBuild 通过。

## 命令登记规则

- tag-driven Release workflow 是自动构建命令的真相来源，本文件解释本地预检和触发条件。
- destination 或 Xcode 版本变化时同时更新 workflow、README 和 reference。
- 失败结果记录首个根因与未执行的后续 suite，不保存大型完整日志到 `docs/`。
