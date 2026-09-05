#!/usr/bin/env ruby

require "json"
require "rexml/document"
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

ios_main_storyboard = read(root, "AltStore/Base.lproj/Main.storyboard")
ios_main_document = REXML::Document.new(ios_main_storyboard)
ios_tab_destinations = REXML::XPath.match(
  ios_main_document,
  "//tabBarController[@customClass='TabBarController']/connections/segue[@relationship='viewControllers']"
).map { |segue| segue.attributes.fetch("destination").value }
assert(ios_tab_destinations == %w[faz-B4-Sub HCK-G6-KdY 3Ew-ox-i4n p3d-dP-Swg], "iOS tabs must remain Browse, Sources, My Apps, and Settings")
assert(!ios_main_storyboard.include?('customClass="NewsViewController"'), "the aggregate News page must not return to the iOS main storyboard")

ios_sources_storyboard = read(root, "AltStore/Sources/Base.lproj/Sources.storyboard")
ios_source_details = read(root, "AltStore/Sources/SourceDetailContentViewController.swift")
assert(ios_sources_storyboard.include?('customClass="NewsViewController"'), "source-specific news must remain available from source details")
assert(ios_source_details.include?("NewsItem.sortedFetchRequest(for: self.source)"), "source details must retain source-scoped news compatibility")

ios_tab_controller = read(root, "AltStore/TabBarController.swift")
ios_tab_cases = ios_tab_controller[/private enum Tab: Int, CaseIterable\s*\{(.*?)\n    \}/m, 1]&.scan(/case (\w+)/)&.flatten
assert(ios_tab_cases == %w[browse sources myApps settings], "iOS tab indices must match the four main storyboard tabs")
%w[bag square.stack.3d.up square.grid.2x2 gearshape].each do |symbol|
  assert(ios_tab_controller.include?(%Q[UIImage(systemName: "#{symbol}")]), "iOS tab bar must use the system symbol #{symbol}")
end

ios_settings_storyboard = read(root, "AltStore/Settings/Base.lproj/Settings.storyboard")
ios_settings = read(root, "AltStore/Settings/SettingsViewController.swift")
ios_info_plist = read(root, "AltStore/Info.plist")
assert(!ios_info_plist.include?("<key>ALTVersion</key>"), "iOS settings version must not come from a stale ALTVersion override")
assert(!ios_info_plist.include?("<key>ALTDeviceID</key>"), "the distributable iOS Info.plist must not contain a maintainer device identifier")
assert(!ios_info_plist.include?("<key>ALTServerID</key>"), "the distributable iOS Info.plist must not contain a maintainer server identifier")
assert(ios_info_plist.include?("<key>CFBundleName</key>\n\t<string>AltForge</string>"), "iOS system and crash-report identity must use AltForge")
ios_project = read(root, "AltStore.xcodeproj/project.pbxproj")
assert(ios_project.scan("EXECUTABLE_NAME = AltForge;").length == 2, "iOS Debug and Release executables must be named AltForge")
assert(ios_project.scan('/AltStore.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/AltForge').length == 2, "iOS test hosts must follow the AltForge executable name")
assert(ios_settings.include?('object(forInfoDictionaryKey: "CFBundleShortVersionString")'), "iOS settings must read the built product version")
assert(ios_settings.include?("https://github.com/legeling/AltForge"), "iOS settings must link to the AltForge repository")
assert(ios_settings.include?("https://github.com/altstoreio/AltStore"), "iOS credits must retain the upstream project link")
{
  "Original Developer" => "Riley Testut",
  "Maintainers" => "AltForge Contributors",
  "Original Design" => "Caroline Moore",
  "AltForge on GitHub" => nil,
  "Suggest an Improvement" => nil
}.each do |label, value|
  assert(ios_settings_storyboard.include?(%Q[text="#{label}"]), "iOS settings is missing #{label}")
  assert(ios_settings_storyboard.include?(%Q[text="#{value}"]), "iOS settings is missing #{value}") if value
end
assert(ios_settings.include?(".systemGroupedBackground"), "iOS settings must use the system grouped background")
assert(ios_settings_storyboard.include?('text="Theme Color"'), "iOS settings must expose theme-color selection")
assert(ios_settings.include?("ThemeSelectionViewController"), "iOS settings must provide a native theme-color picker")
assert(ios_settings.include?("UIGraphicsImageRenderer"), "theme choices must include visual color swatches")
assert(!ios_settings.include?("willDisplay cell:"), "iOS settings must not recursively recolor UIKit cell internals during display")
assert(!ios_settings.include?("applyDynamicColors"), "the crash-prone recursive settings recoloring helper must not return")
settings_header_xib = read(root, "AltStore/Settings/SettingsHeaderFooterView.xib")
patreon_header_xib = read(root, "AltStore/Settings/Base.lproj/AboutPatreonHeaderView.xib")
[ios_settings_storyboard, settings_header_xib, patreon_header_xib].each do |resource|
  assert(!resource.match?(/<color key="(?:textColor|titleColor|tintColor|backgroundColor|separatorColor)" (?:white=|red=)/), "iOS settings surfaces must not keep fixed keyed colors")
  assert(!resource.include?('indicatorStyle="white"') && !resource.include?('barStyle="black"'), "iOS settings surfaces must let system chrome follow light and dark appearance")
end
ios_app_icons = read(root, "AltStore/Settings/AltAppIconsViewController.swift")
assert(!ios_app_icons.match?(/\.(?:white|black)\b/), "the app-icon picker must not hard-code light-only foregrounds or backgrounds")
assert(ios_app_icons.include?(".systemGroupedBackground") && ios_app_icons.include?(".secondarySystemGroupedBackground") && ios_app_icons.include?(".label") && ios_app_icons.include?(".secondaryLabel"), "the app-icon picker must use system semantic surfaces and text")
assert(ios_app_icons.include?("setAlternateIconName") && ios_app_icons.include?("affectedIconNames") && ios_app_icons.include?("collectionView.reconfigureItems"), "the app-icon picker must refresh the old and new checkmarks after the system icon change completes")
assert(!ios_app_icons.include?("collectionView.isUserInteractionEnabled = false") && !ios_app_icons.include?("collectionView.reloadData()"), "app-icon switching must not freeze or rebuild the entire picker")
assert(ios_app_icons.include?("pendingIconName") && ios_app_icons.include?("collectionView.reconfigureItems") && ios_app_icons.include?("UISelectionFeedbackGenerator"), "app-icon switching must expose immediate bounded feedback and update only affected rows")
alternate_icons = read(root, "AltStore/Resources/AltIcons.plist")
alternate_icon_names = %w[AppIcon AppIcon_Coral AppIcon_Frost AppIcon_Paper AppIcon_Neon AppIcon_Blueprint AppIcon_Titanium AppIcon_Glass AppIcon_Ceramic]
alternate_icon_names.each do |icon_name|
  assert(alternate_icons.include?(icon_name), "alternate icon manifest is missing #{icon_name}")
end
info_plist = read(root, "AltStore/Info.plist")
alternate_icon_names.drop(1).each do |icon_name|
  assert(info_plist.scan("<string>#{icon_name}</string>").length >= 2, "#{icon_name} must be declared for both iPhone and iPad")
