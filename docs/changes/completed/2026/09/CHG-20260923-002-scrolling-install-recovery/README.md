# CHG-20260923-002: Scrolling install status and device-confirmed recovery

- Status: Published in v2.5.1; physical-device acceptance tracked by ISSUE-20260905-003
- Mapping: FR-048 -> DES-033 -> TEST-047 -> T-046

## Problem and decision

The installation panel was a fixed overlay, so scrolling My Apps left it floating over unrelated content. A backgrounded or locked iOS app can lose the final installation response; local UTI registration may not become visible promptly even when the app launches on the device. App ID registration alone is not evidence of installation.

The panel becomes a normal list header at the top. Existing receipt-based recovery remains the only persistence path. If foreground local checks are inconclusive, an updated Server reports which requested resigned bundle IDs are actually installed through its existing installation_proxy browser. A positive match restores the missing management record and can update a visible pending result. No match, old Server, offline device, or malformed response leaves the receipt and cache intact. No Core Data migration or unrestricted background mode is added.

## Acceptance

1. The installation panel begins at the top of My Apps, has no manual content inset, and moves with collection-view scrolling on a small viewport.
2. Protocol requests and responses round-trip; macOS and Windows Server use the same installed-bundle-ID contract. The client cannot restore IDs outside its pending receipt set.
3. Positive UTI or device confirmation restores one missing record idempotently; failed save keeps the receipt, and a live installation is not overwritten.
4. A physical-device run must cover install, lock/background, resume, My Apps appearance and refresh, plus device disconnected/old Server behavior. An iOS background task does not promise indefinite execution after lock or force quit.

## Verification and rollback

- 2026-09-23: `swiftc -frontend -parse` passed for edited Swift sources, `jq empty` passed for the App catalog, `git diff --check` passed, and `ruby Scripts/test_repository_contract.rb` passed after changing the prior fixed-overlay contract.
- macOS AltServer Debug build passed with signing disabled. It reported pre-existing Carthage search-path, Sendable and deprecated-alert warnings. Task-owned DerivedData was removed afterward.
- iOS Simulator build could not start: Xcode reports that iOS 26.5 platform/runtime is not installed, despite an SDK directory being present. The added XCTest cases have not executed. This macOS host cannot perform a Windows MSBuild; the Windows branch and locked-device install/refresh still need CI and sanitized physical-device acceptance.
- The v2.5.0 tag CI passed the Windows build and compiled iOS, including the new recovery protocol. Its Apple test job failed on an IPA editor fixture, so it did not produce a Draft or public Release. The new recovery tests selected by CI passed; locked-device install and refresh still require physical-device acceptance.
- 2026-09-23: Manual three-platform preflight [run 35828141331](https://github.com/legeling/AltForge/actions/runs/35828141331) passed selected iOS XCTest, Apple artifact checks and Windows build after the separate editor-test fix. Locked-device installation and refresh remain in ISSUE-20260905-003.
- The v2.5.1 tag [release run 35830942397](https://github.com/legeling/AltForge/actions/runs/35830942397) passed and the Draft artifacts were downloaded and checksummed before public release. Locked-device acceptance remains open.
- Revert this change's list-header and status-query code together to return to the prior fixed panel and UTI-only recovery. Existing receipts and Core Data records remain readable; no migration is required.
