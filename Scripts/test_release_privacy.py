#!/usr/bin/env python3

import json
from pathlib import Path
import plistlib
import tempfile
import unittest
import warnings
import zipfile

from check_release_privacy import MAIN_INFO, MAX_INFO_SIZE, POLICY, load_permissions, verify_ipa


class ReleasePrivacyTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="altforge-privacy-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.ipa = self.root / "AltForge.ipa"
        self.privacy = load_permissions(POLICY)
        self.main = {"CFBundleIdentifier": "com.legeling.AltForge",
                     "NSLocalNetworkUsageDescription": "Find the signing server"}

    def write_ipa(self, entries=None):
        with zipfile.ZipFile(self.ipa, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for name, content in entries or [(MAIN_INFO, self.main)]:
                archive.writestr(name, plistlib.dumps(content, fmt=plistlib.FMT_BINARY) if isinstance(content, dict) else content)

    def test_original_empty_privacy_source_fails_and_reviewed_policy_passes(self):
        self.write_ipa()
        with self.assertRaisesRegex(ValueError, "NSLocalNetworkUsageDescription"):
            verify_ipa(self.ipa, {})
        self.assertEqual(verify_ipa(self.ipa, self.privacy), 1)

    def test_extension_privacy_cannot_be_silently_added(self):
        self.write_ipa([(MAIN_INFO, self.main),
                        ("Payload/AltStore.app/PlugIns/Widget.appex/Info.plist", {"NSCameraUsageDescription": "Camera"})])
        with self.assertRaisesRegex(ValueError, "Widget.appex/Info.plist: NSCameraUsageDescription"):
            verify_ipa(self.ipa, self.privacy)
        self.assertEqual(verify_ipa(self.ipa, {**self.privacy, "NSCameraUsageDescription": "Reviewed camera use"}), 2)

    def test_usage_description_suffix_requires_declaration(self):
        self.main["NSMicrophoneUsageDescription~ipad"] = "Microphone"
        self.write_ipa()
        with self.assertRaisesRegex(ValueError, "NSMicrophoneUsageDescription~ipad"):
            verify_ipa(self.ipa, self.privacy)

    def test_source_identity_and_missing_permission_map_fail_closed(self):
        path = self.root / "apps.json"
        source = {"identifier": "com.legeling.AltForge.Source", "apps": [
            {"bundleIdentifier": "com.legeling.AltForge", "appPermissions": {"privacy": self.privacy}}]}
        path.write_text(json.dumps(source))
        self.assertEqual(load_permissions(path, source=True), self.privacy)
        source["apps"][0]["appPermissions"]["privacy"] = {}
        path.write_text(json.dumps(source))
        self.write_ipa()
        with self.assertRaisesRegex(ValueError, "Undeclared"):
            verify_ipa(self.ipa, load_permissions(path, source=True))
        source["identifier"] = "wrong"
        path.write_text(json.dumps(source))
        with self.assertRaisesRegex(ValueError, "identity"):
            load_permissions(path, source=True)

    def test_malformed_missing_duplicate_and_oversized_plists(self):
        cases = [([(MAIN_INFO, b"not plist")], plistlib.InvalidFileException),
                 ([("unrelated.txt", b"fixture")], ValueError),
                 ([(MAIN_INFO, self.main), (MAIN_INFO, self.main)], ValueError),
                 ([(MAIN_INFO, b"x" * (MAX_INFO_SIZE + 1))], ValueError),
                 ([(MAIN_INFO, {"CFBundleIdentifier": "wrong"})], ValueError)]
        for entries, error in cases:
            with self.subTest(entries=[entry[0] for entry in entries]):
                with warnings.catch_warnings():
                    warnings.simplefilter("ignore", UserWarning)
                    self.write_ipa(entries)
                with self.assertRaises(error):
                    verify_ipa(self.ipa, self.privacy)

    def test_unsafe_and_symbolic_link_metadata(self):
        self.write_ipa([(MAIN_INFO, self.main), ("../escape", b"fixture")])
        with self.assertRaisesRegex(ValueError, "Unsafe"):
            verify_ipa(self.ipa, self.privacy)
        entry = zipfile.ZipInfo(MAIN_INFO)
        entry.external_attr = 0o120777 << 16
        self.write_ipa([(entry, b"outside")])
        with self.assertRaisesRegex(ValueError, "symbolic-link"):
            verify_ipa(self.ipa, self.privacy)

    def test_invalid_policy_and_bundle_count_limit(self):
        path = self.root / "permissions.json"
        for value in [{}, {"privacy": []}, {"privacy": {"NSCameraUsageDescription": ""}},
                      {"privacy": {"invalid": "description"}}]:
            with self.subTest(value=value):
                path.write_text(json.dumps(value))
                with self.assertRaises(ValueError):
                    load_permissions(path)
        entries = [(MAIN_INFO, self.main)] + [
            (f"Payload/AltStore.app/PlugIns/Extension{index}.appex/Info.plist", {}) for index in range(129)]
        self.write_ipa(entries)
        with self.assertRaisesRegex(ValueError, "limits"):
            verify_ipa(self.ipa, self.privacy)


if __name__ == "__main__":
    unittest.main()
