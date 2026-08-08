# Project Testing Rules

- Source、URL、error、encoding 等纯逻辑优先单元测试。
- Shared wire contract、Core Data 和 Operation graph 使用 integration test。
- signing、provisioning、device install、JIT 变化必须有真实设备验证计划。
- Archive/security 修复必须覆盖恶意输入、失败清理和 round trip。
- Localization 变化至少构建受影响 target，并检查简体中文与英文 fallback。
- Release 脚本先 dry run，再使用真实 tag。
- 测试 fixture 不得包含真实第三方 IPA、凭据、UDID、certificate 或 profile。
- 所有临时目录、simulator/build process 和 connection 在测试后回收。
- 具体用例、命令和覆盖状态维护在 `docs/workflow/04-verification/`，本文件不保存单次测试结果。
