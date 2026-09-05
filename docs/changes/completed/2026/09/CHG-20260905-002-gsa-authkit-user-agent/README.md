# CHG-20260905-002: GSA AuthKit identity and isolated retries

- Status: Implemented and user-accepted; v2.4.5 release preparation
- Mapping: FR-041 -> DES-027 -> TEST-040 -> T-040
- Related issue: ISSUE-20260904-001

## New evidence

After the local transport tests/builds below, the user confirmed successful sign-in on 2026-09-05 and supplied a screenshot showing the installation flow preparing/registering the device. This confirms the reported macOS login blocker is cleared in the local candidate. It does not establish final device installation, independent iOS login, Windows login or all 2FA paths. The user authorized a new public release; versions are synchronized to 2.4.5 without overwriting v2.4.4. Remaining device/platform coverage stays in ISSUE-20260904-001.

The user's v2.4.4 screenshot reports apptokens / HTTP 503 / text/html. The local call chain only reaches apptokens after processing init and complete, validating the SRP server proof and decrypting the session payload. This narrows the failure to developer-token issuance, not IPA parsing.

AltSign PR #47 changes the GSA client family from akd to AuthKit. PR #49 reports request comparisons and successful login/install with AuthKit plus fresh sessions and bounded retries, but remains unmerged; its explanation of backend connection affinity is an author hypothesis. xtool PR #244 is merged and release 1.19.0 explicitly fixes its apptokens/503 issue #243.

- https://github.com/rileytestut/AltSign/pull/47
- https://github.com/rileytestut/AltSign/pull/49
- https://github.com/xtool-org/xtool/pull/244
- https://github.com/xtool-org/xtool/releases/tag/1.19.0

Reviewed AltSign marketplace PR heads: #47 `0e756bbebc32d3ceef1b6f48775e9e2aecb14b37`, #49 `a91fb9e6e7f2c83d131bef41d51b96545edf55b7`; both remain open on 2026-09-05. This is a scoped manual adaptation, not a claim that upstream merged them or an unconditional cherry-pick of their diagnostics.

Earlier AltForge changes updated CFNetwork/Darwin but kept the akd/1.0 family. That is materially different from the tested AuthKit user agent. Earlier claims that only the Xcode bundle identity mattered, or that all such failures must simply wait for an Apple outage to end, were incomplete.

## Implementation

Use the exact GSA compatibility user agent from AltSign PR #47:

```text
AuthKit/1 (Macintosh; OS X 26.5.2) (com.apple.dt.Xcode/26.0)
```

This is a pinned protocol compatibility string, not the host OS or AltForge version. Retain the existing independently generated anisette device identity, SRP, endpoints, two-factor handling and redacted diagnostics.

Adapt PR #49's isolated ephemeral session and backoff implementation to the existing parser. Only POST exchanges to Apple's GsService2 for init, complete and apptokens may retry. Each exchange has at most five total attempts, with 1/2/4/8-second backoff. Each attempt has a maximum 15-second request/resource timeout, reduced to the remaining monotonic 60-second exchange budget. A delayed scheduler checks the budget again before opening a session. The entire login may involve three such exchanges, excluding user-driven 2FA.

Parse first and preserve structured Apple error codes. Retry only an HTTP 5xx mapped to authenticationHandshakeFailed, not wrong passwords, invalid anisette, other explicit Apple errors, HTTP 401/429, HTML with HTTP 200, transport errors, cancellation or timeouts. Do not replay the whole SRP flow, 2FA, certificate or installation operations. A 5xx does not prove Apple left a request unprocessed; the limited repeated exchange follows the upstream compatibility workaround, not a general POST retry policy. The backend-affinity explanation remains unverified locally.

Each attempt disables credential/cookie/cache storage and finishes/invalidate its session. Retain only safe operation/status/MIME metadata, never PR #49's response-body snippets or raw parser userInfo. No public protocol, cryptography, dependency, persistent-data or Windows changes. Network cost is bounded to five requests per GSA exchange, one active request at a time; retry state is O(1), response parsing remains O(response bytes). Credentials remain in memory only for the bounded request lifetime as before.

## Verification and rollback

Run repository contracts, Swift syntax, hosted iOS XCTest locally, and a bounded macOS AltServer build. URLProtocol fixtures exercise the actual production transport and parser: 503/502 then success for each operation, five-attempt exhaustion, identical request bodies, distinct sessions and invalidation, structured errors, 401/429/HTML, transport failures, operation/host scope and deadlines. Inject only scheduling/monotonic time to avoid real backoff; do not contact Apple or use real credentials. Add all four transport regressions to the Release workflow. These checks cannot establish successful Apple login. A user-driven real-account test must confirm token issuance and installation before marking the underlying issue resolved.

### Local results, 2026-09-05

- Repository contract, Swift syntax and root/submodule diff checks passed.
- Xcode 26.6 (17F113), iOS 26.5 (23F77) iPhone 17 Pro Simulator: all 17 Release-selected hosted XCTest cases passed locally, zero failures/skips. Four new transport tests cover 19 scenarios, including session invalidation. The iOS app and test host built successfully.
- `xcodebuild test` used four jobs, disabled parallel testing, a dedicated simulator and a 900-second process bound. Test selection was read from `.github/workflows/release.yml`, not a separately maintained list. Result bundle reported 17 passed tests.
- `xcodebuild build -scheme AltServer -configuration Debug -destination generic/platform=macOS CODE_SIGNING_ALLOWED=NO` used the workspace, four jobs, isolated DerivedData and a 600-second process bound; exit 0. The app contains both x86_64 and arm64. Existing dependency/deprecation warnings remain, with no errors or new authentication-source warnings.
- The 31 MiB test app at `build/authkit-retry-test/AltForge Server.app` contains the exact AuthKit user agent in both AltSign slices. Independent ad-hoc signing and `codesign --verify --deep --strict` passed. This is not Developer ID signing/notarization. The app was not launched, installed or substituted for the running release.
- Validated source SHA-256: authentication Swift `9e463737bc7d4d7e48f87e163dd49ff7e64f5f8b46c40978cf50b5f5e6510b64`; AltTests Swift `a513ab98f11b90c72d306afe45600037b9f9c1d83dada0428706a78343b51185`.
- The dedicated simulator was already shut down by the test runner and has been deleted. Both build/test processes exited. The 2.5 GiB temporary DerivedData/result bundle/log directory was removed after extracting the compact results above. Only the new test app is retained for user-driven login; the pre-existing installed server was left running and untouched.
- During the automated local batch, no real Apple credentials were accessed and no real login/2FA/device installation was exercised. Windows is a separate unchanged C++ implementation and was not built/tested in that batch. The user subsequently performed the successful login noted above. Release-phase CI and artifact results are tracked in `docs/releases/v2.4.5.md`.

The earlier UA-only candidate under `build/authkit-user-agent-test` predates this expanded batch and was left untouched; use the retry-test app for the next real-account check. To avoid running two servers, cancel any existing sign-in dialog and quit the installed server before launching the test app. Enter credentials only in the local app. Confirm token issuance, team/certificate lookup and one installation before resolving ISSUE-20260904-001.

Roll back the AltSign authentication patch and corresponding tests/contracts together, or use the unchanged published v2.4.4 bundle (which still has the reported authentication failure). No migration is required. This local patch is not included in the already published v2.4.4 package; no release tag is overwritten.
