#!/usr/bin/env ruby

require "json"
require "uri"

root = File.expand_path("..", __dir__)

def read(root, path)
  File.read(File.join(root, path))
end

def assert(condition, message)
  raise message unless condition
end

def png_dimensions(root, path)
  data = File.binread(File.join(root, path), 24)
  raise "#{path} is not a PNG" unless data.start_with?("\x89PNG\r\n\x1a\n".b)

  data.byteslice(16, 8).unpack("NN")
end

workflow = read(root, ".github/workflows/release.yml")
workflow_names = Dir.children(File.join(root, ".github/workflows")).select { |name| name.end_with?(".yml", ".yaml") }.sort
assert(workflow_names == ["release.yml"], "only the tag-driven release workflow may be enabled")
assert(workflow.include?("tags:\n      - \"v*\""), "release workflow must remain tag-only")
assert(!workflow.match?(/^\s*pull_request:/), "release workflow must not run for pull requests")
assert(!workflow.match?(/^\s*branches:/), "release workflow must not run for branch pushes")
assert(workflow.include?("--draft"), "release workflow must create a draft release")
assert(workflow.include?("vcpkg_baseline: ${{ steps.version.outputs.vcpkg_baseline }}"), "prepare must expose the manifest vcpkg baseline")
assert(workflow.include?("ref: ${{ needs.prepare.outputs.vcpkg_baseline }}"), "Windows must check out the manifest vcpkg baseline")

windows_build = read(root, "AltServer-Windows/Scripts/build-release.ps1")
assert(windows_build.include?("/DLOG_ERR=kDebugLevelError"), "Windows mDNSResponder build must define the missing LOG_ERR priority")
assert(windows_build.include?("SetEnvironmentVariable(\"CL\", $previousCompilerOptions"), "Windows mDNSResponder compiler options must be restored")
assert(windows_build.include?("/DNOMINMAX /DOPENSSL_SUPPRESS_DEPRECATED"), "Windows solution build must isolate Windows macros and permit reviewed OpenSSL compatibility APIs")
assert(windows_build.include?("SetEnvironmentVariable(\"CL\", $previousSolutionCompilerOptions"), "Windows solution compiler options must be restored")

windows_targets = read(root, "AltServer-Windows/Directory.Build.targets")
assert(windows_targets.include?("Dependencies\\dirent\\include"), "Windows projects must receive the pinned dirent include path")

release_assets = %w[
  AltForge.ipa
  AltForge-AltServer-macOS.dmg
  AltForge-AltServer-Windows.zip
  apps.json
  flags.json
  sources.json
  recommended-sources.json
  developerdisks.json
  SHA256SUMS.txt
]
release_assets.each do |asset|
  assert(workflow.include?(asset), "release workflow does not publish #{asset}")
end
assert(workflow.include?("Scripts/package_macos_dmg.sh"), "release workflow must use the reviewed DMG packager")
assert(workflow.include?("Scripts/verify_apple_release_artifacts.sh"), "release workflow must verify packaged Apple artifacts")
assert(workflow.include?("sha256sum --check SHA256SUMS.txt"), "release workflow must verify generated checksums before creating the Draft")

dmg_packager = read(root, "Scripts/package_macos_dmg.sh")
assert(dmg_packager.include?("hdiutil create"), "DMG packager must use the macOS disk image utility")
assert(dmg_packager.include?('staged_app="$staging_root/AltForge Server.app"'), "DMG must present the public AltForge Server application name")
assert(dmg_packager.include?("ln -s /Applications"), "DMG packager must include an Applications shortcut")
assert(dmg_packager.include?("hdiutil verify"), "DMG packager must verify the generated image")

apple_artifact_verifier = read(root, "Scripts/verify_apple_release_artifacts.sh")
assert(apple_artifact_verifier.include?('Payload/AltStore.app/Info.plist'), "Apple artifact verifier must inspect the IPA payload")
assert(apple_artifact_verifier.include?('AltForge Server.app'), "Apple artifact verifier must inspect the public macOS bundle")
assert(apple_artifact_verifier.include?('lipo -archs'), "Apple artifact verifier must enforce the Universal macOS architecture contract")
assert(apple_artifact_verifier.include?('Signature=adhoc'), "Apple artifact verifier must recognize Xcode linker ad-hoc signatures")
assert(apple_artifact_verifier.include?('TeamIdentifier=not set'), "Apple artifact verifier must reject an unexpected signing team")
assert(apple_artifact_verifier.include?('outside the reviewed ad-hoc/unsigned signing policy'), "Apple artifact verifier must enforce the current non-Developer-ID release policy")

