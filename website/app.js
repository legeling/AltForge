"use strict";

const repository = "https://github.com/legeling/AltForge";
const releaseBase = `${repository}/releases/latest/download`;
const latestReleaseAPI = "https://api.github.com/repos/legeling/AltForge/releases/latest";

const copy = {
  "zh-Hans": {
    skip: "跳到主要内容",
    navDownload: "下载",
    navWorkflow: "流程",
    navHelp: "帮助",
    heroKicker: "开源维护中的 AltStore Classic",
    heroLede: "更可靠的经典侧载工具，为中文、Unicode 应用与现代 Apple 平台持续维护。",
    latestFallback: "最新",
    latestRelease: "最新发布",
    iosRequirement: "支持 iOS 17.4+",
    downloadRelease: "下载最新版本",
    downloadMac: "下载 macOS 版",
    downloadWindows: "下载 Windows 版",
    viewSource: "查看源代码",
    downloadNote: "自动为你的电脑选择安装服务，也可以在下方手动选择平台。",
    downloadMacNote: "已识别为 Mac，下载通用 DMG；也可以在下方手动选择其他平台。",
    downloadWindowsNote: "已识别为 Windows，下载便携式 ZIP；也可以在下方手动选择其他平台。",
    heroNext: "版本与源码",
    repositoryLabel: "官方仓库",
    repositoryCode: "源代码",
    repositoryCodeNote: "公开、可审计",
    integrity: "完整性",
    license: "许可证",
    downloadEyebrow: "桌面端安装服务",
    downloadTitle: "选择你的电脑",
    downloadIntro: "AltForge 需要电脑端 Server 完成认证、签名和设备安装。所有文件均直接来自本仓库最新 Release。",
    recommended: "推荐",
    macDescription: "适用于 Apple 芯片和 Intel Mac 的通用 DMG。",
    windowsDescription: "便携式 Win32 版本，包含运行所需的 DLL。",
    downloadDmg: "下载 DMG",
    downloadZip: "下载 ZIP",
    macWarning: "当前为 ad-hoc 签名，尚未经过 Apple 公证。",
    windowsWarning: "当前未代码签名，需使用 Apple 官网版 iTunes 与 iCloud。",
    advancedDownload: "高级下载",
    ipaNote: "未签名的 Classic 安装包，供 AltForge Server 或其他兼容签名工具使用，不能在 iPhone 上直接打开安装。",
    downloadIpa: "下载 IPA",
    workflowEyebrow: "经典侧载流程",
    workflowTitle: "三步完成安装",
    workflowIntro: "Server 在你的电脑上连接 Apple 开发者服务，并针对所选设备完成签名。AltForge 不代理账号，也不收集凭据。",
    stepOneTitle: "安装并打开 Server",
    stepOneBody: "macOS 将 App 拖入“应用程序”；Windows 解压完整 ZIP 后运行。",
    stepTwoTitle: "连接并信任设备",
    stepTwoBody: "使用 USB，或确保电脑与设备在同一 Wi-Fi，并在设备上选择信任。",
    stepThreeTitle: "安装 AltForge",
    stepThreeBody: "从菜单选择设备并登录 Apple ID，Server 会下载官方 IPA、签名并安装。",
    featuresEyebrow: "为什么选择 AltForge",
    featuresTitle: "维护真实问题，不重造侧载流程",
    featureUnicodeTitle: "Unicode 兼容",
    featureUnicodeBody: "保留中文显示名与资源路径，ZIP 路径在使用前经过安全校验。",
    featureLanguageTitle: "原生双语",
    featureLanguageBody: "iOS 应用与 macOS Server 支持 English 和简体中文。",
    featureProgressTitle: "安装过程可见",
    featureProgressBody: "清晰显示下载、认证、签名和设备安装阶段，并保留脱敏诊断。",
    featureOpenTitle: "开源可追溯",
    featureOpenBody: "源码、Release、校验和、版本历史与已知限制都在同一仓库。",
    faqEyebrow: "安装前须知",
    faqTitle: "常见问题",
    faqIntro: "签名、账号与系统安全提示都有明确边界。遇到问题时，请优先核对 Release 与脱敏诊断。",
    faqDirectQuestion: "可以直接在 iPhone 上安装 IPA 吗？",
    faqDirectAnswer: "不可以。IPA 需要针对你的 Apple ID、开发团队和设备重新签名，因此必须使用电脑端 AltForge Server 或其他兼容签名工具。",
    faqSafetyQuestion: "为什么系统会提示无法验证开发者？",
    faqSafetyAnswer: "当前 macOS DMG 未使用 Developer ID 签名和 Apple 公证，Windows ZIP 也未代码签名。请只从本仓库 Release 下载，并在需要时核对 SHA-256。",
    faqAppleIdQuestion: "Apple ID 会上传到 AltForge 吗？",
    faqAppleIdAnswer: "AltForge Server 使用 Apple ID 与 Apple 开发者服务完成签名。仓库不会收集账号；保存密码是可选的，并仅存入本机钥匙串。",
    faqRefreshQuestion: "免费账号为什么需要每 7 天刷新？",
    faqRefreshAnswer: "免费开发团队签发的 App 通常只有 7 天有效期。保持设备与 AltForge Server 在同一网络，可在到期前刷新。",
    allReleases: "全部版本",
    allReleasesNote: "发布说明与校验和",
    documentation: "使用文档",
    documentationNote: "完整说明与构建指南",
    reportIssue: "报告问题",
    reportIssueNote: "附上脱敏诊断报告",
    footerDescription: "由 AltForge Contributors 维护，基于 AltStore 团队的开源工作。",
    upstream: "上游项目",
    independent: "独立的 AltStore 衍生项目",
    noscript: "JavaScript 仅用于语言、平台识别和版本显示；所有下载链接仍然可以直接使用。"
  },
  en: {
    skip: "Skip to main content",
    navDownload: "Download",
    navWorkflow: "Workflow",
    navHelp: "Help",
    heroKicker: "OPEN-SOURCE ALTSTORE CLASSIC MAINTENANCE",
    heroLede: "A more reliable Classic sideloading tool, maintained for Unicode apps, international users, and modern Apple platforms.",
    latestFallback: "Latest",
    latestRelease: "Latest release",
    iosRequirement: "Requires iOS 17.4+",
    downloadRelease: "Download latest release",
    downloadMac: "Download for macOS",
    downloadWindows: "Download for Windows",
    viewSource: "View source",
    downloadNote: "We select the desktop server for your computer automatically. You can also choose a platform below.",
    downloadMacNote: "Mac detected. Download the Universal DMG, or choose another platform below.",
    downloadWindowsNote: "Windows detected. Download the portable ZIP, or choose another platform below.",
    heroNext: "Release and source",
    repositoryLabel: "Official repository",
    repositoryCode: "Source code",
    repositoryCodeNote: "Public and auditable",
    integrity: "Integrity",
    license: "License",
    downloadEyebrow: "DESKTOP INSTALLATION SERVER",
    downloadTitle: "Choose your computer",
    downloadIntro: "AltForge uses a desktop Server for authentication, signing, and device installation. Every file comes directly from this repository's latest Release.",
    recommended: "Recommended",
    macDescription: "Universal DMG for Apple silicon and Intel Macs.",
    windowsDescription: "Portable Win32 build with the required runtime DLLs.",
    downloadDmg: "Download DMG",
    downloadZip: "Download ZIP",
    macWarning: "Currently ad-hoc signed and not notarized by Apple.",
    windowsWarning: "Currently unsigned. Requires Apple's desktop iTunes and iCloud.",
    advancedDownload: "ADVANCED DOWNLOAD",
    ipaNote: "This unsigned Classic package is for AltForge Server or another compatible signing tool. It cannot be installed by opening it on an iPhone.",
    downloadIpa: "Download IPA",
    workflowEyebrow: "CLASSIC SIDELOADING WORKFLOW",
    workflowTitle: "Install in three steps",
    workflowIntro: "Server connects to Apple developer services on your computer and signs for the selected device. AltForge does not proxy accounts or collect credentials.",
    stepOneTitle: "Install and open Server",
    stepOneBody: "On macOS, drag the app to Applications. On Windows, extract the complete ZIP and run it.",
    stepTwoTitle: "Connect and trust",
    stepTwoBody: "Use USB, or keep both devices on the same Wi-Fi, then trust the computer on your device.",
    stepThreeTitle: "Install AltForge",
    stepThreeBody: "Choose your device and sign in. Server downloads the official IPA, signs it, and installs it.",
    featuresEyebrow: "WHY ALTFORGE",
    featuresTitle: "Maintain real problems, not another sideloading stack",
    featureUnicodeTitle: "Unicode compatible",
    featureUnicodeBody: "Keep Chinese display names and resource paths. ZIP paths are validated before use.",
    featureLanguageTitle: "Native bilingual UI",
    featureLanguageBody: "The iOS app and macOS Server support English and Simplified Chinese.",
    featureProgressTitle: "Visible installation",
    featureProgressBody: "See download, authentication, signing, and device stages with sanitized diagnostics on failure.",
    featureOpenTitle: "Open and traceable",
    featureOpenBody: "Source, releases, checksums, version history, and known limitations live in one repository.",
    faqEyebrow: "BEFORE YOU INSTALL",
    faqTitle: "Common questions",
    faqIntro: "Signing, account use, and system warnings have explicit boundaries. Check the Release and sanitized diagnostics first when something fails.",
    faqDirectQuestion: "Can I install the IPA directly on my iPhone?",
    faqDirectAnswer: "No. The IPA must be signed for your Apple ID, developer team, and device, so you need AltForge Server or another compatible signing tool on a computer.",
    faqSafetyQuestion: "Why does my system warn about an unidentified developer?",
    faqSafetyAnswer: "The current macOS DMG is not Developer ID signed or notarized, and the Windows ZIP is unsigned. Download only from this repository's Releases and verify SHA-256 when needed.",
    faqAppleIdQuestion: "Does AltForge upload my Apple ID?",
    faqAppleIdAnswer: "AltForge Server uses it with Apple's developer services to sign apps. This repository does not collect accounts. Saving a password is optional and uses the local Keychain only.",
    faqRefreshQuestion: "Why do free accounts need a refresh every seven days?",
    faqRefreshAnswer: "Apps signed by a free developer team generally expire after seven days. Keep your device and AltForge Server on the same network to refresh before expiry.",
    allReleases: "All releases",
    allReleasesNote: "Release notes and checksums",
    documentation: "Documentation",
    documentationNote: "Full guide and build instructions",
    reportIssue: "Report an issue",
    reportIssueNote: "Attach a sanitized diagnostic report",
    footerDescription: "Maintained by AltForge Contributors and based on the AltStore team's open-source work.",
    upstream: "Upstream",
    independent: "Independent AltStore derivative",
    noscript: "JavaScript is used only for language, platform detection, and release display. All download links still work directly."
  }
};

