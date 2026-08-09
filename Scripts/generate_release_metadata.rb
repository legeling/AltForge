#!/usr/bin/env ruby

require "digest"
require "json"
require "optparse"

options = {}
OptionParser.new do |parser|
  parser.on("--artifacts PATH") { |value| options[:artifacts] = value }
  parser.on("--version VERSION") { |value| options[:version] = value }
  parser.on("--build BUILD") { |value| options[:build] = value }
  parser.on("--date DATE") { |value| options[:date] = value }
end.parse!

required = %i[artifacts version build date]
missing = required.reject { |key| options[key] && !options[key].empty? }
abort("Missing required options: #{missing.join(', ')}") unless missing.empty?

artifacts = File.expand_path(options[:artifacts])
ipa_path = File.join(artifacts, "AltForge.ipa")
mac_path = File.join(artifacts, "AltForge-AltServer-macOS.zip")
windows_path = File.join(artifacts, "AltForge-AltServer-Windows.zip")
[ipa_path, mac_path, windows_path].each do |path|
  abort("Missing release artifact: #{path}") unless File.file?(path)
end

repository_url = "https://github.com/legeling/AltForge"
download_url = "#{repository_url}/releases/latest/download/AltForge.ipa"
icon_url = "https://raw.githubusercontent.com/legeling/AltForge/marketplace/AltStore/Resources/Icons.xcassets/Raw/AppIcon.imageset/AltForgeIcon.png"

source = {
  "name" => "AltForge",
  "identifier" => "com.legeling.AltForge.Source",
  "subtitle" => "The official source for AltForge releases.",
  "description" => "AltForge is a maintained AltStore Classic derivative with Simplified Chinese support.",
  "website" => repository_url,
  "iconURL" => icon_url,
  "tintColor" => "#C52A42",
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
      "tintColor" => "#C52A42",
      "category" => "utilities",
      "appPermissions" => {
        "entitlements" => [
          "aps-environment",
          "com.apple.developer.siri",
          "com.apple.security.application-groups"
        ],
        "privacy" => {}
      },
      "versions" => [
        {
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
      ]
    }
  ]
}

source_path = File.join(artifacts, "apps.json")
File.write(source_path, JSON.pretty_generate(source) + "\n")

checksum_paths = [ipa_path, mac_path, windows_path, source_path]
checksums = checksum_paths.map do |path|
  "#{Digest::SHA256.file(path).hexdigest}  #{File.basename(path)}"
end
File.write(File.join(artifacts, "SHA256SUMS.txt"), checksums.join("\n") + "\n")
