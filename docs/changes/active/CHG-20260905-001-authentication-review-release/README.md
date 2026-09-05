# CHG-20260905-001: Authentication review and v2.4.4

- Status: Implementation complete; release gates pending
- Mapping: FR-041 / FR-042 -> DES-027 / DES-028 -> TEST-040 / TEST-041 -> T-040 / T-041
- Related issue: ISSUE-20260904-001 remains open until real-account verification.

## Review findings and corrections

1. P1: The previous GSA HTTP guard discarded structured Apple errors on non-2xx responses. Parse the service status first, preserve known credential/anisette codes, then reject unsuccessful HTTP responses.
2. P1: Both two-factor request paths ignored HTTP failures, SMS verification classified 503 as a wrong code, and trusted-device validation treated missing ec as success. Require successful HTTP requests and explicit trusted-device result codes. Match the SMS success header case-insensitively.
3. P1: Retaining Foundation parser userInfo could retain response fragments; raw MIME values were not bounded. Keep only underlying domain/code and fixed operation/MIME categories.
4. P2: Local crypto failures were described as unreadable server responses, and 5xx guidance claimed credentials were correct without proof. Use neutral secure-sign-in guidance and report only the observed HTTP result.
5. P2: Copied iOS reports lost new metadata; the macOS inline error had a three-line limit. Include the sanitized summary in both surfaces and allow selectable, wrapping desktop error text.
6. P1 verification gap: Existing tests constructed errors without exercising the parser. Add production-parser fixtures covering valid XML/binary plist, HTML, missing ec, HTTP 401/429/503, known Apple codes, MIME/underlying-error redaction and lowercase SMS headers.

## Release scope and limits

All three products use 2.4.4. This release improves authentication failure handling and diagnostics; it does not establish that a real Apple account can log in. The user's request supplied no per-request HTTP status, and the 503 report in SideStore #1446 is a separate user's report whose broader interpretation was disputed by a maintainer. Do not call that report proof of the user's root cause or a universal outage. No SRP algorithm, endpoint, retry count or stored credentials change.

The new diagnostic fields are optional NSError userInfo values, carried by existing serialization. Older clients continue to receive 3020 with generic guidance. No database migration is required. Processing remains O(response bytes); metadata and classification are bounded, with no additional requests.

## Validation

Run repository/version/metadata contracts and Swift syntax checks locally, then tag-driven hosted tests, iOS and Universal macOS release builds, Windows build, package checks and downloaded draft checksums. Publish only after the hosted gates and draft checks pass. Real-account, device installation and desktop UI interaction remain manual gaps.

## Upgrade and rollback

Upgrade both the iOS app and desktop server to see the new diagnostics in both flows. Do not delete the iOS app before upgrading. Roll back using the v2.4.3 release packages; no database or credential migration is introduced.
