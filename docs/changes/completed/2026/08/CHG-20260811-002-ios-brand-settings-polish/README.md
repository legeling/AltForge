# CHG-20260811-002：收敛 iOS 品牌、配色与设置身份

## 背景

iOS 客户端主导航仍显示上游自定义来源图标，官方来源和自身应用卡片沿用大面积珊瑚红，设置页使用旧版青色满屏背景，并从过期的 `ALTVersion` 显示 2.3.3。设置中的仓库入口虽已指向 AltForge，但维护者、上游致谢和用户文案仍混用旧身份。

## 范围

- 四个主标签统一使用系统语义图标，不再展示上游来源 SVG。
- 官方来源和 AltForge 应用使用独立的深薄荷色 token；发布 metadata 同步更新，已缓存的旧红色 metadata 不再影响官方卡片。
- 设置页改用动态系统分组背景、卡片、标签、分隔线和状态栏颜色，保持深浅色可读性。
- 设置版本只读取构建产物的 `CFBundleShortVersionString`，移除 2.3.3 的静态覆盖。
- 明确区分 AltForge Contributors、上游原始开发者 Riley Testut 与原始设计 Caroline Moore，并将反馈、隐私和 GitHub 入口归属到本仓库。
- 同步英文、简体中文、日文和葡萄牙文已有 string catalog 条目；本次不改版本号、不建 tag、不发布 Release。

## 映射

- Requirement：`FR-034`
- Design：`DES-020`
- Verification：`TEST-033`
- Task：`T-022`

## 复杂度与资源

标签和品牌色按固定四个 controller 与常数次属性判断处理，时间、空间均为 `O(1)`。设置 cell 在显示时递归访问其有限 UIKit 子视图，成本为 `O(cell subviews)`，不增加网络、缓存、并发或长期进程。

## 验证记录

- `ruby Scripts/test_repository_contract.rb` 通过，覆盖四标签 SF Symbols、官方 source/app tint override、metadata 色值、动态设置背景、bundle 版本和仓库/致谢归属。
- string catalog、颜色 asset JSON、`AltStore/Info.plist` 解析通过；Authentication、Settings、Main storyboard 均通过 `ibtool --compile`；`git diff --check` 通过。
- `xcodebuild build -workspace AltStore.xcworkspace -scheme AltStore -configuration Debug -destination "platform=iOS Simulator,id=4D8C56F2-89BF-4DB8-8C32-18D64EA3F12F" -derivedDataPath /tmp/AltForge-ios-brand-settings-build CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES -quiet` 通过。
- `AltTests` 在同一 simulator 执行 64 项，53 项通过、11 项失败；失败均为既有简体中文 error bridge 句间空格差异，继续由 `T-006` 跟踪，与本次导航、颜色、设置版本和归属改动无调用关系。
- iPhone 17 Pro / iOS 26.5 simulator 深色模式检查通过：四标签图标统一、官方来源和自身 App 不再使用红色、设置页使用中性系统分组色、版本显示 `2.4.0`，且同时显示 Riley Testut、AltForge Contributors 与 Caroline Moore。
- 同一 simulator 浅色模式检查通过，设置背景、cell、标签、分隔线和底部版本保持可读。
- 首轮 simulator 检查发现 `willDisplay` 中不应调用未实现的 superclass delegate 方法；移除该调用后重新构建、安装和进入设置页，未再复现崩溃。
- 未执行真机 UI/安装矩阵；本 change 不改签名、安装协议或持久化结构，真机视觉回归保留为后续缺口。

## 回滚

恢复 tab 图片、颜色 token、settings appearance、metadata tint 和 string catalog 即可；不涉及数据库 schema、协议或用户数据迁移。
