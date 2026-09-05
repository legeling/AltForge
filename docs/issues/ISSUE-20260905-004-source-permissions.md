# ISSUE-20260905-004: Official update fails with verification error 201

- Priority: P1
- Status: Fix published in v2.4.7; public latest source and IPA verified, old-client device update acceptance pending
- Mapping: FR-046 / DES-031 / TEST-045 / T-044 / CHG-20260905-004

Apple ID authentication completes, then the source update is rejected for undeclared permissions. v2.4.6 declares local-network usage in its app Info.plist but the official source privacy map is empty. Package checksums and version checks do not establish source permission compatibility. Desktop updating or re-downloading the same IPA does not repair this mismatch.

Fix ownership is release source generation and its gates. Keep client permission enforcement intact. Verify that the original source fails against the released IPA and corrected policy/generated source pass; preserve actionable domain/code-specific copy and permission details. Actual old-client source refresh and in-app update remain to be verified after a separately authorized publication. Never require uninstalling the existing app.

v2.4.7 publication was authorized and completed. Public latest apps.json now declares NSLocalNetworkUsageDescription and passed the built-IPA privacy check. All 29 hosted XCTest, seven Python fixtures and three platform builds passed. A real old-client source refresh and update has not yet been confirmed; the v2.4.6 tag-pinned source remains unchanged.
