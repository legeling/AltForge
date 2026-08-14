# CHG-20260814-001：重构官网视觉并关联代码仓库

- 状态：In progress / hosted deploy secrets pending
- 日期：2026-08-14
- 类型：Feature / Design / Distribution

## 背景

首版静态官网功能、下载与生产部署已经成立，但用户反馈首屏视觉质量不足：两张超大应用图标重复堆叠，标题、版本、下载和品牌图互相争夺注意力，整体不像可信的开源产品下载入口。Cloudflare Pages 项目仍是 Direct Upload，GitHub 仓库 About 未形成清晰官网关系，网站源码与自动部署也尚未完成 Git 交付。

## 范围

- 使用 UI/UX Pro Max 与设计系统重新定义工业编辑型视觉方向。
- 以规范 AltForge 图标为参考生成单一全幅 hero raster，移除玻璃/钛金属双图标舞台和浮动版本卡。
- 重构首屏、仓库归属带、平台下载、安装流程、能力说明、FAQ 与 footer 的响应式层级。
- 增加一次性首屏入场、仓库信息分层、可见区内容揭示、FAQ 展开与控件反馈；所有动效不改变布局，reduced-motion 下退化为即时显示。
- 保留双语、平台识别、latest Release 单一版本源、直接下载、安全披露、无分析与无第三方字体。
- 增加 GitHub Actions website workflow，在 PR/push 上验证，在显式变量与 Secrets 齐备后把 `marketplace` 的 `website/` 部署到现有 Cloudflare Pages 项目。
- 将生产官网写入 GitHub repository homepage；提交、推送和 Secrets 写入遵循单独 Git/凭据授权边界。

## 追踪

- Requirement：`FR-040`、`AC-029`
- Design：`DES-026`
- Verification：`TEST-039`
- Task：`T-039`

## 复杂度与资源

页面仍是无构建静态站。首屏只新增一张有界 JPEG，移除两个运行时使用的重复图标；版本 API 为单次 8 秒超时请求且不重试，时间、内存和网络扇出均为 `O(1)`。滚动动效只观察页面内固定数量的内容节点，节点首次进入后立即 `unobserve`，总时间和额外空间为 `O(n)` 且本页 `n` 有界，不创建滚动轮询。GitHub Actions verify 上限 5 分钟，deploy 上限 10 分钟，同 ref 只保留最新任务。Cloudflare 凭据不进入仓库，deploy 默认关闭。

## 回滚

代码可恢复为本 change 之前的 `website/index.html`、`styles.css` 和 `app.js`，或从 Cloudflare Pages deployment history 恢复上一生产 deployment。GitHub homepage 可清空或改回 Releases；workflow 可通过删除启用变量立即停止生产部署，不需要撤销 Release 或应用代码。

## 当前验证

- `ruby Scripts/test_website.rb`、`ruby Scripts/test_repository_contract.rb`、`node --check website/app.js`、workflow YAML parse、HTML5 文档边界与 `git diff --check` 通过。
- Cloudflare Production deployment `92c5fb54-fb41-4e1a-a645-eb0c4ce030d8` 成功；production alias 返回 200，CSP、Permissions-Policy、Referrer-Policy 与 `nosniff` 生效。
- 线上 HTML、CSS、JavaScript 和 hero JPEG 的 SHA-256 与当前本地文件逐项一致；hero 为 1774 × 887、约 236 KiB。
- latest Release API 返回正式 `v2.4.1`；DMG、Windows ZIP 与 IPA latest URL 均返回 200。
- GitHub repository homepage 已设置为 `https://altforge-dz7.pages.dev`。
- 本地 Playwright 已覆盖 320/375/768/1024/1440/1918px、English/简体中文、浅色/深色与 reduced motion；所有尺寸均无横向溢出或可见元素越界，语言选择刷新后保持，FAQ 可展开，Windows 与 macOS 主下载路由正确。
- 动效验证覆盖 hero/header 入场、23 个有界 reveal 节点、节点进入后解除观察、按钮图标反馈与 FAQ answer 入场；reduced-motion 下不启用 reveal observer，animation/transition 均缩短为 `0.01ms`。
- CSS 请求被主动阻断时，12 个内联 SVG 仍保持 20-28px 的显式尺寸；不会再次出现无样式页面中的巨型 GitHub 图标。
- `marketplace` 已推送 `2063c3fd` 与 CI 修复 `e5a7f7f8`；Website Actions run `31790637050` 的 JavaScript 与两项 repository contract hosted verify 通过，deploy job 因启用变量未设置而按设计跳过。

## 残余风险

- Cloudflare `altforge` 是 Direct Upload 项目，不能原地转换为原生 Git integration；自动部署依赖 GitHub Actions 与最小权限 Pages token。
- 当前仓库尚无 `CLOUDFLARE_API_TOKEN` 与 `CLOUDFLARE_ACCOUNT_ID` Secrets，workflow 的生产 deploy 按设计保持禁用。
- Direct Upload 已完成当前生产交付；未来 push 自动部署仍需配置最小权限 Secrets 和显式启用变量。