end
%w[Frost Paper Neon Blueprint Titanium Glass Ceramic].each do |variant|
  icon_directory = File.join(root, "AltStore/Resources/AppIcon_#{variant}.icon")
  icon_manifest = JSON.parse(File.read(File.join(icon_directory, "icon.json")))
  image_name = "AltForge#{variant}.png"
  assert(icon_manifest.dig("groups", 0, "layers", 0, "image-name") == image_name, "AppIcon_#{variant} must reference its generated brand asset")

  png = File.binread(File.join(icon_directory, "Assets", image_name))
  width, height = png.byteslice(16, 8).unpack("NN")
  color_type = png.getbyte(25)
  assert(width == 1024 && height == 1024 && color_type == 2, "AppIcon_#{variant} must be a 1024px RGB PNG without alpha")
end
assert(File.exist?(File.join(root, "Scripts/generate_altforge_app_icons.swift")), "alternate brand icons must remain reproducibly generated")
brand_generator = read(root, "Scripts/generate_brand_assets.rb")
%w[Titanium Glass Ceramic].each do |variant|
  source_name = "altforge-app-icon-#{variant.downcase}.png"
  assert(File.exist?(File.join(root, "docs/assets/brand", source_name)), "#{variant} must retain its authoritative brand source")
  assert(brand_generator.include?("AppIcon_#{variant}.icon/Assets/AltForge#{variant}.png"), "the brand generator must reproduce AppIcon_#{variant}")
end
settings_background = JSON.parse(read(root, "AltStore/Resources/Assets.xcassets/Colors/SettingsBackground.colorset/Contents.json"))
settings_components = settings_background.fetch("colors").map { |entry| entry.fetch("color").fetch("components") }
assert(settings_components.all? { |components| components.values_at("red", "green", "blue").all? { |value| value.to_f.between?(0.0, 1.0) } }, "settings background components must be normalized sRGB values")
assert(settings_background.fetch("colors").length == 2, "settings background must provide light and dark appearances")
assert(read(root, "AltStoreCore/Model/Source.swift").include?("return .altSourceTint"), "the official source must ignore stale release tint metadata")
store_app_model = read(root, "AltStoreCore/Model/StoreApp.swift")
assert(store_app_model.include?("self.bundleIdentifier == StoreApp.altstoreAppID ? .altSourceTint : self.tintColor"), "the official app must resolve its card tint from the selected theme")
news_item_model = read(root, "AltStoreCore/Model/NewsItem.swift")
assert(news_item_model.include?("self.sourceIdentifier == Source.altStoreIdentifier") && news_item_model.include?("return .altSourceTint"), "official news must resolve its background from the selected theme")
source_tint = JSON.parse(read(root, "AltStoreCore/Resources/Colors.xcassets/SourceTint.colorset/Contents.json"))
assert(source_tint.fetch("colors").length == 2, "official source tint must provide light and dark appearances")
primary_tint = JSON.parse(read(root, "AltStoreCore/Resources/Colors.xcassets/Primary.colorset/Contents.json"))
primary_light_components = primary_tint.fetch("colors").first.fetch("color").fetch("components")
assert(primary_light_components.fetch("red").to_f > primary_light_components.fetch("green").to_f, "the default AltForge accent must be Forge Red, not the legacy green")
theme_defaults = read(root, "AltStoreCore/Extensions/UserDefaults+AltStore.swift")
assert(theme_defaults.include?("public enum AltTheme: String, CaseIterable"), "theme choices must use the shared preference model")
assert(theme_defaults.include?("public static let defaultTheme: AltTheme = .forgeRed"), "Forge Red must remain the default theme")
assert(theme_defaults.include?("var preferredTheme: AltTheme"), "theme choice must persist in UserDefaults")
theme_colors = read(root, "AltStoreCore/Extensions/UIColor+AltStore.swift")
assert(theme_colors.include?("UserDefaults.standard.preferredTheme.primaryColor"), "primary UI tint must resolve from the selected theme")
assert(theme_colors.include?("UserDefaults.standard.preferredTheme.sourceTintColor"), "the official source tint must resolve from the selected theme")
assert(read(root, "AltStore/Extensions/UIColor+AltStore.swift").include?("var contrastingForegroundColor: UIColor"), "filled theme controls must derive a readable foreground color")
assert(read(root, "AltStore/AppDelegate.swift").include?("NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.themeDidChange"), "theme changes must refresh active application chrome")
assert(read(root, "AltStore/AppDelegate.swift").include?("rootViewController?.children.first(where: { $0 is TabBarController })"), "runtime theme changes must reach the child tab controller hosted by LaunchViewController")

theme_surface_paths = [
  "AltStore/App Detail/AppViewController.swift",
  "AltStore/App Detail/AppContentViewController.swift",
  "AltStore/App Detail/AppDetailCollectionViewController.swift",
  "AltStore/Browse/BrowseViewController.swift",
  "AltStore/Browse/FeaturedViewController.swift",
  "AltStore/Components/AppCardCollectionViewCell.swift",
  "AltStore/News/NewsViewController.swift",
  "AltStore/Sources/SourceDetailContentViewController.swift"
]
theme_surface_paths.each do |path|
  surface = read(root, path)
  assert(!surface.match?(/\b(?:app|storeApp|newsItem)\.tintColor\b/), "#{path} must use effective theme-aware metadata colors")
end

app_banner = read(root, "AltStore/Components/AppBannerView.swift")
assert(app_banner.include?("name: .altThemeDidChange") && app_banner.include?("configuredStoreApp?.effectiveTintColor"), "visible app and source banners must update immediately after theme changes")
review_permissions = read(root, "AltStore/Permissions/ReviewPermissionsViewController.swift")
assert(!review_permissions.match?(/gradient(?:Top|Bottom)|darkButtonBackground|overrideUserInterfaceStyle = \.dark/), "permission review must not force the legacy green dark-only presentation")
assert(review_permissions.include?(".systemGroupedBackground") && review_permissions.include?(".secondarySystemGroupedBackground") && review_permissions.include?(".altPrimary"), "permission review must use semantic surfaces and the selected theme")
add_source_text_field = read(root, "AltStore/Sources/Components/AddSourceTextFieldCell.swift")
assert(!add_source_text_field.include?(".gradientTop"), "the add-source field must not restore the legacy green accent in dark mode")

my_apps_controller = read(root, "AltStore/My Apps/MyAppsViewController.swift")
assert(!my_apps_controller.include?("self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionFooter"), "My Apps layout sizing must not dequeue a supplementary view outside the collection-view data source callback")
assert(my_apps_controller.include?("InstalledAppsCollectionFooterView.nib.instantiate(withOwner: nil)"), "My Apps footer sizing must use an independent prototype view")

localizable_catalog = JSON.parse(read(root, "AltStore/Resources/Localizable.xcstrings"))
expires_in_zh = localizable_catalog.dig("strings", "Expires in", "localizations", "zh-Hans", "stringUnit", "value")
assert(expires_in_zh == "剩余有效期", "the split expiration label must be a complete Simplified Chinese phrase")

