#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/package_macos_dmg.sh --app PATH --output PATH [--ad-hoc-sign]

Packages AltForge Server.app in a compressed DMG with an Applications shortcut.
Use --ad-hoc-sign to seal the complete app bundle without claiming a Developer ID identity.
EOF
}

app_path=""
output_path=""
ad_hoc_sign=false

while (($# > 0)); do
  case "$1" in
    --app)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      app_path="$2"
      shift 2
      ;;
    --output)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      output_path="$2"
      shift 2
      ;;
    --ad-hoc-sign)
      ad_hoc_sign=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

[[ -n "$app_path" && -n "$output_path" ]] || { usage >&2; exit 64; }
[[ -d "$app_path" ]] || { echo "Application bundle not found: $app_path" >&2; exit 66; }
[[ "$output_path" == *.dmg ]] || { echo "Output path must end in .dmg" >&2; exit 64; }
[[ ! -e "$output_path" ]] || { echo "Refusing to overwrite existing output: $output_path" >&2; exit 73; }
command -v ditto >/dev/null || { echo "ditto is required" >&2; exit 69; }
command -v hdiutil >/dev/null || { echo "hdiutil is required" >&2; exit 69; }
command -v osascript >/dev/null || { echo "osascript is required" >&2; exit 69; }

output_directory="$(dirname "$output_path")"
mkdir -p "$output_directory"
output_directory="$(cd "$output_directory" && pwd -P)"
output_path="$output_directory/$(basename "$output_path")"
app_path="$(cd "$(dirname "$app_path")" && pwd -P)/$(basename "$app_path")"

staging_root="$(mktemp -d "${TMPDIR:-/tmp}/altforge-dmg.XXXXXX")"
content_root="$staging_root/content"
volume_name="AltForge Server"
mount_point="/Volumes/$volume_name"
read_write_image="$staging_root/AltForge-Server-read-write.dmg"
attached_device=""

detach_image() {
  local device="$attached_device"
  [[ -n "$device" ]] || return 0

  for _ in 1 2 3 4 5; do
    if hdiutil detach "$device" >/dev/null 2>&1; then
      attached_device=""
      return 0
    fi
    sleep 1
  done

  hdiutil detach -force "$device" >/dev/null
  attached_device=""
}

cleanup() {
  if [[ -n "$attached_device" ]]; then
    detach_image >/dev/null 2>&1 || true
  fi
  find "$staging_root" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT INT TERM

mkdir -p "$content_root"
[[ ! -e "$mount_point" ]] || { echo "A volume named $volume_name is already mounted. Eject it and try again." >&2; exit 75; }

staged_app="$content_root/AltForge Server.app"
ditto "$app_path" "$staged_app"
ln -s /Applications "$content_root/Applications"

if [[ "$ad_hoc_sign" == true ]]; then
  command -v codesign >/dev/null || { echo "codesign is required for --ad-hoc-sign" >&2; exit 69; }
  codesign --force --deep --sign - --timestamp=none "$staged_app"
  codesign --verify --deep --strict --verbose=2 "$staged_app"
fi

hdiutil create \
  -volname "$volume_name" \
  -srcfolder "$content_root" \
  -format UDRW \
  "$read_write_image"

hdiutil attach \
  -readwrite \
  -noverify \
  -nobrowse \
  "$read_write_image" >/dev/null
[[ -d "$mount_point" ]] || { echo "Unable to locate the mounted DMG volume." >&2; exit 74; }
attached_device="$(df "$mount_point" | tail -n 1 | awk '{print $1}')"
[[ "$attached_device" == /dev/* ]] || { echo "Unable to identify mounted DMG device." >&2; exit 74; }

osascript - "$mount_point" <<'APPLESCRIPT'
on run arguments
  set mountedFolder to POSIX file (item 1 of arguments) as alias

  tell application "Finder"
    open mountedFolder
    set dmgWindow to container window of mountedFolder
    set current view of dmgWindow to icon view
    set toolbar visible of dmgWindow to false
    set statusbar visible of dmgWindow to false
    set pathbar visible of dmgWindow to false
    set bounds of dmgWindow to {120, 120, 640, 420}

    set viewOptions to icon view options of dmgWindow
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 88
    set text size of viewOptions to 14

    set position of item "AltForge Server.app" of mountedFolder to {145, 135}
    set position of item "Applications" of mountedFolder to {375, 135}
    set extension hidden of item "AltForge Server.app" of mountedFolder to true

    update mountedFolder without registering applications
    close dmgWindow
    delay 2
  end tell
end run
APPLESCRIPT

detach_image

hdiutil attach \
  -readonly \
  -noverify \
  -nobrowse \
  "$read_write_image" >/dev/null
[[ -d "$mount_point" ]] || { echo "Unable to locate the verification DMG volume." >&2; exit 74; }
attached_device="$(df "$mount_point" | tail -n 1 | awk '{print $1}')"
[[ "$attached_device" == /dev/* ]] || { echo "Unable to identify verification DMG device." >&2; exit 74; }
[[ -f "$mount_point/.DS_Store" ]] || { echo "Finder did not persist the DMG window layout." >&2; exit 74; }
detach_image

hdiutil convert \
  "$read_write_image" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$output_path"
hdiutil verify "$output_path"

echo "Created $output_path"