info_plist = read(root, "AltServer/Info.plist")
assert(info_plist.include?("<key>CFBundleDisplayName</key>\n\t<string>AltForge Server</string>"), "macOS public application name must be AltForge Server")
assert(info_plist.include?("Copyright © 2026 AltForge contributors."), "AltForge contributor copyright is missing")
assert(info_plist.include?("AltStore and AltServer © Riley Testut and contributors."), "upstream copyright attribution is missing")

storyboard = read(root, "AltServer/Base.lproj/Main.storyboard")
%w[About\ AltForge\ Server Quit\ AltForge\ Server Settings… Check\ for\ Updates… Remove\ Legacy\ Mail\ Plug-in…].each do |title|
  assert(storyboard.include?("title=\"#{title.gsub('\\ ', ' ')}\""), "macOS menu is missing #{title.gsub('\\ ', ' ')}")
end
assert(!storyboard.include?('title="About AltServer"'), "macOS About menu still uses the upstream public name")
assert(!storyboard.include?('title="Quit AltServer"'), "macOS Quit menu still uses the upstream public name")

app_delegate = read(root, "AltServer/AppDelegate.swift")
assert(app_delegate.include?('NSLocalizedString("%@ (%@)"'), "device menu must include a connection label")
assert(app_delegate.include?("ALTDeviceManager.shared.connectedDevices"), "device menu must distinguish USB devices")
assert(app_delegate.include?('request.timeoutInterval = 10'), "update request must have a finite timeout")
assert(app_delegate.include?('data.count <= 1_048_576'), "update response must have a size bound")
assert(app_delegate.include?('release.htmlURL.host == "github.com"'), "update release URL must validate the GitHub host")
assert(app_delegate.include?("SettingsWindowController"), "macOS settings entry is missing")