localization_catalogs = [
  "AltBackup/Resources/Localizable.xcstrings",
  "AltServer/Resources/Localizable.xcstrings",
  "AltServer/mul.lproj/Main.xcstrings",
  "AltStore/Authentication/mul.lproj/Authentication.xcstrings",
  "AltStore/Resources/Localizable.xcstrings",
  "AltStore/Resources/InfoPlist.xcstrings",
  "AltStore/Resources/AppShortcuts.xcstrings",
  "AltStore/Settings/mul.lproj/AboutPatreonHeaderView.xcstrings",
  "AltStore/Settings/mul.lproj/Settings.xcstrings",
  "AltStore/Sources/mul.lproj/Sources.xcstrings",
  "AltStore/mul.lproj/Main.xcstrings",
  "AltStoreCore/Resources/Localizable.xcstrings",
  "AltWidget/Resources/Localizable.xcstrings"
]
placeholder_pattern = /%(?:\d+\$)?(?:lld|ld|d|@)|%[A-Za-z][A-Za-z0-9_]*|\$\{[^}]+\}/
normalize_placeholder = ->(placeholder) { placeholder.sub(/%\d+\$/, "%") }
localization_catalogs.each do |path|
  catalog = JSON.parse(read(root, path))
  catalog.fetch("strings").each do |key, entry|
    translation = entry.dig("localizations", "zh-Hans", "stringUnit", "value")
    assert(translation && !translation.empty?, "missing Simplified Chinese localization for #{key.inspect} in #{path}")

    source = entry.dig("localizations", "en", "stringUnit", "value") || key
    source_placeholders = source.scan(placeholder_pattern).map(&normalize_placeholder).sort
    translated_placeholders = translation.scan(placeholder_pattern).map(&normalize_placeholder).sort
    assert(source_placeholders == translated_placeholders, "Simplified Chinese placeholders do not match for #{key.inspect} in #{path}")
  end
end

expected_zh_terms = {
  "Active" => "已激活",
  "Inactive" => "未激活",
  "Free" => "免费",
  "Like" => "点赞",
  "Liked" => "已点赞",
  "Likes" => "点赞",
  "Unlike" => "取消点赞",
  "Refreshing" => "正在刷新",
  "Collections" => "软件源合集",
  "TECHY THINGS" => "技术选项",
  "Other Entitlements" => "其他授权项"
}
expected_zh_terms.each do |key, expected|
  actual = localizable_catalog.dig("strings", key, "localizations", "zh-Hans", "stringUnit", "value")
  assert(actual == expected, "Simplified Chinese localization for #{key.inspect} must be #{expected.inspect}")
end

app_shortcuts_catalog = JSON.parse(read(root, "AltStore/Resources/AppShortcuts.xcstrings"))
refresh_shortcut_zh = app_shortcuts_catalog.dig("strings", "Refresh ${applicationName}", "localizations", "zh-Hans", "stringUnit", "value")
assert(refresh_shortcut_zh == "刷新 ${applicationName}", "the primary Simplified Chinese App Shortcut phrase must use natural word order")

featured_controller = read(root, "AltStore/Browse/FeaturedViewController.swift")
assert(featured_controller.include?("No Apps to Browse") && featured_controller.include?("Manage Sources"), "an empty Browse tab must explain the source-driven catalog and offer a source action")
assert(featured_controller.include?("self.dataSource.itemCount == 0") && featured_controller.include?("self.emptyStateView.isHidden = !isEmpty"), "Browse must replace empty section headings with a real empty state")
assert(featured_controller.include?("makeEmptyLayout()") && featured_controller.include?("isEmpty ? self.emptyLayout : self.contentLayout"), "Browse empty state must use a header-free layout instead of showing empty content sections behind the placeholder")
assert(featured_controller.include?("presentSourcesRoot()"), "the Browse empty-state action must open the root software-source manager")
assert(featured_controller.include?("name: .altThemeDidChange") && featured_controller.include?("greaterThanOrEqualToConstant: 44"), "the Browse empty state must update with the selected theme and retain a 44-point action target")

tab_bar_controller = read(root, "AltStore/TabBarController.swift")
assert(tab_bar_controller.include?("func presentSourcesRoot()") && tab_bar_controller.include?("popToRootViewController(animated: false)"), "the explicit Manage Sources action must not strand users inside a previous source detail")

app_ids_controller = read(root, "AltStore/App IDs/AppIDsViewController.swift")
assert(!app_ids_controller.include?("self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader"), "App IDs layout sizing must not dequeue a supplementary view outside the collection-view data source callback")
assert(app_ids_controller.include?("AppIDsCollectionHeaderView.nib.instantiate(withOwner: nil)"), "App IDs header sizing must use an independent prototype view")

ldid_source = read(root, "Dependencies/AltSign/Dependencies/ldid/ldid.cpp")
assert(ldid_source.include?("#define CPU_TYPE_ARM64_32"), "ldid must recognize Apple Watch arm64_32 Mach-O binaries")
assert(ldid_source.include?('arch = "arm64_32"'), "ldid signing progress must name the arm64_32 architecture without constructing a string from NULL")
assert(ldid_source.include?("unsupported CPU type:"), "ldid must reject unknown CPU types with a catchable error instead of crashing")
alt_signer = read(root, "Dependencies/AltSign/AltSign/Signing/ALTSigner.mm")
assert(!alt_signer.include?("return entitlements.UTF8String;"), "AltSign must not construct std::string from nullable Objective-C entitlement bytes")
assert(alt_signer.include?("embedded bundle is missing prepared entitlements or a provisioning profile"), "AltSign must turn missing embedded-bundle entitlements into a catchable error")
assert(alt_signer.include?("progressHandler(detail)"), "AltSign must expose bounded bundle and Mach-O signing checkpoints")
server_request_handler = read(root, "AltServer/Connections/RequestHandler.swift")
assert(server_request_handler.include?("InstallationResponseCoordinator"), "AltForge Server must serialize installation progress and terminal responses")
assert(server_request_handler.include?("self.pendingProgress = nil") && server_request_handler.include?("self.terminalResult = result"), "terminal installation responses must supersede queued progress")
assert(server_request_handler.include?("guard !self.isSending, !self.didFinish"), "terminal installation responses must wait for an in-flight progress write")
release_workflow = read(root, ".github/workflows/release.yml")
assert(release_workflow.include?("bash Scripts/test_ldid_architecture_compatibility.sh"), "Apple release CI must exercise ldid architecture compatibility")

ios_interface_files = Dir.glob(File.join(root, "AltStore/**/*.{storyboard,xib}"))
ios_public_interface_values = ios_interface_files.flat_map do |path|
  File.read(path).scan(/\b(?:text|title|placeholder|toolTip|label|headerTitle|footerTitle)="([^"]*)"/).flatten
end
stale_ios_interface_values = ios_public_interface_values.select do |value|
  (value.include?("AltStore") && !value.include?("AltStore PAL") && !value.include?("AltStore 2.0")) || value.include?("AltServer")
