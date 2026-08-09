#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/package_macos_dmg.sh --app PATH --output PATH [--ad-hoc-sign]

Packages AltServer.app in a compressed DMG with an Applications shortcut.
Use --ad-hoc-sign only for local validation; release artifacts stay unsigned.
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

output_directory="$(dirname "$output_path")"
mkdir -p "$output_directory"
output_directory="$(cd "$output_directory" && pwd -P)"
output_path="$output_directory/$(basename "$output_path")"
app_path="$(cd "$(dirname "$app_path")" && pwd -P)/$(basename "$app_path")"

staging_root="$(mktemp -d "${TMPDIR:-/tmp}/altforge-dmg.XXXXXX")"
cleanup() {
  find "$staging_root" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT INT TERM

staged_app="$staging_root/AltForge Server.app"
ditto "$app_path" "$staged_app"
ln -s /Applications "$staging_root/Applications"

if [[ "$ad_hoc_sign" == true ]]; then
  command -v codesign >/dev/null || { echo "codesign is required for --ad-hoc-sign" >&2; exit 69; }
  codesign --force --deep --sign - --timestamp=none "$staged_app"
  codesign --verify --deep --strict --verbose=2 "$staged_app"
fi

hdiutil create \
  -volname "AltForge AltServer" \
  -srcfolder "$staging_root" \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$output_path"
hdiutil verify "$output_path"

echo "Created $output_path"
