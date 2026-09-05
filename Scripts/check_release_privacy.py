#!/usr/bin/env python3
"""Check Classic IPA privacy declarations without extracting or executing the app."""

import argparse
import json
from pathlib import Path, PurePosixPath
import plistlib
import re
import stat
import zipfile


POLICY = Path(__file__).resolve().parent.parent / "Release" / "app-permissions.json"
MAIN_INFO = "Payload/AltStore.app/Info.plist"
EXTENSION_INFO = re.compile(r"Payload/AltStore\.app/PlugIns/[^/]+\.appex/Info\.plist")
PRIVACY_KEY = re.compile(r"(?:NS)?(.+)UsageDescription.*", re.DOTALL)
MAX_INFO_SIZE = 2 * 1024 * 1024


def load_permissions(path, source=False):
    if Path(path).stat().st_size > 1024 * 1024:
        raise ValueError("Permission metadata is too large")
    with Path(path).open(encoding="utf-8") as handle:
        value = json.load(handle)
    if source:
        if not isinstance(value, dict) or value.get("identifier") != "com.legeling.AltForge.Source":
            raise ValueError("Source identity does not match AltForge")
        apps = value.get("apps")
        if not isinstance(apps, list):
            raise ValueError("Source apps must be an array")
        matches = [app for app in apps if isinstance(app, dict) and app.get("bundleIdentifier") == "com.legeling.AltForge"]
        if len(matches) != 1:
            raise ValueError("Source must declare exactly one AltForge app")
        value = matches[0].get("appPermissions")
    if not isinstance(value, dict) or not isinstance(value.get("privacy"), dict):
        raise ValueError("Missing privacy permission map")
    privacy = value["privacy"]
    if len(privacy) > 128 or any(not isinstance(key, str) or not PRIVACY_KEY.fullmatch(key)
                               or not isinstance(description, str) or not description.strip()
                               for key, description in privacy.items()):
        raise ValueError("Privacy permissions require usage-description keys and nonempty descriptions")
    return privacy


def verify_ipa(ipa_path, privacy):
    if Path(ipa_path).stat().st_size > 1024 * 1024 * 1024:
        raise ValueError("Release IPA exceeds the verification size limit")
    missing = []
    checked = 0
    with zipfile.ZipFile(ipa_path) as archive:
        entries = archive.infolist()
        if len(entries) > 20000:
            raise ValueError("Too many IPA entries")
        seen = set()
        total_info_size = 0
        for info in entries:
            name = info.filename
            if "\\" in name or name.startswith("/") or ".." in PurePosixPath(name).parts:
                raise ValueError("Unsafe IPA path")
            if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", name) and name != MAIN_INFO:
                raise ValueError("Unexpected top-level app")
            if name != MAIN_INFO and not EXTENSION_INFO.fullmatch(name):
                continue
            if name in seen or stat.S_ISLNK(info.external_attr >> 16):
                raise ValueError("Duplicate or symbolic-link app Info.plist")
            seen.add(name)
            checked += 1
            total_info_size += info.file_size
            if checked > 129 or info.file_size > MAX_INFO_SIZE or total_info_size > 8 * 1024 * 1024:
                raise ValueError("App metadata exceeds verification limits")
            with archive.open(info) as handle:
                data = handle.read(MAX_INFO_SIZE + 1)
            if len(data) > MAX_INFO_SIZE:
                raise ValueError("App Info.plist is too large")
            value = plistlib.loads(data)
            if not isinstance(value, dict):
                raise ValueError("App Info.plist must be a dictionary")
            if name == MAIN_INFO and value.get("CFBundleIdentifier") != "com.legeling.AltForge":
                raise ValueError("IPA identity does not match AltForge")
            for key in value:
                match = PRIVACY_KEY.fullmatch(key)
                if not match:
                    continue
                # Our reviewed release policy uses full keys, including any platform suffix.
                if key not in privacy:
                    missing.append(f"{name}: {key}")
        if MAIN_INFO not in seen:
            raise ValueError("IPA is missing the main app Info.plist")
    if missing:
        raise ValueError("Undeclared IPA privacy permissions:\n" + "\n".join(sorted(missing)))
    return checked


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ipa", type=Path, required=True)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--permissions", type=Path, default=POLICY)
    group.add_argument("--source", type=Path)
    args = parser.parse_args()
    try:
        privacy = load_permissions(args.source or args.permissions, source=args.source is not None)
        count = verify_ipa(args.ipa, privacy)
    except (OSError, ValueError, zipfile.BadZipFile, RuntimeError, plistlib.InvalidFileException) as error:
        parser.exit(1, f"Release privacy verification failed: {error}\n")
    print(f"Release privacy declarations cover {count} app/extension bundles")


if __name__ == "__main__":
    main()