end
assert(stale_ios_interface_values.empty?, "iOS interface resources still expose an upstream public name: #{stale_ios_interface_values.first}")
ios_public_catalogs = Dir.glob(File.join(root, "AltStore/**/*.xcstrings")).map { |path| JSON.parse(File.read(path)) }
ios_public_values = ios_public_catalogs.flat_map do |catalog|
  catalog.fetch("strings").flat_map do |key, entry|
    localizations = entry.fetch("localizations", {})
    english = localizations.dig("en", "stringUnit", "value") || key
    [english] + localizations.values.map { |localization| localization.dig("stringUnit", "value") }.compact
  end
end
stale_ios_brand_strings = ios_public_values.uniq.select do |value|
  (value.include?("AltStore") && !value.include?("AltStore PAL") && !value.include?("AltStore 2.0")) || value.include?("AltServer")
end
assert(stale_ios_brand_strings.empty?, "iOS public strings still expose an upstream public name: #{stale_ios_brand_strings.first}")
assert(read(root, "AltStore/Operations/ResignAppOperation.swift").include?('"UTTypeDescription": "AltForge Installed App"'), "installed-app metadata must use AltForge")
assert(read(root, "AltStore/Operations/FetchProvisioningProfilesOperation.swift").include?('let name = "AltForge " + groupIdentifier'), "new App Groups must use the AltForge public prefix")
ios_authentication = read(root, "AltStore/Operations/AuthenticationOperation.swift")
assert(!ios_authentication.include?("static let altInvertedPrimary"), "authentication prompts must not cache the first selected theme color")
assert(ios_authentication.include?('let machineName = "AltForge - " + UIDevice.current.name'), "new iOS signing certificates must use AltForge")
assert(ios_authentication.include?('machineName.starts(with: "AltForge") || machineName.starts(with: "AltStore")'), "certificate migration must recognize AltForge and legacy AltStore names")
assert(ios_authentication.index("$0.type == .individual") < ios_authentication.index("$0.type == .organization"), "iOS authentication must prefer an individual developer team before an organization team")
assert(ios_authentication.index("$0.type == .organization") < ios_authentication.index("$0.type == .free"), "iOS authentication must prefer an organization team before a free team")

