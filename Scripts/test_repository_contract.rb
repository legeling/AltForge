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
assert(windows_targets.include?("cpprest_2_10.lib;libssl.lib;libcrypto.lib;z.lib;"), "Windows AltServer must link its vcpkg runtime import libraries")

windows_packager = read(root, "AltServer-Windows/Scripts/package-release.ps1")
assert(windows_packager.include?('"z.dll"'), "Windows package must require the zlib 1.3.2 runtime DLL")
assert(!windows_packager.include?('"zlib1.dll"'), "Windows package must not require the legacy zlib runtime name")

%w[WiredConnection.cpp WirelessConnection.cpp].each do |name|
  connection = read(root, "AltServer-Windows/AltServer/#{name}")
  assert(connection.include?("#include <algorithm>"), "#{name} must include the standard min implementation")
  assert(connection.include?("std::min("), "#{name} must not depend on the Windows min macro")
end

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
assert(workflow.match?(/package_macos_dmg\.sh.*?--ad-hoc-sign/m), "release workflow must seal the full app bundle for ServiceManagement login items")
assert(workflow.include?("Scripts/verify_apple_release_artifacts.sh"), "release workflow must verify packaged Apple artifacts")
assert(workflow.include?("sha256sum --check SHA256SUMS.txt"), "release workflow must verify generated checksums before creating the Draft")
assert(workflow.match?(/gh release create "\$GITHUB_REF_NAME".*?--repo "\$GITHUB_REPOSITORY"/m), "Draft creation must identify the repository after entering the artifact directory")

dmg_packager = read(root, "Scripts/package_macos_dmg.sh")
assert(dmg_packager.include?("hdiutil create"), "DMG packager must use the macOS disk image utility")
assert(dmg_packager.include?('staged_app="$staging_root/AltForge Server.app"'), "DMG must present the public AltForge Server application name")
assert(dmg_packager.include?("ln -s /Applications"), "DMG packager must include an Applications shortcut")
assert(dmg_packager.include?("hdiutil verify"), "DMG packager must verify the generated image")

apple_artifact_verifier = read(root, "Scripts/verify_apple_release_artifacts.sh")
assert(apple_artifact_verifier.include?('Payload/AltStore.app/Info.plist'), "Apple artifact verifier must inspect the IPA payload")
assert(apple_artifact_verifier.include?('AltForge Server.app'), "Apple artifact verifier must inspect the public macOS bundle")
assert(apple_artifact_verifier.include?('lipo -archs'), "Apple artifact verifier must enforce the Universal macOS architecture contract")
assert(apple_artifact_verifier.include?('codesign --verify --deep --strict'), "Apple artifact verifier must reject an incomplete linker-only app signature")
assert(apple_artifact_verifier.include?('Signature=adhoc'), "Apple artifact verifier must recognize Xcode linker ad-hoc signatures")
assert(apple_artifact_verifier.include?('TeamIdentifier=not set'), "Apple artifact verifier must reject an unexpected signing team")
assert(apple_artifact_verifier.include?('outside the reviewed ad-hoc signing policy'), "Apple artifact verifier must enforce the current non-Developer-ID release policy")

info_plist = read(root, "AltServer/Info.plist")
assert(info_plist.include?("<key>CFBundleDisplayName</key>\n\t<string>AltForge Server</string>"), "macOS public application name must be AltForge Server")
assert(info_plist.include?("Copyright © 2026 AltForge contributors."), "AltForge contributor copyright is missing")
assert(info_plist.include?("AltStore and AltServer © Riley Testut and contributors."), "upstream copyright attribution is missing")

storyboard = read(root, "AltServer/Base.lproj/Main.storyboard")
%w[About\ AltForge\ Server Quit\ AltForge\ Server Settings Language System\ Default English Simplified\ Chinese Check\ for\ Updates… Remove\ Legacy\ Mail\ Plug-in…].each do |title|
  assert(storyboard.include?("title=\"#{title.gsub('\\ ', ' ')}\""), "macOS menu is missing #{title.gsub('\\ ', ' ')}")
end
assert(!storyboard.include?('title="About AltServer"'), "macOS About menu still uses the upstream public name")
assert(!storyboard.include?('title="Quit AltServer"'), "macOS Quit menu still uses the upstream public name")
assert(!storyboard.include?('systemMenu="recentDocuments"'), "device submenus must not use the Recent Documents clock icon")