const languageButton = document.querySelector("[data-language-switch]");
let storedLanguage;

try {
  storedLanguage = localStorage.getItem("altforge-language");
} catch (_) {
  storedLanguage = null;
}

let language = storedLanguage || (navigator.language.toLowerCase().startsWith("zh") ? "zh-Hans" : "en");

function detectedPlatform() {
  const userAgent = navigator.userAgent.toLowerCase();
  if (["iphone", "ipad", "ipod", "android"].some((device) => userAgent.includes(device))) return "other";
  if (userAgent.includes("windows")) return "windows";
  if (userAgent.includes("macintosh")) return "mac";

  const platform = `${navigator.userAgentData?.platform || ""} ${navigator.platform || ""}`.toLowerCase();
  if (platform.includes("mac")) return "mac";
  if (platform.includes("win")) return "windows";
  return "other";
}

function configurePrimaryDownload() {
  const platform = detectedPlatform();
  const button = document.querySelector("[data-primary-download]");
  const label = document.querySelector("[data-primary-label]");
  const note = document.querySelector("[data-primary-note]");

  document.querySelectorAll("[data-platform]").forEach((row) => {
    row.classList.toggle("is-recommended", row.dataset.platform === platform);
  });

  if (platform === "mac") {
    button.href = `${releaseBase}/AltForge-AltServer-macOS.dmg`;
    label.textContent = copy[language].downloadMac;
    note.textContent = copy[language].downloadMacNote;
  } else if (platform === "windows") {
    button.href = `${releaseBase}/AltForge-AltServer-Windows.zip`;
    label.textContent = copy[language].downloadWindows;
    note.textContent = copy[language].downloadWindowsNote;
  } else {
    button.href = `${repository}/releases/latest`;
    label.textContent = copy[language].downloadRelease;
    note.textContent = copy[language].downloadNote;
  }
}