ios_authentication_storyboard = read(root, "AltStore/Authentication/Base.lproj/Authentication.storyboard")
assert(ios_authentication_storyboard.include?("selects the best available team, and shows it in Settings"), "iOS authentication must explain automatic developer-team selection")
assert(ios_authentication_storyboard.include?("Connect by USB, or enable Wi-Fi sync"), "iOS workflow must explain both USB and Wi-Fi connections")
assert(ios_authentication_storyboard.include?("Free-account signatures usually last 7 days"), "iOS workflow must explain free-account expiry")
ios_authentication_strings = JSON.parse(read(root, "AltStore/Authentication/mul.lproj/Authentication.xcstrings")).fetch("strings")
%w[4rk-ge-FSj.text 6HP-Xh-sAH.text esj-pD-D4A.text HU5-Hv-E3d.text JeJ-bk-UCA.text M7T-9j-uyt.text nvb-Aq-sYa.text on2-62-waY.text].each do |key|
  assert(ios_authentication_strings.dig(key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese authentication string: #{key}")
end
assert(read(root, "AltStoreCore/Model/StoreApp.swift").include?("with AltForge Server."), "the built-in app description must use AltForge Server")

ios_app_manager = read(root, "AltStore/Managing Apps/AppManager.swift")
assert(ios_app_manager.include?("static let maximumCount = 20"), "interrupted iOS operation records must remain bounded")
assert(ios_app_manager.include?("static let maximumEventCount = 16"), "iOS diagnostic traces must have a bounded stage count")
assert(ios_app_manager.include?("static let maximumDetailLength = 120"), "iOS diagnostic event details must have a bounded length")
assert(ios_app_manager.include?("ALTDiagnosticIDErrorKey"), "iOS failure logs must persist a client diagnostic ID")
assert(ios_app_manager.include?("ALTDiagnosticStageErrorKey"), "iOS failure logs must persist the last active stage")
assert(ios_app_manager.include?("ALTDiagnosticTraceErrorKey"), "iOS failure logs must persist a bounded operation trace")
assert(ios_app_manager.include?('values = [context.server?.connectionType.localizedDiagnosticName, context.team?.type.localizedDescription]'), "authentication diagnostics must be limited to connection and team categories")
assert(ios_app_manager.include?("recoverInterruptedOperations"), "interrupted iOS operations must become visible after relaunch")
assert(ios_app_manager.include?("InstallationReceiptStore.shared.reconcile"), "foreground reconciliation must recover positively confirmed installations")
assert(ios_app_manager.include?("UIApplication.didBecomeActiveNotification") && ios_app_manager.include?("UIApplication.didEnterBackgroundNotification"), "installation recovery must follow foreground/background transitions")
assert(ios_app_manager.include?("isManaging: { self.isActivelyManagingApp"), "recovery must defer to live installation producers")
management_state_reader = ios_app_manager.split("func isActivelyManagingApp(withBundleID bundleID: String) -> Bool", 2).last&.split("\n    }", 2)&.first.to_s
assert(management_state_reader.include?("os_unfair_lock_lock(self.progressLock)") && management_state_reader.include?("os_unfair_lock_unlock(self.progressLock)"), "recovery must synchronize management-state reads with progress writes")
assert(!ios_app_manager.include?("remove it before retrying"), "interrupted-install recovery must not tell users to erase installed apps")
assert(!ios_app_manager.include?("context.delete(app)"), "missing UTI registration must not silently erase installed-app records")
assert(ios_app_manager.include?("InstallationReceiptStore.shouldRemoveCache"), "orphan IPA caches and pending installation receipts must be retained")
ios_install_operation = read(root, "AltStore/Operations/InstallAppOperation.swift")
assert(ios_install_operation.index("InstallationReceiptStore.shared.stage") < ios_install_operation.index("connection.send(request)"), "installation recovery metadata must persist before device installation begins")
assert(ios_install_operation.include?("try backgroundContext.save()"), "confirmed device installations must save before delivering an operation result")
assert(ios_install_operation.include?("timer.schedule(deadline: .now() + 180)"), "installation response waits must be bounded")
ios_install_ui = read(root, "AltStore/My Apps/MyAppsViewController.swift")
assert(ios_install_ui.include?("self.view.safeAreaLayoutGuide.topAnchor"), "installation progress must be below navigation chrome")
assert(ios_install_ui.include?("self.sideloadingStatusView.finish(error:"), "installation results must remain visible until dismissed")
assert(!read(root, "AltStore/Base.lproj/Main.storyboard").include?('name="Primary"'), "main storyboard must inherit the selected theme instead of a fixed brand red")
assert(ios_app_manager.include?("PendingAppOperations.json"), "pending iOS operations must use an atomic on-disk journal")
assert(ios_app_manager.include?("try data.write(to: self.fileURL, options: .atomic)"), "pending iOS operation journal writes must be atomic")
assert(ios_app_manager.include?("stage == .signingApp || stage == .installingApp"), "signing and device-install checkpoints must replace their latest event instead of evicting the bounded stage history")
assert(ios_app_manager.include?("recoverUnexpectedTermination"), "unexpected foreground termination must become visible after relaunch")
assert(ios_app_manager.include?("CurrentSession.json") && ios_app_manager.include?("InterruptedSession.json"), "app lifecycle recovery must retain bounded current and interrupted session records")
assert(ios_app_manager.include?("guard didSave else { return }"), "interrupted operation records must remain pending until the recovery log saves")
assert(ios_app_manager.scan("guard didSave else { return }").length >= 2, "failed operations must remain pending until their error log saves")
assert(ios_app_manager.include?("!app.objectID.isTemporaryID"), "StoreApp relationships must reject temporary cross-context object IDs")
assert(ios_app_manager.include?("context.existingObject(with: app.objectID)"), "StoreApp relationships must use throwing existing-object lookup")
assert(ios_app_manager.include?("context.existingObject(with: managedObjectID)"), "error logging must use safe cross-context lookup")
assert(read(root, "AltStore/AppDelegate.swift").include?("AppManager.shared.recoverInterruptedOperations()"), "database startup must recover interrupted operation logs")
assert(read(root, "AltStore/AppDelegate.swift").include?("AppManager.shared.recoverUnexpectedTermination()"), "database startup must recover unexpected foreground termination logs")
ios_my_apps = read(root, "AltStore/My Apps/MyAppsViewController.swift")
assert(!ios_my_apps.include?("switch Result(context.installedApp, context.error)"), "third-party IPA completion must not precondition-crash when an operation ends without a result")
assert(ios_my_apps.include?("The installation ended before AltForge received a result."), "missing third-party IPA results must become a handled error")
assert(ios_my_apps.include?("SideloadingStatusView") && ios_my_apps.include?("percentageLabel"), "third-party IPA installation must expose a persistent stage and percentage view")
assert(ios_my_apps.include?("setInstallationStatusHandler") && ios_my_apps.include?("stage.localizedName"), "third-party IPA installation must surface operation stages instead of only aggregate progress")
assert(ios_my_apps.include?("Remove Extensions (Recommended)") && ios_my_apps.include?("preferredAction = removeAction"), "extension removal must be the explicit recommended signing choice")
assert(ios_my_apps.include?("Keep and Sign Extensions") && ios_my_apps.include?("may exceed the active-app or weekly App ID limit"), "keeping extensions must explain signing and free-account quota risk")
assert(ios_my_apps.include?("appExtensions.prefix(4)") && ios_my_apps.include?("boundedSideloadingLabel"), "extension review must bound untrusted plugin names and list length")
refresh_group = read(root, "AltStore/Operations/RefreshGroup.swift")
assert(refresh_group.include?("detail.map { String($0.prefix(120)) }"), "visible installation detail must remain bounded")
my_apps_update = ios_my_apps[/func update\(\).*?func updateBadgeCount/m]
assert(my_apps_update && !my_apps_update.include?("reconfigureItems"), "My Apps appearance updates must not reconfigure a stale collection-view index path")
assert(my_apps_update&.include?("cellForItem(at: indexPath) as? NoUpdatesCollectionViewCell"), "My Apps must update the already-visible no-updates cell without mutating collection structure")
verify_app = read(root, "AltStore/Operations/VerifyAppOperation.swift")
assert(verify_app.include?("throw self.context.error ?? OperationError.invalidApp()"), "a missing prepared app must surface as a handled invalid-app error")
resign_app = read(root, "AltStore/Operations/ResignAppOperation.swift")
assert(resign_app.include?("removeUnsupportedAppleWatchBundle(from: appBundleURL)"), "unsupported Apple Watch companion bundles must be removed before iPhone app signing")
assert(resign_app.include?("sanitizedSigningDiagnosticDetail"), "signing checkpoints must be sanitized before entering persistent diagnostics")
install_app = read(root, "AltStore/Operations/InstallAppOperation.swift")
assert(install_app.include?("response.progress.isFinite") && install_app.include?("fractionCompleted >= 1.0"), "the iOS client must validate and robustly recognize terminal installation progress")
assert(install_app.include?("recordDiagnostic(.installingApp"), "device-install diagnostics must retain the latest bounded percentage")

ios_operation_contexts = read(root, "AltStore/Operations/OperationContexts.swift")
%w[findingServer authenticating preparingApp verifyingApp preparingProfiles signingApp sendingApp installingApp refreshingApp].each do |stage|
  assert(ios_operation_contexts.include?("case #{stage}"), "missing bounded iOS diagnostic stage: #{stage}")
end
ios_error_log = read(root, "AltStore/Settings/Error Log/ErrorLogViewController.swift")
assert(ios_error_log.include?('NSLocalizedString("Copy Diagnostic Report"'), "error log must expose the bounded diagnostic report action")
assert(ios_error_log.include?("ALTDiagnosticTraceErrorKey"), "copied error reports must include the operation trace")
diagnostic_detail_calls = Dir.glob(File.join(root, "AltStore/**/*.swift")).flat_map { |path| File.readlines(path).grep(/recordDiagnostic\(\..*detail:/) }
allowed_diagnostic_details = ["localizedDiagnosticName", "authenticationDiagnosticDetail", "recordDiagnostic(.signingApp, detail: detail)", "recordDiagnostic(.installingApp, detail:", "Removed unsupported Apple Watch components"]
assert(diagnostic_detail_calls.all? { |line| allowed_diagnostic_details.any? { |value| line.include?(value) } }, "diagnostic details must remain on the connection/team/signing allowlist")

ios_strings = JSON.parse(read(root, "AltStore/Resources/Localizable.xcstrings")).fetch("strings")
assert(ios_strings.dig("Sideloaded", "localizations", "zh-Hans", "stringUnit", "value") == "侧载", "Simplified Chinese must consistently use “侧载”")
assert(!ios_strings.to_json.include?("\u65c1\u8f7d"), "Simplified Chinese localization contains deprecated sideload wording")
["Authentication Ready", "Authenticating Apple ID", "Diagnostic ID", "Failure Stage", "Operation Trace", "Copy Diagnostic Report", "AltForge closed unexpectedly while it was active.", "The installation ended before AltForge received a result.", "Main App Bundle", "Removed unsupported Apple Watch components", "Installing App", "Reading IPA", "Downloading IPA", "Unpacking IPA", "Reviewing App Extensions", "Sign App Extensions?", "Keep and Sign Extensions", "Remove Extensions (Recommended)", "Theme Color", "Forge Red", "Ocean Blue", "Indigo", "Rose", "Selected"].each do |key|
  assert(ios_strings.dig(key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese diagnostic string: #{key}")
end

altsign_application = read(root, "Dependencies/AltSign/AltSign/Model/ALTApplication.mm")
assert(altsign_application.include?('isKindOfClass:[NSDictionary class]'), "untrusted IPA icon dictionaries must be type-checked before subscripting")
assert(altsign_application.include?('isKindOfClass:[NSString class]'), "untrusted IPA string metadata must be type-checked before use")
assert(altsign_application.include?('isKindOfClass:[NSNumber class]'), "untrusted IPA device-family values must be type-checked before conversion")

workflow = read(root, ".github/workflows/release.yml")
workflow_names = Dir.children(File.join(root, ".github/workflows")).select { |name| name.end_with?(".yml", ".yaml") }.sort
assert(workflow_names == ["release.yml", "website.yml"], "only the release and bounded website workflows may be enabled")
assert(workflow.include?("tags:\n      - \"v*\""), "release workflow must remain tag-only")
assert(!workflow.match?(/^\s*pull_request:/), "release workflow must not run for pull requests")
assert(!workflow.match?(/^\s*branches:/), "release workflow must not run for branch pushes")
prepare_job = workflow[/^  prepare:.*?^  apple:/m]
assert(prepare_job&.include?("submodules: recursive"), "release prepare job must check out submodules before repository policy validation")
assert(workflow.include?("--draft"), "release workflow must create a draft release")
assert(workflow.include?('gh release upload "$GITHUB_REF_NAME"'), "an explicitly re-pushed release tag must replace assets through the release workflow")
assert(workflow.include?("--clobber"), "same-tag recovery must replace every reviewed release asset")
assert(!workflow.include?("gh release delete"), "same-tag recovery must not delete the public release")
assert(workflow.include?("vcpkg_baseline: ${{ steps.version.outputs.vcpkg_baseline }}"), "prepare must expose the manifest vcpkg baseline")
assert(workflow.include?("ref: ${{ needs.prepare.outputs.vcpkg_baseline }}"), "Windows must check out the manifest vcpkg baseline")

website_workflow = read(root, ".github/workflows/website.yml")
assert(!website_workflow.include?("tags:"), "website workflow must never trigger a product Release")
assert(website_workflow.include?("branches:\n      - marketplace"), "website workflow must follow the repository production branch")
assert(website_workflow.include?("CLOUDFLARE_PAGES_DEPLOY_ENABLED == 'true'"), "website deployment must be explicitly enabled")
assert(website_workflow.include?("pages deploy website --project-name=altforge --branch=marketplace"), "website workflow may deploy only the bounded static directory")
assert(website_workflow.include?("secrets.CLOUDFLARE_API_TOKEN") && website_workflow.include?("secrets.CLOUDFLARE_ACCOUNT_ID"), "website deployment credentials must come from repository Secrets")

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
assert(workflow.scan("sha256sum --check SHA256SUMS.txt").length == 2, "release workflow must verify both local and downloaded release assets")
assert(workflow.match?(/gh release create "\$GITHUB_REF_NAME".*?--repo "\$GITHUB_REPOSITORY"/m), "Draft creation must identify the repository after entering the artifact directory")
assert(workflow.include?("testALTApplicationIgnoresMalformedOptionalMetadata"), "release CI must run the malformed IPA metadata regression")
assert(workflow.include?("testThemePreferenceDefaultsAndRoundTrips"), "release CI must run the theme preference regression")
assert(workflow.include?('xcrun simctl create "AltForge Release Tests"'), "release CI must create its own simulator instead of relying on runner image devices")
assert(workflow.include?('platform=iOS Simulator,id=${{ steps.simulator.outputs.udid }}'), "release tests must target the simulator created by the workflow")
assert(workflow.include?('if: always() && steps.simulator.outputs.udid !='), "release CI must clean up its temporary simulator after failures")

dmg_packager = read(root, "Scripts/package_macos_dmg.sh")
assert(dmg_packager.include?("hdiutil create"), "DMG packager must use the macOS disk image utility")
assert(dmg_packager.include?('staged_app="$content_root/AltForge Server.app"'), "DMG must present the public AltForge Server application name")
assert(dmg_packager.include?("ln -s /Applications"), "DMG packager must include an Applications shortcut")
assert(dmg_packager.include?("-format UDRW"), "DMG packager must create a writable staging image for deterministic Finder metadata")
assert(dmg_packager.include?('mount_point="/Volumes/$volume_name"'), "DMG packager must use the standard Finder volume location")
assert(dmg_packager.include?('[[ ! -e "$mount_point" ]]'), "DMG packager must not replace or reuse a user-mounted volume")
assert(dmg_packager.include?("set pathbar visible of dmgWindow to false"), "DMG Finder window must hide the path bar")
assert(dmg_packager.include?("set bounds of dmgWindow to {120, 120, 640, 420}"), "DMG Finder window must use the reviewed compact 520 by 300 point layout")
assert(dmg_packager.include?('set position of item "AltForge Server.app"'), "DMG Finder layout must position the application explicitly")
assert(dmg_packager.include?('set position of item "Applications"'), "DMG Finder layout must position the Applications shortcut explicitly")
assert(dmg_packager.include?('[[ -f "$mount_point/.DS_Store" ]]'), "DMG packaging must fail if Finder metadata was not persisted")
assert(dmg_packager.include?("hdiutil convert"), "DMG packager must compress the configured writable image")
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
macos_project = read(root, "AltStore.xcodeproj/project.pbxproj")
assert(macos_project.scan('PRODUCT_NAME = "AltForge Server";').length == 2, "macOS Debug and Release products must be named AltForge Server")
assert(macos_project.scan('EXECUTABLE_NAME = "AltForge Server";').length == 2, "macOS Debug and Release executables must be named AltForge Server")
assert(macos_project.scan("PRODUCT_MODULE_NAME = AltServer;").length == 2, "the public macOS product rename must preserve the internal Swift module")
assert(macos_project.include?('path = "AltForge Server.app";'), "the macOS build product must use the public bundle filename")
assert(macos_project.scan('@executable_path/AltForge Server.app/Contents/Frameworks').length == 2, "macOS helper runpaths must follow the public bundle filename")
altserver_scheme = read(root, "AltStore.xcodeproj/xcshareddata/xcschemes/AltServer.xcscheme")
assert(!altserver_scheme.include?('BuildableName = "AltServer.app"'), "the AltServer scheme must launch the public AltForge Server bundle")
altxpc_scheme = read(root, "AltStore.xcodeproj/xcshareddata/xcschemes/AltXPC.xcscheme")
assert(!altxpc_scheme.include?('BuildableName = "AltServer.app"'), "the AltXPC scheme must launch the public AltForge Server bundle")
assert(workflow.include?('Build/Products/Release/AltForge Server.app'), "release packaging must consume the public macOS build product")
assert(dmg_packager.include?('volume_name="AltForge Server"'), "the macOS DMG volume must use the AltForge Server public identity")
assert(apple_artifact_verifier.include?('Contents/MacOS/AltForge Server'), "release verification must inspect the public macOS executable")

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
assert(app_delegate.include?("self.serverUpdateController.checkForUpdates(menuItem: sender)"), "macOS update action must use the direct update controller")
assert(app_delegate.include?("self.serverUpdateController.cancel()"), "macOS update resources must be cancelled when the app terminates")
update_controller = read(root, "AltServer/ServerUpdateController.swift")
assert(update_controller.include?("timeoutIntervalForRequest = 10") && update_controller.include?("timeoutIntervalForResource = 600"), "update requests must have finite metadata and installer timeouts")
assert(update_controller.include?("maximumMetadataSize = 1_048_576") && update_controller.include?("maximumInstallerSize"), "update metadata and installer downloads must be size-bounded")
assert(update_controller.include?('asset.downloadURL.host?.lowercased() == "github.com"') && update_controller.include?('asset.downloadURL.path == expectedPath'), "update installer URL must be pinned to the expected GitHub release asset")
assert(update_controller.include?("URLSessionDownloadDelegate"), "macOS updates must report progress from URLSession download callbacks")
assert(update_controller.include?("asset.digest?.lowercased()") && update_controller.include?("SHA256()") && update_controller.include?("fileSize == self.asset.size"), "downloaded updates must verify GitHub size and SHA-256 metadata")
assert(update_controller.include?('NSLocalizedString("Download Update"') && !update_controller.include?('NSLocalizedString("Open Release"'), "an available update must offer a direct download instead of sending users to the release page")
assert(update_controller.include?("FileManager.default.urls(for: .downloadsDirectory") && update_controller.include?("NSWorkspace.shared.open(fileURL)"), "a verified update must be saved to Downloads and open its installer automatically")
assert(update_controller.include?("cancelHandler") && update_controller.include?("downloadGeneration") && update_controller.include?("self.downloadGeneration == expectedGeneration"), "update download cancellation must not let stale callbacks finish another transfer")
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
assert(installation_manager.include?("transfer?.cancel()"), "manual source switching must cancel the previous transfer")
assert(installation_manager.include?("bytesPerSecond"), "release downloads must report live transfer speed")
assert(installation_manager.include?("URLSessionDownloadDelegate"), "release download progress must come from URLSession delegate byte callbacks")
assert(installation_manager.include?("didWriteData bytesWritten"), "release downloads must report actual bytes written")
assert(!installation_manager.include?("downloadTask.progress.observe(\\.completedUnitCount"), "release downloads must not rely on unreliable task-progress KVO")

installation_progress = read(root, "AltServer/InstallationProgressWindowController.swift")
assert(installation_progress.include?("case downloading"), "macOS installation progress must expose the download stage")
assert(installation_progress.include?("fractionCompleted"), "macOS installation progress must expose determinate transfer progress")
assert(installation_progress.include?("ByteCountFormatter"), "download progress must format transferred and total bytes")
assert(installation_progress.include?("ALTInstallationDownloadControl"), "download progress must expose a bounded source selector")
assert(installation_progress.include?("self.progressIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)"), "the progress bar must use symmetric horizontal margins")
assert(installation_progress.include?("styleMask: [.titled, .closable, .miniaturizable]"), "the completed installation window must expose the native close control")
assert(installation_progress.include?("func showCompletion(onClose:"), "installation success must remain visible until the user closes it")
assert(installation_progress.include?('NSButton(title: NSLocalizedString("Close"'), "installation success must provide an explicit localized close button")
assert(installation_progress.include?("self.window?.performClose(sender)"), "the completion button must use the same guarded window close path")
assert(app_delegate.include?("activeInstallations[device.identifier]"), "macOS installation must deduplicate work by device identifier")
assert(app_delegate.include?("activeInstallation.focus()"), "a duplicate installation request must focus the existing operation")
assert(app_delegate.include?("progressController.showCompletion"), "installation success must present the closeable completion state")
assert(!app_delegate.include?("DispatchQueue.main.asyncAfter(deadline: .now() + 1.5)"), "installation success must not disappear on a fixed timer")
device_manager = read(root, "AltServer/Devices/ALTDeviceManager.mm")
assert(device_manager.include?("instproxy_status_get_name(status, &statusName)"), "device installation completion must inspect the installation-proxy status name")
assert(device_manager.include?('strcmp(statusName, "Complete") == 0'), "device installation must finish when installation_proxy reports Complete")
certificate_flow = installation_manager[/func fetchCertificate\(.*?\n    func prepareAllProvisioningProfiles/m]
assert(certificate_flow, "macOS certificate flow could not be inspected")
assert(certificate_flow.include?('machineName.hasPrefix("AltForge") || machineName.hasPrefix("AltStore")'), "certificate replacement must be limited to AltForge-managed certificates")
assert(!certificate_flow.include?("altstoreCertificate ?? certificates.first"), "certificate replacement must never fall back to an unrelated Xcode certificate")
assert(certificate_flow.include?('addCertificate(machineName: "AltForge"'), "new macOS signing certificates must use the AltForge owner label")
assert(certificate_flow.include?("confirmReplacement(of: certificate)"), "managed certificate replacement must require explicit consent")

altsign_package = read(root, "Dependencies/AltSign/Package.swift")
assert(!altsign_package.include?('.define("MARKETPLACE")'), "Classic AltServer authentication must not compile AltSign with SRP cryptography disabled")
anisette_manager = read(root, "AltServer/Anisette Data/AnisetteDataManager.swift")
altsign_apple_api = read(root, "Dependencies/AltSign/AltSign/Apple API/ALTAppleAPI.m")
assert(altsign_apple_api.include?('ALTAppleXcodeVersion = @"27.0 (27A5252f)"'), "Apple requests must use the current Xcode 27 client version")
assert(altsign_apple_api.include?('ALTAppleXcodeBundleVersion = @"25183.54.10"'), "anisette data must use the current accepted Xcode bundle version")
assert(anisette_manager.include?("ALTAppleXcodeBundleVersion"), "anisette and Apple service requests must share one Xcode identity")
assert(!anisette_manager.include?("3594.4.19"), "anisette data must not advertise the rejected Xcode 11 client identity")
altsign_authentication = read(root, "Dependencies/AltSign/AltSign/Sources/ALTAppleAPI+Authentication.swift")
assert(altsign_authentication.include?('"X-Xcode-Version": ALTAppleXcodeVersion'), "two-factor authentication must use the shared Xcode client version")
assert(altsign_apple_api.scan('@"X-Xcode-Version": ALTAppleXcodeVersion').length == 2, "all Apple Developer service requests must use the shared Xcode client version")
assert(!altsign_authentication.include?("11.2 (11B41)") && !altsign_apple_api.include?("11.2 (11B41)"), "Apple requests must not advertise the rejected Xcode 11 version")
assert(altsign_authentication.include?('return "AuthKit/1 (Macintosh; OS X 26.5.2) (com.apple.dt.Xcode/26.0)"'), "GSA must use the upstream-tested AuthKit compatibility user agent")
assert(!altsign_authentication.include?('"akd/1.0"'), "updating CFNetwork alone must not restore the failing akd user agent")
assert(altsign_authentication.include?("self.sendGSARequest(request, operation: operation, completionHandler: completionHandler)"), "production GSA calls must use the regression-tested isolated transport")
assert(altsign_authentication.include?("session.finishTasksAndInvalidate()"), "every isolated GSA attempt must release its session")
assert(altsign_authentication.scan("PropertyListSerialization.propertyList(from:").length == 1, "all Apple authentication response parsing must use the bounded metadata helper")
assert(altsign_authentication.include?("authenticationDictionary(from: data, operation: operation, response: response)"), "GSA responses must capture the safe authentication operation and HTTP metadata")
assert(altsign_authentication.include?("ALTAppleAPIHTTPStatusCodeErrorKey") && altsign_authentication.include?("ALTAppleAPIResponseMIMETypeErrorKey"), "malformed Apple authentication responses must preserve safe transport metadata")
assert(altsign_authentication.include?("never retain or log the response body"), "authentication parse failures must document response-body privacy")

error_presentation = read(root, "Shared/Extensions/NSError+AltStore.swift")
assert(error_presentation.include?("struct ALTErrorPresentation"), "user-facing errors must use the shared title, reason, and recovery model")
assert(error_presentation.include?("var userFacingPresentation: ALTErrorPresentation"), "all app surfaces must be able to request a consistent error presentation")
assert(error_presentation.include?('case 3840, 4864:'), "property-list and archive parse failures must use a data-specific message")
assert(!read(root, "Shared/Errors/ProcessError.swift").include?("baseMessage + \" \" + lastLine"), "raw process output must stay in error details instead of the primary message")
assert(!read(root, "AltServer/Plugin/PluginManager.swift").include?("return output"), "privileged task output must stay in error details instead of the primary message")

altsign_errors_header = read(root, "Dependencies/AltSign/AltSign/Categories/NSError+ALTErrors.h")
assert(altsign_errors_header.include?("ALTAppleAPIErrorInvalidResponse = 3022"), "Apple API invalid-response errors need a unique cross-platform code")
windows_altsign_errors = read(root, "AltServer-Windows/AltSign/Error.hpp")
{
  "MaximumAppIDLimitReached" => 3013,
  "InvalidAppGroup" => 3014,
  "AppGroupDoesNotExist" => 3015,
  "InvalidProvisioningProfileIdentifier" => 3016,
  "ProvisioningProfileDoesNotExist" => 3017,
  "InvalidResponse" => 3022
}.each do |name, code|
  assert(windows_altsign_errors.include?("#{name} = #{code}"), "Windows Apple API error #{name} must use shared code #{code}")
end

error_copy_keys = [
  "Apple ID Sign-In Failed",
  "The secure sign-in with Apple could not be completed.",
  "Apple's authentication service is temporarily limiting sign-in requests while %@ (HTTP 429).",
  "Apple's authentication service is temporarily unavailable while %@ (HTTP %ld).",
  "Apple's authentication service returned a web page instead of sign-in data while %@.",
  "The secure sign-in with Apple could not be completed while %@.",
  "The sign-in endpoint returned a server error. Wait a few minutes, then retry. If it continues, include the diagnostic details in your report.",
  "Sign-in failed before app signing. Try again later; if it continues, include the diagnostic details in your report.",
  "Wait several minutes before trying again. Repeated attempts may extend the temporary limit.",
  "starting Apple ID sign-in",
  "verifying the Apple ID",
  "issuing the developer token",
  "verifying the two-factor code",
  "preparing the sign-in request",
  "processing Apple ID sign-in",
  "Check the network and device date and time, then update AltForge Server before retrying.",
  "App Package Could Not Be Read",
  "Device Connection Failed",
  "App Verification Failed",
  "The returned data could not be read."
]
%w[AltStore/Resources/Localizable.xcstrings AltServer/Resources/Localizable.xcstrings].each do |path|
  strings = JSON.parse(read(root, path)).fetch("strings")
  error_copy_keys.each do |key|
    chinese = strings.dig(key, "localizations", "zh-Hans", "stringUnit", "value")
    assert(chinese && !chinese.empty?, "missing Simplified Chinese error copy in #{path}: #{key}")
  end
end

release_generator = read(root, "Scripts/generate_release_metadata.rb")
assert(release_generator.include?('parser.on("--cdn-base-url URL")'), "release metadata generation must accept an explicit CDN base URL")
assert(release_generator.include?('current_version["downloadMirrors"]'), "release metadata must publish the configured CDN mirror")
assert(release_generator.scan('"tintColor" => "#8E1735"').length == 2, "release source and app metadata must use the default Forge Red tint")
assert(!release_generator.include?("#C52A42"), "release metadata must not restore the legacy full-card red tint")
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
%w[AltForge\ Server Account Account\ Could\ Not\ Be\ Saved Apple\ ID\ Account Apple\ ID\ Verified Caps\ Lock\ is\ on. Close Downloading\ AltForge Forget\ Account Free\ Account Hide\ Password Individual\ Developer Installation\ Complete Installation\ Progress Organization\ /\ Enterprise Remember\ password Replace\ AltForge\ Certificate Saved\ accounts\ are\ unavailable.\ You\ can\ still\ sign\ in. Saved\ passwords\ stay\ in\ Keychain.\ macOS\ may\ ask\ for\ your\ Mac\ login\ password\ to\ read\ them,\ not\ your\ Apple\ ID\ password. Show\ Password Sign\ in\ with\ Apple\ ID Signing\ AltForge Check\ for\ Updates… Remove\ Plug-in USB Wi-Fi].each do |key|
  localized_key = key.gsub('\\ ', ' ')
  assert(desktop_strings.dig(localized_key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese desktop string: #{localized_key}")
end
["About AltForge Server", "AltForge Server is the macOS companion for AltForge. It downloads, signs, and installs AltForge and other IPA files on your Apple devices.", "Documentation", "GitHub Repository", "Releases", "Report an Issue", "Version %@ (%@)"].each do |key|
  assert(desktop_strings.dig(key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese About string: #{key}")
end
["Automatic (Recommended)", "Current source: %@", "Downloading the verified IPA from the selected mirror…", "GitHub (Official)", "The selected download sources could not download AltForge."].each do |key|
  assert(desktop_strings.dig(key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese download string: #{key}")
end
["Download Update", "Downloading Update", "Downloaded %@ of %@", "Preparing download…", "Cancelling download…", "Unable to Download Update", "Retry", "Unable to Open Installer", "Show in Finder", "AltForge Server will download the verified disk image and open the installer automatically.", "The downloaded installer did not match the size and SHA-256 published by GitHub."].each do |key|
  assert(desktop_strings.dig(key, "localizations", "zh-Hans", "stringUnit", "value"), "missing Simplified Chinese updater string: #{key}")
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
about_ui = read(root, "AltServer/AboutWindowController.swift")
assert(about_ui.include?('width: 560, height: 420'), "the custom About window must provide room for project details")
assert(about_ui.include?('https://github.com/legeling/AltForge'), "the About window must show the AltForge GitHub repository")
assert(about_ui.include?("contentStack.alignment = .centerX"), "the About window content must be horizontally centered")
assert(about_ui.include?("addCursorRect(self.bounds, cursor: .pointingHand)"), "clickable About links must use the pointing-hand cursor")
assert(app_delegate.include?("self.aboutWindowController.show()"), "the About menu must present the custom project window")
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

assert(File.file?(File.join(root, "website/index.html")), "the official static website entrypoint is missing")
assert(File.file?(File.join(root, "Scripts/test_website.rb")), "the static website contract is missing")

puts "repository release policy contract passed"
