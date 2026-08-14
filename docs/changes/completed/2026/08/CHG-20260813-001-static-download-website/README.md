# CHG-20260813-001：建立 AltForge 静态下载官网

- 状态：Completed
- 日期：2026-08-13
- 类型：Feature / Documentation / Distribution

## 背景

仓库已有 README、GitHub Release 与 `apps.json`，但用户缺少一个面向安装的统一网页入口。用户明确要求保持简单、复用仓库能力、下载链接使用 Release，并使用 UI UX Pro 形成设计基线后部署到 Cloudflare Pages。

## 范围

- 在 `website/` 建立无框架、无包管理器的 English/简体中文静态下载页。
- 首屏自动识别 macOS/Windows，下载本仓库 latest DMG/ZIP；其他平台进入 latest Release，并保留 unsigned IPA 的高级入口。
- 从本仓库 latest Release API 读取当前版本，失败时显示无版本号的“最新”；不复制 Release 二进制或建立第二个版本源。
- 使用仓库现有品牌图，支持系统深浅色、键盘、reduced-motion 和移动布局。
- 通过 `_headers` 配置 CSP、Referrer/Permissions policy，并以 Cloudflare Pages 静态目录部署。

## 追踪

- Requirement：`FR-039`、`AC-028`
- Design：`DES-025`
- Verification：`TEST-038`、Suite I
- Task：`T-038`

## 复杂度与资源

页面没有框架、构建或常驻服务。每次载入只执行一次有界 latest Release API 请求，不轮询；页面与版本处理为 `O(1)`，图片数量固定为三张。Release 二进制继续留在 GitHub，避免 Cloudflare 静态资源限制和重复存储。部署使用单次有界命令，失败不覆盖本地源码且 Pages 保留上一 deployment。

## 回滚

Cloudflare 可回滚到上一 deployment 或暂时删除 Pages 项目；仓库回滚只需还原 `website/`、生成脚本和对应文档，不影响 iOS、macOS、Windows、Release metadata、协议或签名链路。

## 实际验证

- `ruby Scripts/test_website.rb`、`ruby Scripts/test_repository_contract.rb`、`node --check website/app.js` 与 `git diff --check` 通过。
- Playwright 覆盖 320、375、768、1024、1440px，English/简体中文与浅色/深色；无横向滚动、坏图、不可操作的小尺寸控件或控制台错误，语言选择重载后保持。
- macOS 首要按钮指向 latest DMG，Windows 指向 latest ZIP，iPhone 进入 latest Release；Release API 不可用时显示“最新”，直接下载仍可用。
- Cloudflare Pages 生产站为 `https://altforge-dz7.pages.dev`；HTML 与图片返回 200，CSP、Permissions-Policy、Referrer-Policy、nosniff 和一小时图片缓存均在线生效。
- GitHub latest Release 在线版本为 2.4.1，DMG、ZIP、IPA 三个 latest 下载 URL 均返回 200。

## 残余风险

自定义域名不在本次范围；Cloudflare 与 GitHub 可用性仍是外部依赖。当前仓库变更尚未提交或推送，需在后续明确授权的 Git 交付中纳入。
