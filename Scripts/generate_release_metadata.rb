#!/usr/bin/env ruby

require "digest"
require "date"
require "fileutils"
require "json"
require "optparse"
require "uri"

MAX_VERSION_HISTORY = 20

options = {}
OptionParser.new do |parser|
  parser.on("--artifacts PATH") { |value| options[:artifacts] = value }
  parser.on("--version VERSION") { |value| options[:version] = value }
  parser.on("--build BUILD") { |value| options[:build] = value }
  parser.on("--date DATE") { |value| options[:date] = value }
  parser.on("--previous-source PATH") { |value| options[:previous_source] = value }
  parser.on("--cdn-base-url URL") { |value| options[:cdn_base_url] = value }
end.parse!

required = %i[artifacts version build date]
missing = required.reject { |key| options[key] && !options[key].empty? }
abort("Missing required options: #{missing.join(', ')}") unless missing.empty?
abort("Version must use numeric X.Y.Z form") unless options[:version].match?(/\A\d+\.\d+\.\d+\z/)
abort("Build must be numeric") unless options[:build].match?(/\A\d+\z/)
abort("Date must use YYYY-MM-DD form") unless options[:date].match?(/\A\d{4}-\d{2}-\d{2}\z/)
begin
  abort("Date must be a valid calendar date") unless Date.iso8601(options[:date]).iso8601 == options[:date]
rescue ArgumentError
  abort("Date must be a valid calendar date")
end

artifacts = File.expand_path(options[:artifacts])
ipa_path = File.join(artifacts, "AltForge.ipa")
mac_path = File.join(artifacts, "AltForge-AltServer-macOS.dmg")
windows_path = File.join(artifacts, "AltForge-AltServer-Windows.zip")
[ipa_path, mac_path, windows_path].each do |path|
  abort("Missing release artifact: #{path}") unless File.file?(path)
end

repository_url = "https://github.com/legeling/AltForge"
download_url = "#{repository_url}/releases/download/v#{options[:version]}/AltForge.ipa"
icon_url = "https://raw.githubusercontent.com/legeling/AltForge/marketplace/AltStore/Resources/Icons.xcassets/Raw/AppIcon.imageset/AltForgeIcon.png"

current_version = {
  "version" => options[:version],
  "buildVersion" => options[:build],
  "date" => options[:date],
  "localizedDescription" => "See the GitHub Release notes for changes in this version.",
  "localizedDescriptions" => {
    "zh-Hans" => "本版本的变更请查看 GitHub Release 说明。"
  },
  "downloadURL" => download_url,
  "size" => File.size(ipa_path),
  "sha256" => Digest::SHA256.file(ipa_path).hexdigest,
  "minOSVersion" => "17.4"
}

if options[:cdn_base_url]
  begin
    cdn_base_url = URI.parse(options[:cdn_base_url])
  rescue URI::InvalidURIError
    abort("CDN base URL must be a valid HTTPS URL")
  end
  valid_cdn_url = cdn_base_url.is_a?(URI::HTTPS) && cdn_base_url.host && !cdn_base_url.host.empty? && cdn_base_url.userinfo.nil? && cdn_base_url.query.nil? && cdn_base_url.fragment.nil?
  abort("CDN base URL must be a valid HTTPS URL without credentials, query, or fragment") unless valid_cdn_url

  base = options[:cdn_base_url].sub(%r{/+\z}, "")
  current_version["downloadMirrors"] = ["#{base}/v#{options[:version]}/AltForge.ipa"]
end

previous_versions = []
if options[:previous_source]
  begin
    previous_source = JSON.parse(File.read(File.expand_path(options[:previous_source])))
  rescue JSON::ParserError
    abort("Previous source must contain valid JSON")
  end
  abort("Previous source identifier does not match AltForge") unless previous_source["identifier"] == "com.legeling.AltForge.Source"

  previous_apps = previous_source["apps"]
  abort("Previous source apps must be an array") unless previous_apps.is_a?(Array)
  previous_app = previous_apps.find { |app| app.is_a?(Hash) && app["bundleIdentifier"] == "com.legeling.AltForge" }
  abort("Previous source does not contain AltForge") unless previous_app

  previous_versions = previous_app.fetch("versions", [])
  abort("Previous source versions must be an array") unless previous_versions.is_a?(Array)
  previous_versions.each do |entry|
    valid_entry = entry.is_a?(Hash) && entry["version"].is_a?(String) && entry["version"].match?(/\A\d+\.\d+\.\d+\z/) && entry["downloadURL"].is_a?(String)
    abort("Previous source contains an invalid version entry") unless valid_entry

    expected_url = "#{repository_url}/releases/download/v#{entry['version']}/AltForge.ipa"
    abort("Previous source contains a non-tag-pinned download URL") unless entry["downloadURL"] == expected_url
  end
end

seen_versions = {options[:version] => true}
versions = previous_versions.each_with_object([current_version]) do |entry, result|
  next if seen_versions[entry["version"]]

  seen_versions[entry["version"]] = true
  result << entry
end.first(MAX_VERSION_HISTORY)

permissions_path = File.expand_path("../Release/app-permissions.json", __dir__)
permissions = JSON.parse(File.read(permissions_path))
valid_permissions = permissions.is_a?(Hash) && permissions.keys.sort == %w[entitlements privacy] &&
  permissions["entitlements"].is_a?(Array) && permissions["entitlements"].all? { |key| key.is_a?(String) && !key.empty? } &&
  permissions["privacy"].is_a?(Hash) && permissions["privacy"].all? { |key, description| key.match?(/\A(?:NS)?.+UsageDescription.*\z/) && description.is_a?(String) && !description.strip.empty? }
abort("Release app permissions must contain reviewed entitlements and privacy descriptions") unless valid_permissions

source = {
  "name" => "AltForge",
  "identifier" => "com.legeling.AltForge.Source",
  "subtitle" => "The official source for AltForge releases.",
  "description" => "AltForge is a maintained AltStore Classic derivative with Simplified Chinese support.",
  "website" => repository_url,
  "iconURL" => icon_url,
  "tintColor" => "#8E1735",
  "apps" => [
    {
      "name" => "AltForge",
      "bundleIdentifier" => "com.legeling.AltForge",
      "developerName" => "AltForge Contributors",
      "subtitle" => "A maintained AltStore Classic derivative.",
      "localizedDescription" => "Install, refresh, and manage sideloaded apps with AltServer.",
      "localizedDescriptions" => {
        "zh-Hans" => "通过 AltServer 安装、刷新和管理侧载应用。"
      },
      "iconURL" => icon_url,
      "tintColor" => "#8E1735",
      "category" => "utilities",
      "appPermissions" => permissions,
      "versions" => versions
    }
  ]
}

source_path = File.join(artifacts, "apps.json")
File.write(source_path, JSON.pretty_generate(source) + "\n")

release_config_directory = File.expand_path("../Release", __dir__)
config_paths = %w[flags.json sources.json recommended-sources.json developerdisks.json].map do |name|
  source_config_path = File.join(release_config_directory, name)
  JSON.parse(File.read(source_config_path))

  destination = File.join(artifacts, name)
  FileUtils.cp(source_config_path, destination)
  destination
end

checksum_paths = [ipa_path, mac_path, windows_path, source_path] + config_paths
checksums = checksum_paths.map do |path|
  "#{Digest::SHA256.file(path).hexdigest}  #{File.basename(path)}"
end
File.write(File.join(artifacts, "SHA256SUMS.txt"), checksums.join("\n") + "\n")
