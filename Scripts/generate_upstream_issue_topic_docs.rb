#!/usr/bin/env ruby

require "fileutils"
require "json"

ROOT = File.expand_path("..", __dir__)
AUDIT_PATH = File.join(ROOT, "docs/issues/upstream/altstore-open-issue-audit.json")
TOPICS_DIR = File.join(ROOT, "docs/issues/upstream/topics")

TOPICS = {
  "authentication-team" => {
    file: "01-apple-authentication-and-teams.md",
    title: "Apple 认证、2FA、团队与 Provisioning",
    scope: "Apple ID 登录、2FA、anisette、证书、Provisioning Profile、App ID 限额，以及免费、个人、组织和企业团队识别。",
    merge: "共同门禁是认证状态机、Apple 服务错误保真、团队能力判定与敏感数据保护，因此合并到同一认证兼容风险。",
    decision: "纳入当前 Classic 维护范围；以脱敏真实账号矩阵和失败恢复验证为完成依据。"
  },
  "ipa-signing-packaging" => {
    file: "02-ipa-signing-and-packaging.md",
    title: "IPA、签名、归档路径与扩展",
    scope: "IPA/ZIP 解包、Unicode 路径、Info.plist、nested code、extensions、ldid、AltSign 和大型包安装。",
    merge: "按归档解析、签名底层与 iOS 安装回归三个所有者映射到既有本地 Issue，避免为单个 App 建重复问题。",
    decision: "纳入当前范围；第三方 IPA 只有能复现到共享解析、签名或安装链路时才提升为实现任务。"
  },
  "device-connectivity" => {
    file: "03-device-discovery-and-connectivity.md",
    title: "设备发现、USB、Wi-Fi 与 Server 连接",
    scope: "设备枚举、配对与信任、Bonjour discovery、USB/Wi-Fi fallback、连接中断、socket reset 和多设备选择。",
    merge: "共同门禁是跨平台连接矩阵、超时、迟到回调隔离、任务去重与资源释放。",
    decision: "纳入当前范围，并统一合并到设备发现与连接实机验证。"
  },
  "refresh-backup-lifecycle" => {
    file: "04-refresh-backup-and-lifecycle.md",
    title: "刷新、停用、备份与应用生命周期",
    scope: "refresh、deactivate、backup/restore、App ID、到期、部分失败、取消和失败清理。",
    merge: "这些报告共享安装记录、设备状态、备份状态与本地持久化之间的一致性门禁。",
    decision: "纳入当前范围；以幂等、原子恢复和跨平台真机回归作为关闭条件。"
  },
  "jit" => {
    file: "05-altjit-runtime.md",
    title: "AltJIT、Developer Disk、隧道与进程选择",
    scope: "Developer Disk、pymobiledevice3、RemoteXPC/RSD、隧道、debugserver、PID 选择及新系统兼容。",
    merge: "共同所有者位于 AltJIT 运行时适配层，且都依赖有界子进程、端口发现和失败清理。",
    decision: "纳入当前范围；不得通过修改用户全局 Python、关闭安全机制或终止无关进程规避。"
  },
  "desktop-distribution" => {
    file: "06-desktop-distribution.md",
    title: "macOS/Windows 桌面分发与安装器",
    scope: "AltServer 更新、DMG/ZIP、iCloud/iTunes 前置条件、菜单栏/托盘、启动项、架构和桌面安装失败。",
    merge: "按 macOS 分发签名、干净构建与 Windows 构建/设备验证映射到已有风险。",
    decision: "Classic 桌面端属于当前范围；平台特有结果必须分别验证，不能互相代替。"
  },
  "build-development" => {
    file: "07-build-and-development.md",
    title: "源码构建与开发环境",
    scope: "Xcode、submodule、AltSign clone、版本字段、开发构建和仓库提问规范。",
    merge: "可执行构建故障合并到干净 checkout 可复现性；纯提问和仓库模板不创建产品风险。",
    decision: "维护构建基线，但不把一般支持请求自动升级为缺陷。"
  },
  "ios-runtime-ui" => {
    file: "08-ios-runtime-ui-and-localization.md",
    title: "iOS 运行时、崩溃、UI 与本地化",
    scope: "启动崩溃、黑屏、Widget、后台行为、语言、图标、系统版本变化和安装时客户端退出。",
    merge: "运行时安装崩溃与本地化回归映射到现有风险，其余条目在复现后按具体模块进入 change。",
    decision: "当前范围内保留证据，但标题相似不代表共同根因。"
  },
  "network-source-download" => {
    file: "09-sources-downloads-and-network.md",
    title: "Source、下载、网络与远程配置",
    scope: "Source schema、源地址、下载、GitHub/API、网络错误、远程配置和内容可用性。",
    merge: "当前 requirements 已覆盖官方源、下载路由、完整性、超时和失败可见性，因此不重复创建本地 Issue。",
    decision: "标记为既有需求覆盖；出现可复现回归时再关联具体 TEST 与 change。"
  },
  "feature-request-other" => {
    file: "10-unplanned-feature-requests.md",
    title: "未进入当前路线的功能建议",
    scope: "排序筛选、深链、多实例、权限预览、屏幕常亮、Android 等未纳入当前计划的建议。",
    merge: "这些条目是产品机会而非已确认缺陷，不应混入交付阻塞项。",
    decision: "记录为 not-currently-planned；只有需求、范围和验收标准明确后才建立 change。"
  },
  "marketplace-pal" => {
    file: "11-marketplace-and-pal.md",
    title: "Marketplace、PAL 与替代市场",
    scope: "AltStore PAL、Marketplace entitlement、notarized distribution、Patreon 和 EU 替代市场路径。",
    merge: "AltForge 当前发布明确是 Classic，PAL/Marketplace 的身份、协议与发布门禁不同。",
    decision: "当前范围外；保留证据用于防止 Classic 与 Marketplace 语义再次混淆。"
  },
  "jailbreak-altdaemon" => {
    file: "12-jailbreak-and-altdaemon.md",
    title: "越狱、AltDaemon 与旁路安装环境",
    scope: "AltDaemon、Dopamine、palera1n、unc0ver、TrollStore、SparseBox 和越狱专用路径。",
    merge: "这些路径改变信任、安装与运行模型，不能用 Classic 的 Apple Developer 签名门禁验证。",
    decision: "当前范围外；不据此修改 Classic 安全默认值。"
  },
  "apple-tv" => {
    file: "13-apple-tv-and-tvos.md",
    title: "Apple TV 与 tvOS",
    scope: "Apple TV 发现、tvOS 安装、Kodi/unc0verTV 等 tvOS 包。",
    merge: "tvOS 目标、设备服务与应用能力均不在当前 iOS/iPadOS Classic 交付矩阵中。",
    decision: "当前范围外；未来只有建立独立平台需求和验证矩阵后才重新评估。"
  },
  "linux" => {
    file: "14-linux-server.md",
    title: "Linux 与远程 AltServer",
    scope: "Linux AltServer、永久远程 Server 和非本地网络部署。",
    merge: "当前实现与发布只覆盖 macOS 和 Windows，远程 Server 还会改变认证、网络与信任边界。",
    decision: "当前范围外；不能作为现有桌面端的隐式兼容承诺。"
  },
  "low-signal-other" => {
    file: "15-insufficient-evidence.md",
    title: "证据不足、空内容与无法行动条目",
    scope: "空正文、仅产品名、重复占位、垃圾内容或无法识别预期行为和复现条件的报告。",
    merge: "信息不足时强行归因会污染风险模型，因此只保留可追溯记录，不创建实现任务。",
    decision: "标记为 insufficient-actionable-evidence；补充环境、步骤、预期和实际结果后重新分类。"
  }
}.freeze

