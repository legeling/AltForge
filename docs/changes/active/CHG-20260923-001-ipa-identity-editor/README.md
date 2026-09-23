# CHG-20260923-001: IPA identity editing and installed-app rename

- Status: Implemented locally; iOS platform build and physical-device acceptance pending
- Mapping: FR-047 -> DES-032 -> TEST-046 -> T-045

## Goal

After selecting a local IPA or import link, show its app name, bundle ID, version and extension count. The user can install it unchanged or edit its display name and bundle ID independently before the existing signing and installation flow. The original IPA must remain untouched. A distinct bundle ID should make a second managed installation possible without overwriting the first AltForge-managed copy. An already installed, active sideloaded app can also be renamed from My Apps, with its home-screen name and managed record updated together.

## Scope and decisions

- The editor operates on the already extracted temporary `.app`, before App ID/profile registration. Direct installation leaves the app metadata unchanged.
- Renaming an installed sideloaded app copies its refresh cache into a temporary `.app`, changes only the display name and reinstalls through AppManager with the same bundle ID. This path disables AppManager's early cache replacement and swaps in the temporary edited bundle only after device installation succeeds. A missing cache requires IPA reimport; a failed installation leaves the saved cache untouched. Changing an installed app's bundle ID in place is not offered because it is a new installation identity.
- Edit the main `Info.plist`, localized `InfoPlist.strings` display names and retained extension bundle IDs, then reload `ALTApplication` so signing and tracking use the edited identity. An extension whose ID is outside the original app's prefix is placed under the edited app's prefix with its complete old ID as suffix. Existing signing, provisioning, source verification, and install receipt paths remain authoritative.
- Validate reverse-DNS bundle ID characters and reject case-only identity changes or AltForge's own ID. Preserve unrelated plist keys and formats where supported. Stage all plist mutations before writing; failure aborts installation and the temporary directory is removed.
- App Group, Keychain, APNs and server-side account behaviors may remain tied to the original application. The UI explains that changing the ID can affect login, shared data and notifications; it does not claim those capabilities will work for every third-party app. No plug-in injection or security-check bypass is part of this change.

## Open-source references

- SideStore signs the main app and extensions against their final identifiers: https://github.com/SideStore/SideStore/blob/develop/SideStore/Core/Operations/PipelineOperations/ResignAppOperation.swift
- fastlane's re-signing script exposes separate bundle ID/display-name edits and warns that its bundle ID flag does not modify extensions: https://github.com/fastlane/fastlane/blob/master/sigh/lib/assets/resign.sh
- zsign exposes bundle ID and display-name options while re-signing: https://github.com/zhlynn/zsign

## Acceptance

1. Direct installation follows the existing path without rewriting the extracted bundle.
2. Editing to a distinct ID changes main/retained-extension identities and the display name, including existing localized names, before profiles and signing are requested.
3. Invalid IDs, unreadable localization metadata and cancellation stop before signing; the original IPA is never rewritten, and the temporary edited bundle is discarded on failure.
4. Local synthetic fixture tests and an iOS Simulator build pass. A sanitized physical-device smoke must confirm parallel installation, separate My Apps records and refresh before claiming the feature fully accepted.
5. Renaming one installed copy changes its home-screen and My Apps names without changing its bundle ID or the other copy. Missing cached files and failed reinstalls leave the prior installation intact.

## Validation

- 2026-09-23: The actual `IPAIdentityEditor.swift` compiled with the macOS Swift compiler against minimal local model stubs. A synthetic `.app` harness passed five checks: no-op identity, edited main/extension IDs, Unicode/localized name, malformed ID rejection, and malformed localization rejection without writing the main plist. The harness lived in a task-owned temporary directory and is not a substitute for iOS XCTest.
- `swiftc -frontend -parse` passed for the edited app/controller/test files; `jq empty` passed for the string catalog; `plutil -lint` passed for the Xcode project; `ruby Scripts/test_repository_contract.rb` and `git diff --check` passed.
- 2026-09-23 follow-up: Installed-app rename was added using the same editor and AppManager reinstall path. A fourth XCTest case covers a name-only edit across two localizations and the deferred cache swap. The actual editor source also passed a macOS Swift synthetic harness for these cases; the new XCTest and rename/reinstall flow have not run on iOS or a device.
- `xcodebuild` could not find an eligible iOS destination because this Xcode installation reports iOS 26.5 platform not installed, even though its SDK directory exists. No Simulator runtime is installed. The four new XCTest cases, iOS target build, edited IPA signing, side-by-side device installation, rename and refresh remain unverified.
- No third-party IPA or Apple credentials are stored in the repository. No version, tag or release was changed.
