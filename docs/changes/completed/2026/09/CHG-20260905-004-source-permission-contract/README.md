# CHG-20260905-004: Source privacy declarations and verification error 201

- Status: Implementation and release completed in v2.4.7; real-device update acceptance remains open
- Mapping: FR-046 -> DES-031 -> TEST-045 -> T-044
- Issue: ISSUE-20260905-004

## Evidence

After v2.4.6, the user reports an in-app update failing at verification with AltStore.VerificationError 201 after Apple authentication succeeds. Code 201 is undeclaredPermissions, not a bad password, hash mismatch or outdated desktop server. The published v2.4.6 apps.json has an empty privacy map, while the tagged AltStore Info.plist declares NSLocalNetworkUsageDescription. The metadata generator hard-coded privacy to an empty object. Existing 28 XCTest and checksum/build gates did not exercise this producer-consumer contract. A generic NSError 201 also received a misleading re-download suggestion.

## Decisions and scope

- A small reviewed Release/app-permissions.json owns existing entitlement declarations and the local-network privacy description. The generator copies this policy into appPermissions rather than copying an old source's omission or inventing permissions from a binary.
- A Python standard-library ZIP/plist checker reads only the main Info.plist and direct app extensions, without extracting or executing code. Missing privacy declarations fail before Apple upload and again against generated apps.json before Draft creation. This is a privacy-key gate, not a new entitlement/signature/permission-review engine; existing client verification remains unchanged.
- Bound ZIP entries, metadata count and decompressed plist bytes; reject missing/wrong main identities, malformed or duplicate metadata, symbolic-link metadata and traversal paths. It scans O(archive entries + metadata bytes), at most 129 bundle plists and 8 MiB of metadata, with one bounded plist buffer at a time and no network requests.
- Code 201 receives a specific localized explanation and source-maintainer recovery instructions. Existing permission details and original domain/code remain available; hash errors and unrelated error domains must keep their behavior. Shared copy is synchronized across iOS and macOS catalogs.
- Do not change Apple authentication, signing, Core Data, installation recovery, selected theme, safety checks, dependency versions or the public 2.4.6 tag/assets. No commit/push/release is authorized by this implementation request. A future release/source publication is required before old clients can consume corrected declarations.

## Verification plan

Run Ruby generation/repository/version contracts and Python privacy regressions after the complete batch. Prove the old empty source fails and the reviewed declaration passes for a real downloaded v2.4.6 IPA, as well as synthetic extension/malformed/oversized/path fixtures. Verify generated source against the same IPA. Run the targeted NSError XCTest and iOS build, plus macOS build for the shared presentation path. Real-device source refresh and update remain an acceptance gap; do not claim a successful device update from these gates.

## Local verification

- Ruby metadata, repository and version contracts, shell syntax and diff checks passed. Seven Python regressions passed, including empty/fixed source, extension privacy, suffix keys, invalid policy, bundle-count bound, malformed/missing/duplicate/oversized plists and unsafe/symlink metadata.
- Downloaded the original v2.4.6 IPA through its CI artifact and source from the published release. Confirmed SHA-256 values `e6df338c393be50af35301cf12e9e10a91963e720eb9a8d5f16a1dd279000293` (IPA) and `9b5ef52e35c6b69ba294b96e26250a09e2ae7a9fa6bfd22a5c61aba6462e9aa7` (source) match the release record. The original source fails with missing NSLocalNetworkUsageDescription. Both reviewed policy and the actual regenerated source pass against that same IPA, covering two app/extension bundles. No release assets were modified.
- Four iOS Simulator XCTest passed, zero failures/skips: specific 201 copy/details/wrapper/103 behavior, all known error presentations and two adjacent authentication presentations. Xcode 26.6 / iOS Simulator 26.5 built the app and test host. The macOS Debug build also passed with the shared presentation and catalog changes. Existing Roxas/Carthage/deprecation warnings remain; physical-device updating and Windows build were not performed.
- A fixed luna_worker (gpt-5.6-luna/max) implemented only 201 presentation, its iOS/macOS catalog entries and the focused XCTest. The primary agent owned policy, release gates, fixture validation and docs, reviewed the worker diff and ran unified verification. No GUI or user account was controlled, and no commit, push, version bump or release mutation was performed.

## Release authorization

The user subsequently requested publication. Prepare a new v2.4.7 tag with synchronized iOS/macOS/Windows versions, preserving existing public v2.4.6 assets. The tag workflow must run all 29 selected XCTest, seven Python privacy fixtures, three platform builds and the real-IPA/generated-source privacy gate. Verify downloaded package identities, versions, checksums and privacy declarations before making the Draft public. Real-device source refresh/update remains pending.

## Release convergence

Published v2.4.7 (build 25) at 2026-09-05 16:02:46 Asia/Shanghai. Tag commit `a1a1172a4d5059ab5a5c4caf8d1eda7a5e65b586`, workflow `33952693053`: all 29 XCTest, seven Python fixtures, three platform packaging jobs and the generated-source/IPA privacy gate passed. Three binary downloads came from the same CI run's artifacts, metadata/checksums from Draft; all nine files matched Draft sizes/digests and eight manifest checksums passed. Local Apple identity/version/architecture/signature, Windows version and new IPA/source privacy checks passed. Public latest source is byte-identical to verified Draft and passes the same privacy gate; all three package URLs return HTTP 200. Physical-device updating remains in ISSUE-20260905-004; existing public v2.4.6 assets were not overwritten.

## Upgrade and rollback

There is no schema or protocol migration. Correct source declarations are understood by old clients after a source refresh; the new error copy requires updating the client binary. Do not overwrite the published tag or release files without explicit release authorization and refreshed checksums. Reverting the source policy restores the known 201 failure, not a safe rollback. Preserve the installed app and its data; no uninstall is required.
