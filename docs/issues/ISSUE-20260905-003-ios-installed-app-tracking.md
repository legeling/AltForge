# ISSUE-20260905-003: Device app missing from My Apps

- Priority: P0
- Status: Fixes published in v2.4.6 (24); all 28 hosted regressions passed, device acceptance pending
- Change: CHG-20260905-003; FR-044/FR-045; TEST-043/TEST-044

The user confirmed an app can open on the phone but is absent from AltForge's management list after an installation with no visible progress and screen locking. Code inspection found unsaved installation results, cancellation without finishing the wait, and destructive cleanup based on absent UTI registration. No user device database or credentials were read.

The candidate adds receipts, immediate confirmed-result saves, positive-only recovery and conservative cache retention; explicit removal remains available. The production transport identity fix from v2.4.5 is unchanged. An App ID does not establish installation or provide a refresh payload.

Follow-up clarification pins the report to background installation. Review found a gap in the initial local candidate: one-shot foreground reconciliation could miss delayed UTI registration, and recovery did not defer to live producers. The continuation adds bounded, lifecycle-aware local rechecks and removes legacy instructions to uninstall before retrying. AltStore marketplace and SideStore self-update evidence are recorded in CHG-20260905-003; neither is presented as an upstream fix already covering all ordinary-app background installations.

Acceptance requires a real-device install that remains listed after foreground/background transitions, a deliberately interrupted final response followed by recovery, a successful refresh from the recovered record, and manual removal that does not reappear. Verify both theme changes and large-text installation UI on-device. Automatic screen-awake leases do not override the power button or OS background limits.

If an older app has already lost both its record and recovery metadata, keep the device app/data and import the same IPA with the same Apple ID/team. Do not promise reconstruction from App IDs, and do not ask the user to uninstall first.
