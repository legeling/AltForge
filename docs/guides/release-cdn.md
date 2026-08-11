# Release CDN 配置

AltForge 的 GitHub Release 始终是官方发布源。维护者可以把同一份 `AltForge.ipa` 复制到自有 HTTPS CDN，并让 macOS AltForge Server 在自动模式下优先使用 CDN；用户也可以在下载窗口中手动切换 GitHub、CDN 或固定公共镜像。

## 对象路径

CDN 使用不可变的版本路径：

```text
<ALT_FORGE_CDN_BASE_URL>/v<version>/AltForge.ipa
```

例如 `ALT_FORGE_CDN_BASE_URL=https://cdn.example.com/altforge`、版本 `2.5.0` 时，对象地址为 `https://cdn.example.com/altforge/v2.5.0/AltForge.ipa`。Base URL 必须是无账号、密码、query 和 fragment 的 HTTPS URL。

## 发布顺序

1. Release workflow 构建 `AltForge.ipa` 后，把完全相同的字节上传到上述版本固定路径。
2. 对 CDN 对象计算 SHA-256，并与 workflow 生成的 `SHA256SUMS.txt` 中 `AltForge.ipa` 条目比较；不一致时不得发布。
3. 在 GitHub 仓库 Actions Variables 中设置 `ALT_FORGE_CDN_BASE_URL`。它不是凭据，不要把 CDN 写入密钥放在这个变量中。
4. 重新运行 tag 对应的 Release workflow。生成的 `apps.json` 会在当前版本写入 `downloadMirrors`；发布 Draft 前确认 CDN URL 返回完整文件。
5. 发布后不要覆盖版本对象。新版本使用新路径；回滚时删除错误 Draft 或修正新 tag，不原地替换已公开 IPA。

上传方式取决于实际 CDN。访问密钥必须放在 GitHub Actions Secrets，并只授予目标 bucket/path 的写权限；当前仓库不会假设某一家供应商，也不会在未配置凭据时上传任何对象。

## HTTP 与缓存要求

- 必须支持 HTTPS `GET`，建议支持 `HEAD` 和 byte range。
- 版本路径应使用长缓存和 `immutable`；`apps.json` 仍从 GitHub Release 获取，不走不可控的 latest CDN 缓存。
- 不需要浏览器 CORS，但不得要求 Cookie、Referer、Apple ID 或设备信息。
- CDN、GitHub 和公共镜像下载完成后都必须匹配 `apps.json`/GitHub API 的文件大小和 SHA-256，否则 AltForge Server 会拒绝解压和签名。
- 单次自动下载是有界的顺序尝试，不并发下载多个完整 IPA。手动切换线路会取消当前任务并从新线路重新开始。

## 本地验证

```sh
version="$(tr -d '[:space:]' < VERSION)"
curl --fail --location --max-time 600 \
  "${ALT_FORGE_CDN_BASE_URL%/}/v${version}/AltForge.ipa" \
  | shasum -a 256
```

不要把下载的真实 IPA、CDN 凭据、Apple 账号或设备标识加入仓库。公开发布前仍需在脱敏设备上验证 CDN 下载、手动线路切换、签名和安装完整流程。
