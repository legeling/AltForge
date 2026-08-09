# CHG-20260809-005 AltForge Brand Assets

## Background

AltForge still exposed inherited AltStore artwork in the default iOS icon, AltServer applications, menu/tray surfaces, Widget template, and documentation. The repository also lacked a reproducible path from the approved AltForge mark to platform-specific icon formats.

## Scope

- Establish the approved `altforge-app-icon.png` as the authoritative compact mark.
- Add a complete horizontal `AltForge` wordmark and a monochrome template glyph.
- Replace default iOS, macOS, Windows, Widget, and README brand surfaces.
- Keep historical alternate iOS themes available as optional user-selected artwork.
- Add a bounded generator for fixed PNG sizes and multi-resolution Windows ICO containers.

## Traceability

| Type | ID | Requirement |
|---|---|---|
| Requirement | `FR-BRAND-001` | Default product surfaces use the approved AltForge mark rather than inherited AltStore artwork. |
| Requirement | `FR-BRAND-002` | Documentation provides the complete AltForge wordmark in English and Chinese README variants. |
| Design | `DES-BRAND-001` | One color master and one transparent template master generate fixed platform outputs. |
| Test | `TEST-BRAND-001` | Validate dimensions, alpha behavior, manifests, ICO entries, Markdown rendering, and affected Apple targets. |

## Complexity And Resources

Generation processes a fixed list of image sizes. Time and disk use are `O(total output pixels)` with no unbounded input, concurrency, cache, retry, or network work. Temporary ICO directories and intermediate files are scoped to one process and removed on exit.

## Implementation

- `docs/assets/brand/` owns the app icon, wordmark, template glyph, and usage record.
- `Scripts/generate_brand_assets.rb` uses macOS `sips` and Ruby standard-library code to resize PNGs and pack PNG-backed ICO entries.
- iOS Icon Composer uses the approved raster mark as a single opaque layer without inherited glass effects.
- macOS and Windows receive fixed-size platform resources; menu and Widget assets use the monochrome template where the system supplies foreground color.
- Release metadata now publishes the generated AltForge preview icon rather than the removed inherited filename.

## Verification

- `ruby Scripts/generate_brand_assets.rb` completed and regenerated every platform asset.
- Ruby syntax and JSON parsing checks passed for the generator and affected asset manifests; `AltIcons.plist` passed `plutil -lint`.
- PNG dimensions and alpha modes match their platform roles, and both ICO files contain the expected bounded multi-resolution PNG entries.
- `AltStore` built successfully for the generic iOS Simulator destination with signing disabled.
- `AltServer` built successfully for the generic macOS destination with signing disabled.
- Both README variants rendered through GitHub's Markdown API with the horizontal wordmark present.
- Windows MSBuild and physical-device appearance were not exercised on macOS; Windows coverage is limited to deterministic generation and ICO structure validation.

## Residual Risk And Rollback

- Historical alternate iOS icons intentionally remain available and may still contain upstream-themed artwork when explicitly selected.
- Final appearance can vary slightly with platform masking and menu-bar scaling; the generated sources remain the rollback and regeneration boundary.
- Rollback is a single commit revert because no schema, protocol, identifier, or user data changes are involved.