function applyLanguage(nextLanguage) {
  language = copy[nextLanguage] ? nextLanguage : "en";
  document.documentElement.lang = language;
  document.querySelectorAll("[data-i18n]").forEach((element) => {
    const value = copy[language][element.dataset.i18n];
    if (value) element.textContent = value;
  });
  languageButton.textContent = language === "zh-Hans" ? "EN" : "中";
  languageButton.setAttribute("aria-label", language === "zh-Hans" ? "Switch to English" : "切换到简体中文");
  document.querySelector("[data-doc-link]").href = `${repository}/blob/marketplace/${language === "zh-Hans" ? "README.zh-CN.md" : "README.md"}`;
  document.title = language === "zh-Hans" ? "AltForge · 持续维护的经典侧载工具" : "AltForge · Classic sideloading, thoughtfully maintained";
  try {
    localStorage.setItem("altforge-language", language);
  } catch (_) {
    // Language switching still works when storage is unavailable.
  }
  configurePrimaryDownload();
}

async function loadReleaseVersion() {
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), 8000);
  try {
    const response = await fetch(latestReleaseAPI, {
      cache: "no-store",
      headers: { Accept: "application/vnd.github+json" },
      signal: controller.signal
    });
    if (!response.ok) throw new Error(`Release metadata returned ${response.status}`);
    const release = await response.json();
    const version = release?.tag_name?.replace(/^v/, "");
    if (!/^\d+\.\d+\.\d+$/.test(version || "")) throw new Error("Release metadata has no valid version");
    document.querySelectorAll("[data-release-version]").forEach((element) => {
      element.textContent = version;
    });
  } catch (error) {
    console.info("Showing the generic latest-release label because live metadata is unavailable.", error);
  } finally {
    window.clearTimeout(timeout);
  }
}

function configureMotion() {
  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches || !("IntersectionObserver" in window)) return;

  const revealGroups = [
    ".section-heading",
    ".platform-row",
    ".advanced-download",
    ".steps li",
    ".feature-intro",
    ".feature-grid article",
    ".faq-list details",
    ".support-links a",
    ".footer-brand",
    ".footer-links"
  ];
  const elements = document.querySelectorAll(revealGroups.join(","));
  document.documentElement.classList.add("motion-enhanced");

  elements.forEach((element, index) => {
    element.dataset.reveal = "";
    element.classList.add(`reveal-delay-${index % 4}`);
  });

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add("is-visible");
      observer.unobserve(entry.target);
    });
  }, { rootMargin: "0px 0px -8%", threshold: 0.12 });

  elements.forEach((element) => observer.observe(element));
}

languageButton.addEventListener("click", () => applyLanguage(language === "zh-Hans" ? "en" : "zh-Hans"));
applyLanguage(language);
configureMotion();
loadReleaseVersion();
