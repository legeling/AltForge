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

- 在临时 artifact 目录准备最小 IPA/macOS archive。
- 运行 metadata script。
- 解析 `apps.json` 并复算 size/hash。
- 不创建 tag、不发布 Release。

## Suite E：真实设备

触发：Apple API、provisioning、signing、device install、JIT、最低系统变化。

- 使用脱敏测试账户与设备。
- 执行 `TEST-002` 和受影响路径。
- 不将凭据、UDID 或 profile 保存为 artifact。

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

- CI 是命令真相的首选来源，本文件解释触发条件。
- destination 或 Xcode 版本变化时同时更新 workflow、README 和 reference。
- 失败结果记录首个根因与未执行的后续 suite，不保存大型完整日志到 `docs/`。
