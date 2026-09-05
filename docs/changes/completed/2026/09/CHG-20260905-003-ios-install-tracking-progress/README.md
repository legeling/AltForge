# CHG-20260905-003: iOS installation tracking, progress and theme consistency

- Status: Implementation delivered in v2.4.6; real-device acceptance remains open in ISSUE-20260905-003
- Mapping: FR-044/FR-045 -> DES-030 -> TEST-043/TEST-044 -> T-043

## Evidence and scope

The user reports that a newly installed app opens on the device but is absent from My Apps, while an App ID exists. The IPA-import path shows only a spinning plus button, and the phone locks before receiving a visible result. App IDs are developer registrations, not proof of a local managed installation.

Code review found three independent risks: InstalledApp was saved only after the final installation callback; background expiration cancelled InstallAppOperation without finishing its asynchronous wait; AppManager.update deleted records based only on absent UTI registration and subsequently deleted their cached app bundles. A 92-point progress panel was anchored to the scroll frame rather than the navigation-safe area, and could overlap navigation or truncate Dynamic Type. These are code-confirmed paths, not a claim to have reproduced the user's exact device sequence.

## Decisions

### Background-specific follow-up

The user clarified that the failure occurs specifically after placing AltForge in the background: device installation completes, but tracking does not. The first local receipt patch still reconciled only once on return and did not defer to a live producer. A delayed system registration could therefore remain undiscovered until another activation, while a concurrent final callback could contend with recovery.

- Reconcile on actual didBecomeActive and explicit AppManager updates, not only willEnterForeground. Coalesce requests, allow only one database pass at a time, stop scheduled checks on background entry and reject stale-generation callbacks. If registration or a live producer remains pending, retry locally after 1/2/5/10/20 seconds: at most six passes over approximately 38 seconds, with no Apple/server network requests. A later activation starts a new bounded window.
- Defer to active install/refresh producers and re-fetch before restoring a candidate whose initial snapshot was missing. Do not overwrite existing records. Directory cleanup must successfully enumerate children before deciding a cache has no app/receipt; an inaccessible directory is not empty.
- Protect management-state reads with the same progress lock used by writes. The pre-existing unlocked reader is now used by recovery on a background context and must not race progress dictionary mutation. Add a bounded concurrency smoke and source-contract assertion; do not describe this as Thread Sanitizer coverage.
- Correct the old interrupted-operation recovery text that instructed users to remove an already installed app. All supported translations for that text now preserve the device app and direct recovery/re-import without prior uninstallation.
- Add production-coordinator plus Core Data regression scenarios for background/foreground transitions, delayed registration, live-producer deferral, persisted list recovery, coalescing, one in-flight pass, stale callbacks and bounded retries. These are deterministic simulations, not a claim of physical-device acceptance.

### Upstream evidence, 2026-09-05

- AltStore marketplace `56854e66fef2eac32dad88dcbad1dc131d430e60`: InstallAppOperation still delivers success after the final response, and the base Operation cancels on background-task expiration. The inspected code does not contain a durable general-app recovery flow for the reported lost-callback sequence. https://github.com/altstoreio/AltStore/blob/56854e66fef2eac32dad88dcbad1dc131d430e60/AltStore/Operations/InstallAppOperation.swift
- AltStore #1329 remains open with a maintainer acknowledgement of an app installed from the source view not appearing in My Apps. That report is related symptom evidence, not an established background-install fix. https://github.com/altstoreio/AltStore/issues/1329
- SideStore develop `367bd8c98c466cdf335bc59ef6f42e19f7fe0b8f` writes StagedSelfReinstall.json before self-reinstallation and describes verifying a changed embedded profile at boot. This supports the stage/verify/recover principle, but is self-update-specific and uses a different pipeline/data model. No blanket PR merge or direct copy of its best-effort writes is claimed. https://github.com/SideStore/SideStore/blob/367bd8c98c466cdf335bc59ef6f42e19f7fe0b8f/SideStore/Core/Operations/PipelineOperations/InstallAppOperation.swift

### Installation and UI behavior

