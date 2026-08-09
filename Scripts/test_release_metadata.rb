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
    "AltForge-AltServer-macOS.zip" => "mac fixture\n",
    "AltForge-AltServer-Windows.zip" => "windows fixture\n"
  }
  fixtures.each { |name, content| File.write(File.join(artifacts, name), content) }

  arguments = [
    "--artifacts", artifacts,
    "--version", "9.8.7",
    "--build", "987",
    "--date", "2026-08-09"
  ]
  stdout, stderr, status = run_generator(generator, arguments)
  raise "generator failed: #{stdout}#{stderr}" unless status.success?

  source = JSON.parse(File.read(File.join(artifacts, "apps.json")))
  app = source.fetch("apps").fetch(0)
  version = app.fetch("versions").fetch(0)
  raise "unexpected bundle identifier" unless app.fetch("bundleIdentifier") == "com.legeling.AltForge"
  raise "unexpected version metadata" unless version.values_at("version", "buildVersion", "date") == ["9.8.7", "987", "2026-08-09"]

  ipa = File.join(artifacts, "AltForge.ipa")
  raise "unexpected IPA size" unless version.fetch("size") == File.size(ipa)
  raise "unexpected IPA hash" unless version.fetch("sha256") == Digest::SHA256.file(ipa).hexdigest

  expected_names = fixtures.keys + ["apps.json"]
  checksums = File.readlines(File.join(artifacts, "SHA256SUMS.txt"), chomp: true)
  raise "unexpected checksum set" unless checksums.map { |line| line.split.last }.sort == expected_names.sort
  expected_names.each do |name|
    digest = Digest::SHA256.file(File.join(artifacts, name)).hexdigest
    raise "unexpected checksum for #{name}" unless checksums.include?("#{digest}  #{name}")
  end

  File.delete(File.join(artifacts, "AltForge-AltServer-Windows.zip"))
  _stdout, missing_stderr, missing_status = run_generator(generator, arguments)
  raise "missing Windows artifact was accepted" if missing_status.success?
  raise "missing artifact error was unclear" unless missing_stderr.include?("AltForge-AltServer-Windows.zip")

  _stdout, arguments_stderr, arguments_status = run_generator(generator, ["--artifacts", artifacts])
  raise "missing arguments were accepted" if arguments_status.success?
  raise "missing argument error was unclear" unless arguments_stderr.include?("Missing required options")
end

puts "release metadata contract passed"
