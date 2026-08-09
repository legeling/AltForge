# Localization Rules

## 文案与资源

- 用户可见字符串使用目标现有的 `.xcstrings`/localization 设施，不把英文或中文直接硬编码进业务逻辑。
- 新增或修改文案至少维护英文基线和简体中文；其他语言缺失时保持明确 fallback，不复制机器翻译充数。
- 格式化内容使用可本地化占位符和 locale-aware API，不通过字符串拼接固定语序。
- 按钮、错误、通知和权限说明保持术语一致；品牌名 `AltForge`、协议字段和代码标识不随意翻译。

## 仓库入口文档

- `README.md` 作为英文入口，`README.zh-CN.md` 作为简体中文入口；两份文档顶部必须互相链接并标记当前语言。
- 项目能力、系统要求、下载、安装、构建、发布、已知限制和许可证等事实变化时，两份 README 必须在同一 change 中同步。
- 两种语言应保持相同信息层级和链接目标，可以按语言习惯改写表达，但不能让其中一份承诺另一份没有的能力。
- 路径、命令、artifact 名称、bundle identifier、版本号和外部 URL 保持一致，不翻译代码标识。

## Unicode 与文件处理

- App name、bundle display name、source metadata、archive entry 和资源文件名按 Unicode 处理，不假设 ASCII。
- 只有外部协议明确限制 ASCII 的字段才做规范化；必须保留原始用户可见名称，并为规范化为空定义稳定 fallback。
- ZIP/IPA filename encoding 变化覆盖 UTF-8 flag、Unicode extra field、legacy fallback、round trip 和非法路径。
- 比较、排序、大小写和长度限制必须说明使用 code point、grapheme、UTF-8 byte 还是目标协议定义。

## 验证

- 至少检查英文与简体中文的编译、fallback、截断、复数/占位符和错误路径。
- 文件与安装链路使用中文、组合字符、emoji、空白和长名称 fixture；fixture 不包含第三方私有 IPA。
- Localization 行为变化更新 test matrix/coverage map；真实设备安装仍需按风险补测。