- Stage a bounded, versioned installation receipt in the existing private app cache before sending BeginInstallationRequest. It contains only metadata needed to reconstruct tracking, not passwords, private keys, tokens, anisette or provisioning-profile bodies. Save confirmed installations on their Core Data queue immediately, before cancellation can replace the operation result.
- On foreground reconciliation, only restore a missing record if the receipt is valid, the cached App.app exists and system UTI registration positively confirms the resigned bundle identity. Never infer success from App IDs or a negative registry lookup. Restored apps require full resigning on the next refresh because presence alone does not prove the interrupted version completed. Preserve existing records/versions and retain receipts until the database save succeeds.
- Do not automatically delete records on absent UTI. Retain orphan App.app caches and receipts; expose the existing explicitly confirmed Remove action in Release builds, clear recovery receipts during explicit removal, and explain that removing tracking/cache/backups does not uninstall the device app.
- Show IPA-import stage, bounded aggregate percentage, elapsed time, waiting state and a persistent success/failure result. Unknown waits do not invent advancing percentages. Cap the progress panel to 60 percent of the safe area and allow its contents to scroll at large text sizes; keep list insets synchronized.
- If a device-installation response is interrupted by timeout, connection loss or cancellation, show an unconfirmed result rather than asserting the app failed to install. The same errors before device installation and explicit Apple/server rejection retain their normal failure states. The details still expose the original diagnostic error.
- Main-thread reference-counted idle-timer leases cover manual app operations and IPA preparation, restoring the original value after success/failure/cancellation. This prevents automatic screen sleep, not manual locking or unlimited background execution. Finish installation waits on cancellation and after 180 seconds without a server response; retain the receipt because the device may still finish installing.
- Keep the existing UIKit theme system, SF Symbols and semantic danger/expiration colors. Remove fixed brand-red storyboard colors and update reused controls on theme changes. Do not recolor third-party icons or change the selected theme.

## Complexity and compatibility

No Core Data schema, signing protocol, crypto, Apple authentication, dependency, Windows or macOS changes. One receipt per app, at most 64 KiB and 128 extensions; atomic writes, bounded identifiers and symlink rejection. Reconciliation is O(number of cached apps + stored records), uses a set for membership and batches one Core Data save. No network discovery or device enumeration is added. Retaining unresolved caches deliberately trades disk space for preserving refresh data; explicit removal is the cleanup path.

## Verification plan

Test production receipt recovery with in-memory Core Data: no positive evidence, confirmed presence, idempotency, save failure/rollback, existing-record preservation, malformed/oversized/path/symlink inputs and receipt replacement. Test idle-timer lease restoration and concurrent leases. Render the progress component at small-phone/landscape/tablet widths, light/dark appearance and accessibility Dynamic Type; inspect bounds, buttons, terminal states and theme changes. Run repository/version/localization checks, then the selected hosted XCTest locally and an iOS build. Do not claim simulator fixtures prove device installation or background survival.

## Upgrade and rollback

No destructive database migration. Receipts are additive private cache files, and malformed receipts are ignored without deleting cached apps. Older versions ignore receipts but retain the unsafe UTI cleanup; returning to an older version can lose tracking again. Preserve device apps and IPA originals. For an app already omitted by an older version with no surviving receipt, import the same IPA under the same Apple ID/team to restore tracking without first uninstalling the device app. App IDs alone cannot reconstruct its signing metadata or refresh payload.

The user subsequently requested publishing the candidate before performing their own real-device installation test. v2.4.6 was published across iOS/macOS/Windows after tag CI and downloaded asset verification. Device acceptance remains open in ISSUE-20260905-003. No real device, account or user GUI was controlled during automated verification.

## Local verification, 2026-09-05

