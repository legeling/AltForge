#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/verify_apple_release_artifacts.sh --artifacts PATH --version X.Y.Z --build NUMBER

Verifies the non-Developer-ID iOS IPA and macOS DMG produced by the tag release workflow.
EOF
}

artifacts_path=""
version=""
build_number=""

while (($# > 0)); do
  case "$1" in
    --artifacts)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      artifacts_path="$2"
      shift 2
      ;;
    --version)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      version="$2"
      shift 2
      ;;
    --build)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      build_number="$2"
      shift 2
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

[[ -n "$artifacts_path" && -n "$version" && -n "$build_number" ]] || { usage >&2; exit 64; }
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Version must use numeric X.Y.Z form." >&2; exit 64; }
[[ "$build_number" =~ ^[0-9]+$ ]] || { echo "Build must be numeric." >&2; exit 64; }

for command in codesign hdiutil lipo plutil unzip; do
  command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 69; }
done

artifacts_path="$(cd "$artifacts_path" && pwd -P)"
ipa_path="$artifacts_path/AltForge.ipa"
dmg_path="$artifacts_path/AltForge-AltServer-macOS.dmg"
[[ -s "$ipa_path" ]] || { echo "Missing or empty IPA: $ipa_path" >&2; exit 66; }
[[ -s "$dmg_path" ]] || { echo "Missing or empty DMG: $dmg_path" >&2; exit 66; }

temporary_root="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/altforge-apple-artifacts.XXXXXX")"
mount_path="$temporary_root/mount"
mounted=false
cleanup() {
  if [[ "$mounted" == true ]]; then
    hdiutil detach "$mount_path" >/dev/null 2>&1 || true
  fi
  find "$temporary_root" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT INT TERM

ipa_info="$temporary_root/AltStore-Info.plist"
unzip -p "$ipa_path" Payload/AltStore.app/Info.plist > "$ipa_info"
plutil -lint "$ipa_info" >/dev/null
[[ "$(plutil -extract CFBundleIdentifier raw "$ipa_info")" == "com.legeling.AltForge" ]] || { echo "IPA bundle identifier is incorrect." >&2; exit 65; }
[[ "$(plutil -extract CFBundleShortVersionString raw "$ipa_info")" == "$version" ]] || { echo "IPA version is incorrect." >&2; exit 65; }
[[ "$(plutil -extract CFBundleVersion raw "$ipa_info")" == "$build_number" ]] || { echo "IPA build number is incorrect." >&2; exit 65; }

hdiutil verify "$dmg_path" >/dev/null
mkdir -p "$mount_path"
hdiutil attach -readonly -nobrowse -mountpoint "$mount_path" "$dmg_path" >/dev/null
mounted=true

app_path="$mount_path/AltForge Server.app"
[[ -d "$app_path" ]] || { echo "DMG does not contain AltForge Server.app." >&2; exit 65; }
[[ -L "$mount_path/Applications" && "$(readlink "$mount_path/Applications")" == "/Applications" ]] || { echo "DMG Applications shortcut is incorrect." >&2; exit 65; }

mac_info="$app_path/Contents/Info.plist"
[[ "$(plutil -extract CFBundleIdentifier raw "$mac_info")" == "com.legeling.AltForge.AltServer" ]] || { echo "macOS bundle identifier is incorrect." >&2; exit 65; }
[[ "$(plutil -extract CFBundleDisplayName raw "$mac_info")" == "AltForge Server" ]] || { echo "macOS display name is incorrect." >&2; exit 65; }
[[ "$(plutil -extract CFBundleShortVersionString raw "$mac_info")" == "$version" ]] || { echo "macOS version is incorrect." >&2; exit 65; }
[[ "$(plutil -extract CFBundleVersion raw "$mac_info")" == "$build_number" ]] || { echo "macOS build number is incorrect." >&2; exit 65; }

executable="$app_path/Contents/MacOS/AltServer"
architectures=" $(lipo -archs "$executable") "
[[ "$architectures" == *" arm64 "* && "$architectures" == *" x86_64 "* ]] || { echo "macOS executable is not Universal (arm64 + x86_64)." >&2; exit 65; }

codesign --verify --deep --strict --verbose=2 "$app_path"
signature_details="$(codesign -dvvv "$app_path" 2>&1)"
if [[ "$signature_details" != *"Signature=adhoc"* || "$signature_details" != *"TeamIdentifier=not set"* || "$signature_details" == *"Authority="* ]]; then
  echo "Release workflow produced a macOS app outside the reviewed ad-hoc signing policy." >&2
  exit 65
fi
if codesign -d "$dmg_path" >/dev/null 2>&1; then
  echo "Release workflow unexpectedly produced a signed DMG without the Developer ID release path being configured." >&2
  exit 65
fi

echo "Apple release artifacts passed structure, identity, version, architecture, deep ad-hoc signature, and non-Developer-ID policy checks."