app_delegate = read(root, "AltServer/AppDelegate.swift")
assert(app_delegate.include?('NSLocalizedString("%@ (%@)"'), "device menu must include a connection label")
assert(app_delegate.include?("ALTDeviceManager.shared.connectedDevices"), "device menu must distinguish USB devices")
assert(app_delegate.include?('request.timeoutInterval = 10'), "update request must have a finite timeout")
assert(app_delegate.include?('data.count <= 1_048_576'), "update response must have a size bound")
assert(app_delegate.include?('release.htmlURL.host == "github.com"'), "update release URL must validate the GitHub host")
assert(app_delegate.include?('systemSymbolName: "arrow.down.app"'), "Install AltForge must use an install icon")
assert(app_delegate.include?('case simplifiedChinese'), "macOS settings menu must expose Simplified Chinese")
assert(app_delegate.include?('UserDefaults.standard.set([identifier], forKey: "AppleLanguages")'), "macOS language preference is not persisted")
assert(app_delegate.include?("LaunchAtLogin.isEnabled"), "macOS settings menu must expose launch at login")
assert(app_delegate.include?("SMAppService.mainApp"), "macOS 13+ launch-at-login must use the current ServiceManagement API")
assert(app_delegate.include?("case .requiresApproval"), "launch-at-login must expose system approval state")
assert(app_delegate.include?("try service.register()") && app_delegate.include?("try service.unregister()"), "launch-at-login must report registration failures instead of silently toggling")
assert(app_delegate.include?("Restart AltForge Server to apply the selected language."), "language selection must explain that a restart is required")
assert(app_delegate.include?("ALT_FORGE_RELAUNCH_PATH"), "language selection must offer an immediate bounded relaunch")
assert(app_delegate.include?("UserDefaults.standard.synchronize()"), "language preference must reach disk before the immediate relaunch terminates the process")
assert(!File.exist?(File.join(root, "AltServer/SettingsWindowController.swift")), "macOS settings must remain in the status menu instead of a separate window")
assert(app_delegate.include?('(self.settingsMenuItem, "gearshape")'), "macOS Settings must have a leading gear icon")
assert(app_delegate.include?('(self.checkForUpdatesMenuItem, "arrow.clockwise")'), "macOS Check for Updates must have a leading refresh icon")

authentication_ui = read(root, "AltServer/AppleIDAuthenticationWindowController.swift")
assert(authentication_ui.include?("NSPopover"), "Apple ID authentication must expose a dedicated saved-account picker")
assert(authentication_ui.include?('NSLocalizedString("Saved Accounts"'), "saved account selection must have a localized heading")
assert(authentication_ui.include?('checkboxWithTitle: NSLocalizedString("Remember password"'), "Apple ID authentication must expose password persistence consent")
assert(authentication_ui.include?('systemSymbolName: symbolName'), "Apple ID authentication must provide password visibility controls")
assert(authentication_ui.include?("NSEvent.addLocalMonitorForEvents(matching: .flagsChanged)"), "Apple ID authentication must monitor Caps Lock")
assert(authentication_ui.include?('NSLocalizedString("Caps Lock is on."'), "Apple ID authentication must warn when Caps Lock is enabled")
assert(authentication_ui.include?("runModal(submissionHandler:"), "Apple ID authentication must remain open while a sign-in attempt runs")
assert(authentication_ui.include?("authenticationDidFail(message:"), "Apple ID authentication must restore the editable form after failure")
assert(authentication_ui.include?("self.submissionHandler?(submission)"), "Apple ID authentication must submit without closing the window")
assert(authentication_ui.include?(".miniaturizable"), "Apple ID authentication must allow users to minimize the window")
assert(!authentication_ui.include?("standardWindowButton(.miniaturizeButton)?.isHidden = true"), "Apple ID authentication must keep the native minimize control visible")
assert(authentication_ui.include?("if let localizedKind = account.kind.localizedName"), "saved Apple ID picker must display verified team types")
assert(!authentication_ui.include?("accountKindBadge"), "verified team types must not consume space in the editable account row")
assert(!authentication_ui.include?("Account Type Pending"), "unverified legacy account types must be omitted instead of shown as pending")
assert(app_delegate.include?("localizedAuthenticationFailure(for:"), "Apple ID authentication failures must use localized inline feedback")

verification_ui = read(root, "AltServer/AppleIDVerificationWindowController.swift")
assert(verification_ui.include?("verificationCodeLength = 6"), "Apple ID verification must require a six-digit code")
assert(verification_ui.include?('filter { "0123456789".contains($0) }'), "Apple ID verification must reject non-ASCII digits")
assert(verification_ui.include?("String(digits.prefix(Self.verificationCodeLength))"), "Apple ID verification input must remain bounded")
assert(!verification_ui.include?("Keychain") && !verification_ui.include?("UserDefaults"), "Apple ID verification codes must not be persisted")