def escape_cell(value)
  value.to_s.gsub("|", "\\|").gsub(/\r?\n/, " ").strip
end

def issue_link(issue)
  "[##{issue.fetch("number")}](#{issue.fetch("url")})"
end

audit = JSON.parse(File.read(AUDIT_PATH))
issues = audit.fetch("issues")
grouped = issues.group_by { |issue| issue.fetch("category") }

missing = grouped.keys - TOPICS.keys
extra = TOPICS.keys - grouped.keys
abort("Unconfigured audit categories: #{missing.join(", ")}") unless missing.empty?
abort("Configured categories missing from audit: #{extra.join(", ")}") unless extra.empty?

FileUtils.mkdir_p(TOPICS_DIR)

TOPICS.each do |category, topic|
  topic_issues = grouped.fetch(category).sort_by { |issue| -issue.fetch("number") }
  dispositions = Hash.new(0)
  topic_issues.each { |issue| dispositions[issue.fetch("disposition")] += 1 }
  local_ids = topic_issues.flat_map { |issue| issue.fetch("localIssueIds") }.uniq.sort

  lines = []
  lines << "# #{topic.fetch(:title)}"
  lines << ""
  lines << "- 上游仓库：[`altstoreio/AltStore`](https://github.com/altstoreio/AltStore)"
  lines << "- 最后核对：2026-08-11"
  lines << "- 开放 Issue：#{topic_issues.length} 条"
  lines << "- 分类键：`#{category}`"
  lines << "- 处置分布：#{dispositions.sort.map { |name, count| "`#{name}` #{count} 条" }.join("；")}"
  lines << "- 本地映射：#{local_ids.empty? ? "无" : local_ids.map { |id| "[`#{id}`](../../#{id}-#{case id
    when "ISSUE-20260808-001" then "unicode-regression-tests"
    when "ISSUE-20260808-003" then "macos-distribution-signing"
    when "ISSUE-20260808-005" then "clean-build-reproducibility"
    when "ISSUE-20260808-006" then "altsign-classic-baseline"
    when "ISSUE-20260808-007" then "zh-error-test-spacing"
    when "ISSUE-20260809-001" then "windows-build-device-validation"
    when "ISSUE-20260811-002" then "ios-third-party-install-device-validation"
    when "ISSUE-20260811-003" then "apple-authentication-team-compatibility"
    when "ISSUE-20260811-004" then "altjit-runtime-compatibility"
    when "ISSUE-20260811-005" then "device-discovery-connectivity"
    when "ISSUE-20260811-006" then "refresh-backup-lifecycle"
    else abort("Unknown local issue mapping: #{id}")
    end}.md)" }.join("、")}"
  lines << ""
  lines << "## 主题边界"
  lines << ""
  lines << topic.fetch(:scope)
  lines << ""
  lines << "## 合并依据"
  lines << ""
  lines << topic.fetch(:merge)
  lines << ""
  lines << "## AltForge 处置"
  lines << ""
  lines << topic.fetch(:decision)
  lines << ""
  lines << "本分类是维护分流，不声称所有上游报告具有同一根因；本地实施仍需复现、定位并关联 `FR/DES/TEST/T/CHG`。"
  lines << ""
  lines << "## 全部上游条目"
  lines << ""
  lines << "| Issue | 标题 | 更新日期 | Labels | 处置 | 本地 Issue |"
  lines << "|---:|---|---|---|---|---|"
  topic_issues.each do |issue|
    labels = issue.fetch("labels").map { |label| label.is_a?(Hash) ? label["name"] : label }.compact.join(", ")
    mappings = issue.fetch("localIssueIds").map { |id| "`#{id}`" }.join(", ")
    lines << "| #{issue_link(issue)} | #{escape_cell(issue.fetch("title"))} | #{issue.fetch("updatedAt")[0, 10]} | #{escape_cell(labels)} | `#{issue.fetch("disposition")}` | #{mappings.empty? ? "-" : mappings} |"
  end
  lines << ""
  lines << "## 复核规则"
  lines << ""
  lines << "- 上游状态或证据变化时，更新机器审计后重新生成本页。"
  lines << "- 只有共同所有者、风险和完成门禁一致时才继续合并；出现独立根因时拆出新的本地 Issue。"
  lines << "- 不在仓库复制正文、评论、附件、作者、Apple ID、UDID、证书或其他敏感材料。"

  File.write(File.join(TOPICS_DIR, topic.fetch(:file)), lines.join("\n") + "\n")
