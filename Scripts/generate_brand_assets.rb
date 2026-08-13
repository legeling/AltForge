#!/usr/bin/env ruby

require "fileutils"
require "open3"
require "tempfile"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
BRAND_ROOT = File.join(ROOT, "docs/assets/brand")
APP_ICON = File.join(BRAND_ROOT, "altforge-app-icon.png")
CORAL_APP_ICON = File.join(BRAND_ROOT, "altforge-app-icon-coral.png")
TITANIUM_APP_ICON = File.join(BRAND_ROOT, "altforge-app-icon-titanium.png")
GLASS_APP_ICON = File.join(BRAND_ROOT, "altforge-app-icon-glass.png")
CERAMIC_APP_ICON = File.join(BRAND_ROOT, "altforge-app-icon-ceramic.png")
TEMPLATE_ICON = File.join(BRAND_ROOT, "altforge-template-icon.png")
MENU_BAR_CROP_SIZE = 780

def run!(*command)
  stdout, stderr, status = Open3.capture3(*command)
  return stdout if status.success?

  abort(["Command failed: #{command.join(" ")}", stdout, stderr].reject(&:empty?).join("\n"))
end

def resize_png(source, destination, size)
  FileUtils.mkdir_p(File.dirname(destination))
  Tempfile.create(["altforge-brand", ".png"], File.dirname(destination)) do |file|
    file.close
    run!("sips", "-z", size.to_s, size.to_s, source, "--out", file.path)
    FileUtils.mv(file.path, destination)
  end
end

def resize_cropped_png(source, destination, size, crop_size)
  FileUtils.mkdir_p(File.dirname(destination))

  Dir.mktmpdir("altforge-brand", File.dirname(destination)) do |directory|
    cropped = File.join(directory, "cropped.png")
    run!("sips", "-c", crop_size.to_s, crop_size.to_s, source, "--out", cropped)
    resize_png(cropped, destination, size)
  end
end

def write_ico(source, destination, sizes)
  FileUtils.mkdir_p(File.dirname(destination))

  Dir.mktmpdir("altforge-ico") do |directory|
    images = sizes.map do |size|
      path = File.join(directory, "icon-#{size}.png")
      resize_png(source, path, size)
      [size, File.binread(path)]
    end

    offset = 6 + (16 * images.length)
    entries = images.map do |size, data|
      dimension = size == 256 ? 0 : size
      entry = [dimension, dimension, 0, 0, 1, 32, data.bytesize, offset].pack("CCCCvvVV")
      offset += data.bytesize
      entry
    end

    payload = [0, 1, images.length].pack("vvv") + entries.join + images.map(&:last).join
    Tempfile.create(["altforge-brand", ".ico"], File.dirname(destination)) do |file|
      file.binmode
      file.write(payload)
      file.close
      FileUtils.mv(file.path, destination)
    end
  end
end

abort("Missing brand source: #{APP_ICON}") unless File.file?(APP_ICON)
abort("Missing brand source: #{CORAL_APP_ICON}") unless File.file?(CORAL_APP_ICON)
[TITANIUM_APP_ICON, GLASS_APP_ICON, CERAMIC_APP_ICON].each do |source|
  abort("Missing dimensional icon source: #{source}") unless File.file?(source)
end
abort("Missing template source: #{TEMPLATE_ICON}") unless File.file?(TEMPLATE_ICON)

resize_png(APP_ICON, File.join(ROOT, "AltStore/Resources/AppIcon.icon/Assets/AltForge.png"), 1024)
resize_png(APP_ICON, File.join(ROOT, "AltStore/Resources/Icons.xcassets/Raw/AppIcon.imageset/AltForgeIcon.png"), 1024)
resize_png(APP_ICON, File.join(ROOT, "AltStore/Resources/Icons.xcassets/Raw/AppIcon.imageset/AltForgeIconDark.png"), 1024)
resize_png(CORAL_APP_ICON, File.join(ROOT, "AltStore/Resources/AppIcon_Coral.icon/Assets/AltForgeCoral.png"), 1024)
resize_png(CORAL_APP_ICON, File.join(ROOT, "AltStore/Resources/Icons.xcassets/Raw/AppIcon_Coral.imageset/AltForgeCoralIcon.png"), 1024)
run!("swift", File.join(ROOT, "Scripts/generate_altforge_app_icons.swift"))
resize_png(TITANIUM_APP_ICON, File.join(ROOT, "AltStore/Resources/AppIcon_Titanium.icon/Assets/AltForgeTitanium.png"), 1024)
resize_png(GLASS_APP_ICON, File.join(ROOT, "AltStore/Resources/AppIcon_Glass.icon/Assets/AltForgeGlass.png"), 1024)
resize_png(CERAMIC_APP_ICON, File.join(ROOT, "AltStore/Resources/AppIcon_Ceramic.icon/Assets/AltForgeCeramic.png"), 1024)

mac_icons = {
  "Icon@16.png" => 16,
  "Icon@32-1.png" => 32,
  "Icon@32.png" => 32,
  "Icon@64.png" => 64,
  "Icon@128.png" => 128,
  "Icon@256-1.png" => 256,
  "Icon@256.png" => 256,
  "Icon@512-1.png" => 512,
  "Icon@512.png" => 512,
  "Icon@1024.png" => 1024
}

mac_icons.each do |filename, size|
  resize_png(APP_ICON, File.join(ROOT, "AltServer/Assets.xcassets/AppIcon.appiconset", filename), size)
end

resize_cropped_png(TEMPLATE_ICON, File.join(ROOT, "AltServer/Assets.xcassets/MenuBarIcon.imageset/MenuBar@19.png"), 19, MENU_BAR_CROP_SIZE)
resize_cropped_png(TEMPLATE_ICON, File.join(ROOT, "AltServer/Assets.xcassets/MenuBarIcon.imageset/MenuBar@38.png"), 38, MENU_BAR_CROP_SIZE)
resize_png(TEMPLATE_ICON, File.join(ROOT, "AltWidget/Assets.xcassets/SmallIcon.imageset/AltForgeSmallIcon.png"), 512)
resize_png(APP_ICON, File.join(ROOT, "AltWidget/Assets.xcassets/AltForge.imageset/AltForge@2x.png"), 120)
resize_png(APP_ICON, File.join(ROOT, "AltWidget/Assets.xcassets/AltForge.imageset/AltForge@3x.png"), 180)

write_ico(APP_ICON, File.join(ROOT, "AltServer-Windows/Resources/Icon.ico"), [16, 32, 48, 256])
write_ico(APP_ICON, File.join(ROOT, "AltServer-Windows/AltServer/MenuBarIcon.ico"), [16, 19, 24, 32, 48])

puts "Generated AltForge platform brand assets."
