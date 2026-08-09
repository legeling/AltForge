#!/usr/bin/env ruby

require "json"
require "optparse"

options = {}
OptionParser.new do |parser|
  parser.on("--tag TAG") { |value| options[:tag] = value }
end.parse!

version_path = File.expand_path("../VERSION", __dir__)
version = File.read(version_path).strip
abort("VERSION must use numeric X.Y.Z form") unless version.match?(/\A\d+\.\d+\.\d+\z/)
abort("Release tag must be v#{version}") if options[:tag] && options[:tag] != "v#{version}"

project = File.read(File.expand_path("../AltStore.xcodeproj/project.pbxproj", __dir__))
expected_xcode_settings = 4
actual_xcode_settings = project.scan(/MARKETING_VERSION = #{Regexp.escape(version)};/).length
abort("Expected at least #{expected_xcode_settings} Xcode version settings for #{version}, found #{actual_xcode_settings}") if actual_xcode_settings < expected_xcode_settings

resource = File.read(File.expand_path("../AltServer-Windows/AltServer/Resource.rc", __dir__))
windows_tuple = version.tr(".", ",") + ",0"
abort("Windows FILEVERSION does not match #{version}") unless resource.include?("FILEVERSION #{windows_tuple}")
abort("Windows PRODUCTVERSION does not match #{version}") unless resource.include?("PRODUCTVERSION #{windows_tuple}")
abort("Windows string version does not match #{version}") unless resource.scan(%Q{"#{version}.0"}).length >= 2

manifest = JSON.parse(File.read(File.expand_path("../AltServer-Windows/vcpkg.json", __dir__)))
abort("Windows manifest version does not match #{version}") unless manifest["version-string"] == "#{version}-altforge"

puts "release version contract passed (#{version})"