- Repository contract, version contract, Swift syntax and diff checks passed. The first build caught an incorrect Foundation file-protection option spelling; it was corrected to the SDK's completeFileProtectionUntilFirstUserAuthentication option before successful tests.
- Xcode 26.6 / iOS 26.5 Simulator: the 23 selected XCTest batch passed with zero failures/skips and built the iOS app, resources and test host. Receipt recovery/idempotency/save-failure/validation, cache retention, idle leases and theme controls were exercised without a real account.
- Added a full My Apps navigation-container test, bringing the Release selection to 24 distinct cases. A focused two-case layout run passed after strengthening actual window trait propagation and safe-area assertions; subsequent default-font preview and final layout checks also passed. The remaining unaffected cases were not needlessly rerun.
- Final follow-up corrected the authentication prompt's cached theme-color alias and added stage-specific unconfirmed-installation presentation. A final iOS Simulator build passed, followed by three focused outcome/navigation/layout tests with zero failures/skips. The Release selection now contains 25 distinct cases, all covered by the successful local batches; no claim is made that all 25 ran in one invocation. Checked source contracts again after the final changes.
- Actual UIKit attachments cover 320/375/844-point component widths, light/dark modes, maximum accessibility text and a normal-size Chinese progress sample. Traits are asserted rather than assumed. The real navigation container keeps the panel below the bar, below 220 points at normal size, and restores its list insets after dismissal. Inspected rendered normal-size and accessibility light/dark images; no overlapping text/buttons or constraint failures were found in those fixtures. Long application names retain the existing two-line truncation policy.
- Local builds use four jobs, no parallel tests, a dedicated simulator and bounded 600/900-second processes. The normal initial fixture-only screenshot did not actually apply dark/large-text traits; its test was corrected and rerun, and only the corrected results are considered visual evidence.
- No physical-device installation, interrupted server response on real hardware, manual lock/background timeout, full navigation matrix, Windows/macOS build, commit, push or release was performed. Those are not implied by the simulator results. Temporary build/result/attachment files and this simulator are removed at the final resource gate; unrelated user files and the running desktop server remain untouched.

### Background follow-up verification

- Xcode 26.6 / iOS 26.5 Simulator: the complete 27-case Release selection passed with zero failures/skips. This included the production coordinator and receipt store reconstructing a lost, unsaved record after delayed positive registration, while deferring to a live producer and preserving the cached app for refresh. Lifecycle coalescing, stale callbacks and all six bounded attempts passed.
- Final static review found the existing management-state reader did not take the progress writer's lock. After adding that lock and a bounded concurrency regression, the final three-case recovery/lifecycle/synchronization run passed with zero failures/skips and rebuilt the changed iOS app/test host. The Release selection now has 28 distinct cases, covered by these two runs; it was not run as one 28-case invocation. Thread Sanitizer was not enabled.
- Repository/version contracts, Swift parse and diff checks passed; the final lock/source contract also passed. Existing dependency warnings about Roxas target edges, deprecated linker/API usage remain, with no build errors. No physical-device or server/account installation was performed, and recovered-app refresh remains a required device acceptance step. Version remains 2.4.5; no commit, push or release.
- Owned resources: a unique temporary directory held 977 MiB of DerivedData, test logs and result bundles; a dedicated iPhone 17 Pro simulator was used. Both are removed after reading results, along with their unused temporary package locks. The user's desktop server and unrelated files are preserved.

## Release convergence

User-authorized v2.4.6 tag commit `879d50774078d7ec85d6df14a1a181710ed5b050`, build 24, workflow `33949821997`. All 28 hosted tests and three platform packaging jobs passed. Nine local files matched Draft asset size/digest metadata and all eight manifest entries passed checksums; binaries came from the same run's artifacts after slow Release downloads were stopped, with metadata/checksums downloaded from Draft. Local Apple package identity/version/architecture/signature and Windows version checks passed. Published as latest at 2026-09-05 14:55:36 Asia/Shanghai. See docs/releases/v2.4.6.md for hashes, upgrade guidance and known limitations. Implementation/release work is complete; real-device response loss and refresh acceptance remain explicitly open in ISSUE-20260905-003 and TEST-043/044.

The theme implementation was delegated only to the fixed luna_worker role (gpt-5.6-luna/max), with explicit UI file ownership and no tests/builds allowed before batch convergence. The primary agent reviewed its actual diffs, made the installation/data decisions, added tests and documentation, and ran the unified validation. This background-specific continuation was implemented directly by the primary agent without further delegation.