plugin_manager = read(root, "AltServer/Plugin/PluginManager.swift")
assert(plugin_manager.include?('NSLocalizedString("Remove Legacy Mail Plug-in"'), "legacy Mail plug-in action needs a clear title")
assert(plugin_manager.include?('NSLocalizedString("Remove Plug-in"'), "legacy Mail plug-in confirmation needs a clear command")
assert(!plugin_manager.match?(%r{https?://}), "legacy Mail plug-in manager must not access an update or download service")
assert(!plugin_manager.include?("URLSession"), "legacy Mail plug-in manager must remain uninstall-only")

settings = read(root, "AltServer/SettingsWindowController.swift")
assert(settings.include?('case simplifiedChinese'), "macOS settings must expose Simplified Chinese")
assert(settings.include?('UserDefaults.standard.set([identifier], forKey: "AppleLanguages")'), "macOS language preference is not persisted")
assert(settings.include?("LaunchAtLogin.isEnabled"), "macOS settings must expose launch at login")

menu_icon_catalog = JSON.parse(read(root, "AltServer/Assets.xcassets/MenuBarIcon.imageset/Contents.json"))
assert(menu_icon_catalog.dig("properties", "template-rendering-intent") == "template", "menu bar icon must use template rendering")
assert(png_dimensions(root, "AltServer/Assets.xcassets/MenuBarIcon.imageset/MenuBar@19.png") == [19, 19], "1x menu bar icon dimensions are incorrect")
assert(png_dimensions(root, "AltServer/Assets.xcassets/MenuBarIcon.imageset/MenuBar@38.png") == [38, 38], "2x menu bar icon dimensions are incorrect")

app_icon_catalog = JSON.parse(read(root, "AltServer/Assets.xcassets/AppIcon.appiconset/Contents.json"))
app_icon_catalog.fetch("images").each do |entry|
  filename = entry["filename"]
  assert(filename, "every macOS AppIcon slot must name a file")
  points = entry.fetch("size").split("x").first.to_f
  scale = entry.fetch("scale").delete_suffix("x").to_i
  expected_pixels = (points * scale).to_i
  path = "AltServer/Assets.xcassets/AppIcon.appiconset/#{filename}"
  assert(png_dimensions(root, path) == [expected_pixels, expected_pixels], "incorrect AppIcon dimensions for #{filename}")
end

desktop_strings = JSON.parse(read(root, "AltServer/Resources/Localizable.xcstrings")).fetch("strings")
%w[AltForge\ Server AltForge\ Server\ Settings Check\ for\ Updates… Remove\ Plug-in USB Wi-Fi].each do |key|
  localized_key = key.gsub('\\ ', ' ')
  assert(desktop_strings.dig(localized_key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese desktop string: #{localized_key}")
end
%w[AltServer\ Running Uninstall\ Mail\ Plug-in Uninstall\ Plug-in].each do |key|
  stale_key = key.gsub('\\ ', ' ')
  assert(!desktop_strings.key?(stale_key), "stale macOS public string remains: #{stale_key}")
end
credits_key = "AltForge Server is maintained by the AltForge contributors and builds on the AltStore and pymobiledevice3 communities. AltForge is distributed under the GNU AGPL v3.0 license."
assert(desktop_strings.key?(credits_key), "About credits must use project/community attribution")
assert(!app_delegate.include?("Thanks to"), "About credits must not single out an individual thank-you")

windows_menu = read(root, "AltServer-Windows/AltServer/AltServer.cpp")
assert(windows_menu.include?('L"Check for Updates..."'), "Windows menu must use a clear update-check label")
assert(windows_menu.include?('L" (USB)" : L" (Wi-Fi)"'), "Windows device menus must show USB/Wi-Fi connection type")
windows_app = read(root, "AltServer-Windows/AltServer/AltServerApp.cpp")
assert(windows_app.include?('"AltForge Server Running"'), "Windows notification must use the public server name")
windows_resources = read(root, "AltServer-Windows/AltServer/Resource.rc")
assert(windows_resources.include?('VALUE "ProductName", "AltForge Server"'), "Windows product metadata must use the public server name")
assert(windows_resources.include?("AltStore and AltServer (C) Riley Testut and contributors"), "Windows metadata must retain upstream copyright attribution")

flags = JSON.parse(read(root, "Release/flags.json"))
sources = JSON.parse(read(root, "Release/sources.json"))
collections = JSON.parse(read(root, "Release/recommended-sources.json"))
developer_disks = JSON.parse(read(root, "Release/developerdisks.json"))
assert(flags == {"version" => 1, "flags" => {}}, "flags.json must use a safe empty default")
assert(collections == {"version" => 1, "collections" => []}, "recommended-sources.json must use a safe empty default")
assert(sources["version"] == 1 && sources["blocked"] == [], "sources.json must use version 1 with no blocked sources")
trusted_source = sources.fetch("trusted").fetch(0)
assert(trusted_source["sourceURL"] == "https://github.com/legeling/AltForge/releases/latest/download/apps.json", "trusted source must point to AltForge releases")
assert(trusted_source["bundleIDs"] == ["com.legeling.AltForge"], "trusted source bundle identifier is incorrect")

assert(developer_disks["version"] == 1, "developerdisks.json must use schema version 1")
disk_groups = developer_disks.fetch("disks")
assert(!disk_groups.empty?, "developerdisks.json must contain at least one platform")
allowed_disk_hosts = %w[github.com raw.githubusercontent.com]
disk_groups.each do |platform, versions|
  assert(%w[iOS tvOS].include?(platform), "unsupported Developer Disk platform #{platform}")
  assert(versions.is_a?(Hash) && !versions.empty?, "Developer Disk platform #{platform} must contain versions")

  versions.each do |version, entry|
    assert(version.match?(/\A\d+\.\d+\z/), "invalid Developer Disk version #{version}")
    assert(entry.is_a?(Hash), "Developer Disk entry #{platform} #{version} must be an object")
    keys = entry.keys.sort
    assert(keys == ["archive"] || keys == %w[disk signature], "Developer Disk entry #{platform} #{version} must use archive or disk + signature")

    entry.each_value do |value|
      uri = URI.parse(value)
      assert(uri.scheme == "https", "Developer Disk URL must use HTTPS: #{value}")
      assert(allowed_disk_hosts.include?(uri.host), "Developer Disk URL host is not reviewed: #{value}")
    rescue URI::InvalidURIError
      raise "invalid Developer Disk URL: #{value}"
    end
  end
end

classic_endpoints = {
  "AltStore/Operations/UpdateRemoteFlagsOperation.swift" => "https://github.com/legeling/AltForge/releases/latest/download/flags.json",
  "AltStore/Operations/UpdateKnownSourcesOperation.swift" => "https://github.com/legeling/AltForge/releases/latest/download/sources.json",
  "AltStore/Operations/FetchSourceCollectionsOperation.swift" => "https://github.com/legeling/AltForge/releases/latest/download/recommended-sources.json",
  "AltServer/DeveloperDiskManager.swift" => "https://github.com/legeling/AltForge/releases/latest/download/developerdisks.json",
  "AltServer-Windows/AltServer/DeveloperDiskManager.cpp" => "/legeling/AltForge/releases/latest/download/developerdisks.json"
}
classic_endpoints.each do |path, endpoint|
  assert(read(root, path).include?(endpoint), "#{path} does not use the AltForge release endpoint")
end

owned_control_files = classic_endpoints.keys + [
  "AltStore/Operations/UpdatePatronsOperation.swift",
  "AltServer/Plugin/PluginManager.swift",
  "AltStoreCore/Patreon/PatreonAPI.swift"
]
forbidden_control_hosts = %w[cdn.altstore.io f000.backblazeb2.com rileytestut.com/patreon/altstore]
owned_control_files.each do |path|
  contents = read(root, path)
  forbidden_control_hosts.each do |host|
    assert(!contents.include?(host), "#{path} still depends on upstream control endpoint #{host}")
  end
end

update_patrons = read(root, "AltStore/Operations/UpdatePatronsOperation.swift")
assert(!update_patrons.include?("URLSession"), "AltForge must not fetch the upstream creator patron list")

patreon_api = read(root, "AltStoreCore/Patreon/PatreonAPI.swift")
patreon_plist = read(root, "AltStoreCore/Resources/PatreonAPI.plist")
ios_settings = read(root, "AltStore/Settings/SettingsViewController.swift")
assert(patreon_plist.include?("<key>redirectURI</key>"), "Patreon configuration must declare an explicit redirect URI")
assert(patreon_api.include?("public var isConfigured"), "Patreon integration must expose its configured state")
assert(patreon_api.include?("PatreonAPIError(.notConfigured)"), "Patreon integration must expose a fail-closed configuration error")
assert(read(root, "AltStore/Operations/VerifyAppPledgeOperation.swift").include?("PatreonAPI.shared.notConfiguredError"), "pledge verification must fail closed before Patreon network access")
assert(patreon_api.include?('url.scheme?.lowercased() == "https"'), "Patreon redirect URI must require HTTPS")
assert(ios_settings.include?("case .patreon: return !PatreonAPI.shared.isConfigured"), "unconfigured Patreon UI must be hidden")

project = read(root, "AltStore.xcodeproj/project.pbxproj")
assert(!project.include?("MARKETPLACE"), "Classic release project must not define the MARKETPLACE compilation condition")

fetch_source = read(root, "AltStore/Operations/FetchSourceOperation.swift")
federation_manager = read(root, "AltStore/Fediverse/FederationManager.swift")
mastodon_api = read(root, "AltStore/Fediverse/MastodonAPI.swift")
bluesky_api = read(root, "AltStore/Fediverse/BlueskyAPI.swift")
app_manager = read(root, "AltStore/Managing Apps/AppManager.swift")
user_defaults = read(root, "AltStoreCore/Extensions/UserDefaults+AltStore.swift")
classic_federation_guard = "#if !MARKETPLACE\n        // AltForge Classic does not use upstream federation control services."
assert(fetch_source.include?(classic_federation_guard), "Classic source updates must not contact upstream federation metadata services")
assert(federation_manager.include?(classic_federation_guard), "Classic interaction updates must not contact upstream federation services")
assert(mastodon_api.include?(classic_federation_guard + "\n        throw URLError(.unsupportedURL)"), "Classic Mastodon transport must fail before network access")
assert(bluesky_api.include?(classic_federation_guard + "\n        throw URLError(.unsupportedURL)"), "Classic Bluesky transport must fail before network access")
assert(app_manager.include?("#if !MARKETPLACE\n        // Avoid loading interaction records when federation is unavailable."), "Classic launch must not schedule federation update operations")
assert(user_defaults.include?("#if MARKETPLACE\n    @NSManaged var fediverseInteractionsDisabled: Bool\n    #else\n    var fediverseInteractionsDisabled: Bool { true }"), "Classic UI must keep federation interactions disabled")

assert(read(root, "AltStoreCore/Model/DatabaseManager.swift").include?("let storeBuildVersion = localApp.buildVersion"), "AltForge build version must be persisted for update comparisons")
assert(read(root, "AltStoreCore/Model/Source.swift").include?('source.name = "AltForge"'), "offline source identity must be AltForge")
assert(read(root, "AltStoreCore/Model/StoreApp.swift").include?('app.name = "AltForge"'), "offline app identity must be AltForge")

patreon_screen = read(root, "AltStore/Settings/PatreonViewController.swift")
assert(patreon_screen.include?("#if MARKETPLACE"), "upstream Patreon campaign UI must remain outside the Classic build")
assert(patreon_screen.include?("AltForge does not operate a Patreon campaign."), "Classic Patreon compatibility disclosure is missing")
assert(patreon_screen.include?("headerView.supportButton.isHidden = true"), "Classic build must hide the upstream support button")

user_facing_files = %w[
  AltStore/Settings/SettingsViewController.swift
  AltStore/SceneDelegate.swift
  AltStore/Settings/Error\ Log/ErrorLogViewController.swift
  AltServer/AppDelegate.swift
  AltServer/ErrorDetailsViewController.swift
  AltServer-Windows/AltServer/AltServerApp.cpp
  Shared/Errors/JITError.swift
]
forbidden_urls = %w[
  https://faq.altstore.io
  https://altstore.io/privacy-policy
  https://github.com/altstoreio/AltStore/issues
  https://github.com/rileytestut
]
user_facing_files.each do |path|
  contents = read(root, path)
  forbidden_urls.each do |url|
    assert(!contents.include?(url), "#{path} still exposes upstream support URL #{url}")
  end
end

puts "repository release policy contract passed"