credential_store = read(root, "AltServer/AppleIDCredentialStore.swift")
assert(credential_store.include?("import KeychainAccess"), "Apple ID credentials must use the existing Keychain wrapper")
assert(credential_store.include?(".afterFirstUnlockThisDeviceOnly"), "Apple ID credentials must remain local to this Mac")
assert(credential_store.include?("maximumAccounts = 8"), "saved Apple ID history must remain bounded")
assert(credential_store.include?("maximumArchiveSize = 64 * 1024"), "saved credential archive must have a size bound")
assert(!credential_store.include?("UserDefaults"), "Apple ID credentials must not fall back to UserDefaults")
assert(credential_store.include?("func credentialSnapshot() throws -> [AppleIDSavedCredential]"), "saved accounts and passwords must be returned by one bounded Keychain archive read")
assert(credential_store.include?("updateAccountKind"), "saved Apple ID accounts must persist the last verified team type")
assert(authentication_ui.include?("self.credentialStore.credentialSnapshot()"), "the authentication window must load saved credentials with one Keychain request")
assert(!authentication_ui.include?("self.credentialStore.password(for:"), "selecting a saved account must not trigger a second Keychain request")
assert(authentication_ui.include?("self.savedCredentials.removeAll(keepingCapacity: false)"), "the authentication window must release its credential snapshot when the modal session ends")
assert(app_delegate.include?("recordSuccessfulAuthentication"), "credentials must only be recorded after authentication succeeds")
assert(app_delegate.include?("teamCompletion:"), "verified Apple ID team types must be recorded after team lookup")

installation_manager = read(root, "AltServer/Devices/ALTDeviceManager+Installation.swift")
authentication_result = installation_manager.index("let (account, session) = try result.get()")
credential_callback = installation_manager.index("authenticationCompletion()")
assert(authentication_result && credential_callback && credential_callback > authentication_result, "credential persistence must run only after successful Apple authentication")
assert(installation_manager.include?("AppleIDVerificationWindowController()"), "Apple ID two-factor authentication must use the dedicated verification window")
assert(!installation_manager.include?("securityCodeTextField"), "Apple ID verification must not retain the obsolete shared security-code field")
assert(installation_manager.include?("githubReleaseMirrorPrefixes"), "AltForge release downloads must provide bounded GitHub mirror fallback")
assert(installation_manager.include?("fetchReleaseAssetIntegrity"), "mirrored release downloads must obtain trusted GitHub asset integrity metadata")
assert(installation_manager.include?("try self.sha256(of: fileURL) == integrity.sha256"), "mirrored release downloads must verify the GitHub SHA-256 digest")
assert(installation_manager.include?("configuration.timeoutIntervalForRequest = 45"), "release requests must use a bounded idle timeout")
assert(installation_manager.include?("configuration.timeoutIntervalForResource = 600"), "release downloads must use a bounded resource timeout")
assert(installation_manager.include?("var downloadMirrors: [URL]?"), "official source metadata must support repository-configured CDN mirrors")
assert(installation_manager.include?("configuredMirrorURLs.prefix(4)"), "configured CDN mirror fan-out must remain bounded")
assert(installation_manager.include?("downloadControl.setSelectionHandler"), "download source selection must restart the active transfer")
assert(installation_manager.include?("task?.cancel()"), "manual source switching must cancel the previous transfer")
assert(installation_manager.include?("bytesPerSecond"), "release downloads must report live transfer speed")

