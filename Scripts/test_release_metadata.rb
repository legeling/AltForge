#!/usr/bin/env ruby

require "digest"
require "json"
require "open3"
require "rbconfig"
require "tmpdir"

generator = File.expand_path("generate_release_metadata.rb", __dir__)

def run_generator(generator, arguments)
  Open3.capture3(RbConfig.ruby, generator, *arguments)
end

Dir.mktmpdir("altforge-release-contract-") do |artifacts|
  fixtures = {
    "AltForge.ipa" => "ipa fixture\n",
    "AltForge-AltServer-macOS.dmg" => "mac fixture\n",
    "AltForge-AltServer-Windows.zip" => "windows fixture\n"
  }
  fixtures.each { |name, content| File.write(File.join(artifacts, name), content) }

  previous_source_path = File.join(artifacts, "previous-apps.json")
  previous_source = {
    "name" => "AltForge",
    "identifier" => "com.legeling.AltForge.Source",
    "apps" => [
      {
        "bundleIdentifier" => "com.legeling.AltForge",
        "versions" => [
          {
            "version" => "9.8.7",
            "downloadURL" => "https://github.com/legeling/AltForge/releases/download/v9.8.7/AltForge.ipa"
          },
          {
            "version" => "9.8.6",
            "buildVersion" => "986",
            "date" => "2026-08-08",
            "downloadURL" => "https://github.com/legeling/AltForge/releases/download/v9.8.6/AltForge.ipa"
          },
          {
            "version" => "9.8.6",
            "downloadURL" => "https://github.com/legeling/AltForge/releases/download/v9.8.6/AltForge.ipa"
          }
        ]
      }
    ]
  }
  baseline_previous_source = JSON.parse(JSON.generate(previous_source))
  File.write(previous_source_path, JSON.generate(previous_source))

  arguments = [
    "--artifacts", artifacts,
    "--version", "9.8.7",
    "--build", "987",
    "--date", "2026-08-09",
    "--previous-source", previous_source_path
  ]
  stdout, stderr, status = run_generator(generator, arguments)
  raise "generator failed: #{stdout}#{stderr}" unless status.success?

  source = JSON.parse(File.read(File.join(artifacts, "apps.json")))
  app = source.fetch("apps").fetch(0)
  versions = app.fetch("versions")
  version = versions.fetch(0)
  raise "unexpected bundle identifier" unless app.fetch("bundleIdentifier") == "com.legeling.AltForge"
  raise "unexpected version metadata" unless version.values_at("version", "buildVersion", "date") == ["9.8.7", "987", "2026-08-09"]
  expected_download_url = "https://github.com/legeling/AltForge/releases/download/v9.8.7/AltForge.ipa"
  raise "current version download URL is not tag-pinned" unless version.fetch("downloadURL") == expected_download_url
  raise "version history was not preserved and de-duplicated" unless versions.map { |item| item.fetch("version") } == ["9.8.7", "9.8.6"]

  previous_source.fetch("apps").fetch(0)["versions"] = 25.times.map do |index|
    {
      "version" => "8.#{index}.0",
      "downloadURL" => "https://github.com/legeling/AltForge/releases/download/v8.#{index}.0/AltForge.ipa"
    }
  end
  File.write(previous_source_path, JSON.generate(previous_source))
  _stdout, history_stderr, history_status = run_generator(generator, arguments)
  raise "bounded history generator failed: #{history_stderr}" unless history_status.success?
  bounded_source = JSON.parse(File.read(File.join(artifacts, "apps.json")))
  bounded_versions = bounded_source.fetch("apps").fetch(0).fetch("versions")
  raise "version history is not bounded" unless bounded_versions.length == 20
  previous_source = JSON.parse(JSON.generate(baseline_previous_source))
  File.write(previous_source_path, JSON.generate(previous_source))

  ipa = File.join(artifacts, "AltForge.ipa")
  raise "unexpected IPA size" unless version.fetch("size") == File.size(ipa)
  raise "unexpected IPA hash" unless version.fetch("sha256") == Digest::SHA256.file(ipa).hexdigest

  config_names = %w[flags.json sources.json recommended-sources.json developerdisks.json]
  config_names.each { |name| JSON.parse(File.read(File.join(artifacts, name))) }

  expected_names = fixtures.keys + ["apps.json"] + config_names
  checksums = File.readlines(File.join(artifacts, "SHA256SUMS.txt"), chomp: true)
  raise "unexpected checksum set" unless checksums.map { |line| line.split.last }.sort == expected_names.sort
  expected_names.each do |name|
    digest = Digest::SHA256.file(File.join(artifacts, name)).hexdigest
    raise "unexpected checksum for #{name}" unless checksums.include?("#{digest}  #{name}")
  end

  invalid_previous_source = previous_source.merge("identifier" => "com.example.Wrong")
  File.write(previous_source_path, JSON.generate(invalid_previous_source))
  _stdout, previous_stderr, previous_status = run_generator(generator, arguments)
  raise "mismatched previous source was accepted" if previous_status.success?
  raise "previous source error was unclear" unless previous_stderr.include?("identifier")
  File.write(previous_source_path, JSON.generate(previous_source))

  non_pinned_previous_source = JSON.parse(JSON.generate(previous_source))
  non_pinned_previous_source.fetch("apps").fetch(0).fetch("versions").fetch(1)["downloadURL"] = "https://github.com/legeling/AltForge/releases/latest/download/AltForge.ipa"
  File.write(previous_source_path, JSON.generate(non_pinned_previous_source))
  _stdout, pinned_stderr, pinned_status = run_generator(generator, arguments)
  raise "non-tag-pinned previous URL was accepted" if pinned_status.success?
  raise "non-tag-pinned error was unclear" unless pinned_stderr.include?("non-tag-pinned")
  File.write(previous_source_path, JSON.generate(previous_source))

  File.delete(File.join(artifacts, "AltForge-AltServer-Windows.zip"))
  _stdout, missing_stderr, missing_status = run_generator(generator, arguments)
  raise "missing Windows artifact was accepted" if missing_status.success?
  raise "missing artifact error was unclear" unless missing_stderr.include?("AltForge-AltServer-Windows.zip")

  _stdout, arguments_stderr, arguments_status = run_generator(generator, ["--artifacts", artifacts])
  raise "missing arguments were accepted" if arguments_status.success?
  raise "missing argument error was unclear" unless arguments_stderr.include?("Missing required options")

  invalid_arguments = arguments.dup
  invalid_arguments[invalid_arguments.index("9.8.7")] = "9.8-beta"
  _stdout, version_stderr, version_status = run_generator(generator, invalid_arguments)
  raise "invalid version was accepted" if version_status.success?
  raise "version validation error was unclear" unless version_stderr.include?("numeric X.Y.Z")

  invalid_date_arguments = arguments.dup
  invalid_date_arguments[invalid_date_arguments.index("2026-08-09")] = "2026-02-30"
  _stdout, date_stderr, date_status = run_generator(generator, invalid_date_arguments)
  raise "invalid calendar date was accepted" if date_status.success?
  raise "date validation error was unclear" unless date_stderr.include?("valid calendar date")
end

puts "release metadata contract passed"