end

index = []
index << "# 上游 Issue 主题报告"
index << ""
index << "这里按维护责任和验证门禁拆分 `altstoreio/AltStore` 的全部 645 个开放 Issue。每个文件都包含该主题的范围、合并依据、AltForge 处置和完整条目清单。"
index << ""
index << "| 顺序 | 主题 | 数量 | 主要处置 |"
index << "|---:|---|---:|---|"
TOPICS.each_with_index do |(category, topic), index_number|
  topic_issues = grouped.fetch(category)
  dispositions = Hash.new(0)
  topic_issues.each { |issue| dispositions[issue.fetch("disposition")] += 1 }
  primary = dispositions.max_by { |_name, count| count }.first
  index << "| #{index_number + 1} | [#{topic.fetch(:title)}](#{topic.fetch(:file)}) | #{topic_issues.length} | `#{primary}` |"
end
index << ""
index << "主题总数必须与 [`altstore-open-issue-audit.json`](../altstore-open-issue-audit.json) 的 `count` 一致。审计方法和处置规则分别见 [`METHODOLOGY.md`](../METHODOLOGY.md) 与 [`SCOPE-AND-DISPOSITION.md`](../SCOPE-AND-DISPOSITION.md)。"
File.write(File.join(TOPICS_DIR, "README.md"), index.join("\n") + "\n")

puts "Generated #{TOPICS.length} topic reports for #{issues.length} upstream issues."