installation_progress = read(root, "AltServer/InstallationProgressWindowController.swift")
assert(installation_progress.include?("case downloading"), "macOS installation progress must expose the download stage")
assert(installation_progress.include?("fractionCompleted"), "macOS installation progress must expose determinate transfer progress")
assert(installation_progress.include?("ByteCountFormatter"), "download progress must format transferred and total bytes")
assert(installation_progress.include?("ALTInstallationDownloadControl"), "download progress must expose a bounded source selector")
assert(installation_progress.include?("self.progressIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)"), "the progress bar must use symmetric horizontal margins")
assert(app_delegate.include?("activeInstallations[device.identifier]"), "macOS installation must deduplicate work by device identifier")
assert(app_delegate.include?("activeInstallation.focus()"), "a duplicate installation request must focus the existing operation")
certificate_flow = installation_manager[/func fetchCertificate\(.*?\n    func prepareAllProvisioningProfiles/m]
assert(certificate_flow, "macOS certificate flow could not be inspected")
assert(certificate_flow.include?('machineName.hasPrefix("AltForge") || machineName.hasPrefix("AltStore")'), "certificate replacement must be limited to AltForge-managed certificates")
assert(!certificate_flow.include?("altstoreCertificate ?? certificates.first"), "certificate replacement must never fall back to an unrelated Xcode certificate")
assert(certificate_flow.include?('addCertificate(machineName: "AltForge"'), "new macOS signing certificates must use the AltForge owner label")
assert(certificate_flow.include?("confirmReplacement(of: certificate)"), "managed certificate replacement must require explicit consent")

altsign_package = read(root, "Dependencies/AltSign/Package.swift")
assert(!altsign_package.include?('.define("MARKETPLACE")'), "Classic AltServer authentication must not compile AltSign with SRP cryptography disabled")

release_generator = read(root, "Scripts/generate_release_metadata.rb")
assert(release_generator.include?('parser.on("--cdn-base-url URL")'), "release metadata generation must accept an explicit CDN base URL")
assert(release_generator.include?('current_version["downloadMirrors"]'), "release metadata must publish the configured CDN mirror")
assert(workflow.include?("ALT_FORGE_CDN_BASE_URL"), "release workflow must pass the repository CDN variable to metadata generation")

plugin_manager = read(root, "AltServer/Plugin/PluginManager.swift")
assert(plugin_manager.include?('NSLocalizedString("Remove Legacy Mail Plug-in"'), "legacy Mail plug-in action needs a clear title")
assert(plugin_manager.include?('NSLocalizedString("Remove Plug-in"'), "legacy Mail plug-in confirmation needs a clear command")
assert(!plugin_manager.match?(%r{https?://}), "legacy Mail plug-in manager must not access an update or download service")
assert(!plugin_manager.include?("URLSession"), "legacy Mail plug-in manager must remain uninstall-only")

menu_icon_catalog = JSON.parse(read(root, "AltServer/Assets.xcassets/MenuBarIcon.imageset/Contents.json"))
assert(menu_icon_catalog.dig("properties", "template-rendering-intent") == "template", "menu bar icon must use template rendering")
assert(png_dimensions(root, "AltServer/Assets.xcassets/MenuBarIcon.imageset/MenuBar@19.png") == [19, 19], "1x menu bar icon dimensions are incorrect")
assert(png_dimensions(root, "AltServer/Assets.xcassets/MenuBarIcon.imageset/MenuBar@38.png") == [38, 38], "2x menu bar icon dimensions are incorrect")
brand_generator = read(root, "Scripts/generate_brand_assets.rb")
assert(brand_generator.include?("MENU_BAR_CROP_SIZE = 780"), "menu bar icon must remove the template master's display padding")
assert(brand_generator.scan("resize_cropped_png(TEMPLATE_ICON").length == 2, "both menu bar scales must use the cropped template output")

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
%w[AltForge\ Server Account Account\ Could\ Not\ Be\ Saved Apple\ ID\ Account Apple\ ID\ Verified Caps\ Lock\ is\ on. Downloading\ AltForge Forget\ Account Free\ Account Hide\ Password Individual\ Developer Installation\ Complete Installation\ Progress Organization\ /\ Enterprise Remember\ password Replace\ AltForge\ Certificate Saved\ accounts\ are\ unavailable.\ You\ can\ still\ sign\ in. Saved\ passwords\ are\ stored\ in\ this\ Mac's\ Keychain. Show\ Password Sign\ in\ with\ Apple\ ID Signing\ AltForge Check\ for\ Updates… Remove\ Plug-in USB Wi-Fi].each do |key|
  localized_key = key.gsub('\\ ', ' ')
  assert(desktop_strings.dig(localized_key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese desktop string: #{localized_key}")
end
["Automatic (Recommended)", "Current source: %@", "Downloading the verified IPA from the selected mirror…", "GitHub (Official)", "The selected download sources could not download AltForge."].each do |key|
  assert(desktop_strings.dig(key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese download string: #{key}")
end
altsign_error_source = read(root, "Dependencies/AltSign/AltSign/Categories/NSError+ALTErrors.m")
altsign_error_source.scan(/NSLocalizedString\(@"((?:\\.|[^"\\])*)"/).flatten.uniq.each do |key|
  assert(desktop_strings.dig(key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese AltSign error string: #{key}")
end
["Launch at Login (On)", "Launch at Login (Off)", "Launch at Login (Requires Approval)", "Unable to Change Launch at Login", "Restart Required", "Restart Now"].each do |key|
  assert(desktop_strings.dig(key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese launch-at-login state: #{key}")
end
desktop_menu_strings = JSON.parse(read(root, "AltServer/mul.lproj/Main.xcstrings")).fetch("strings")
%w[Afg-1A-Set.title IyR-FQ-upe.title Afg-1D-Lng.title Afg-1F-Sys.title Afg-1G-Eng.title Afg-1H-Zhs.title].each do |key|
  assert(desktop_menu_strings.dig(key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese desktop menu string: #{key}")
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

database_manager = read(root, "AltStoreCore/Model/DatabaseManager.swift")
assert(database_manager.include?("let storeBuildVersion = localApp.buildVersion"), "AltForge build version must be persisted for update comparisons")
assert(database_manager.include?("UserDefaults.shared.requiresAppGroupMigration && FileManager.default.altstoreSharedDirectory != nil"), "app-group migration must require access to the actual shared container")
assert(database_manager.include?("previousAppsDirectoryURL.standardizedFileURL != appsDirectoryURL.standardizedFileURL"), "app-group migration must never replace the Apps directory with itself")
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
