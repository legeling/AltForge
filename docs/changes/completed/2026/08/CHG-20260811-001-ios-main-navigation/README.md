# CHG-20260811-001：收敛 iOS 主导航

## 背景

Classic 客户端的聚合资讯标签与浏览、来源入口内容重叠，且不是 AltForge 安装、刷新和来源管理的核心路径。用户确认当前版本不需要这个独立页面，本次未修改版本号、tag 或 Release。

## 实现

- 从 iOS 主 storyboard 删除聚合资讯 scene 与 tab relationship。
- 将浏览设为默认首屏，后续依次为软件源、我的 App、设置。
- 保留 source schema、`NewsItem` persistence 和来源详情内的资讯展示，避免破坏第三方 source 兼容。
- repository contract 使用 XML parser 检查四个 relationship 的顺序，同时锁定 `Tab` 枚举与来源资讯兼容入口。

## 映射

- Requirement：`FR-033`
- Design：`DES-019`
- Verification：`TEST-032`
- Task：`T-021`

## 性能与风险

主 tab 数量固定，初始化仍为 `O(1)`，并少实例化一个 navigation/controller 树；source 解析与同步复杂度不变。主要回归风险是 tab 索引错位导致 deep link 打开错误页面，已由 repository contract 覆盖。来源详情中的资讯区域完成静态与编译验证，没有构造带资讯的第三方 source 做手工点击。

## 验证记录

- `ruby Scripts/test_repository_contract.rb`：通过。
- `xcrun ibtool --compile` 主 storyboard：通过，无 warning/error。
- `xcodebuild build -workspace AltStore.xcworkspace -scheme AltStore -configuration Debug -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO`：通过。
- 临时 iOS 26.5 iPhone 17 Pro simulator：启动进入简体中文“浏览”，底栏依次显示“浏览 / 软件源 / 我的 App / 设置”，没有“资讯”。
- Main string catalog JSON parse 与 change-scope `git diff --check`：通过。

## 回滚

恢复 Main storyboard 的资讯 scene、tab relationship、对应 string catalog 条目与 `Tab.news` 索引即可；无需迁移 Core Data 或用户数据。
