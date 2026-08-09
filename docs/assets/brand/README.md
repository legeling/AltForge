# AltForge Brand Assets

This directory contains the repository-owned visual identity used by project documentation.

## Assets

| File | Purpose | Format |
|---|---|---|
| `altforge-app-icon.png` | Authoritative square app icon and compact project mark | 1024 x 1024 PNG |
| `altforge-wordmark.png` | Complete horizontal AltForge wordmark | 1600 x 533 PNG |
| `altforge-template-icon.png` | Transparent monochrome source for template-rendered UI icons | 1024 x 1024 PNG |

## Direction

- The app icon uses a flat geometric `A` with a central diamond-shaped negative space.
- Graphite, warm white, coral, and mint are the primary identity colors.
- The app icon must remain readable at small sizes and must not gain metallic, glass, bevel, shadow, or other three-dimensional effects.
- The horizontal wordmark may be used in documentation and release artwork when the full project name is needed.
- Keep clear space around either mark. Do not stretch, rotate, recolor, or place extra text inside the app icon.

## Platform Assets

Run `ruby Scripts/generate_brand_assets.rb` from the repository root after changing either icon source. The script deterministically generates the iOS default icon layer and preview, every macOS AppIcon size, the macOS menu-bar template images, the Widget template image, and both Windows ICO resources.

Historical alternate iOS icon themes remain optional user-selectable artwork. They are not the default AltForge identity.

## Generation Record

The app-icon artwork was generated with OpenAI image generation on 2026-08-09 using the established AltForge `A` as the required geometry. The selected PNG preserves the white front planes, coral and mint folds, central black negative space, and balanced graphite underside facets. The wordmark prompt specified the exact `AltForge` name and a wide developer-tool lockup. A separate generated monochrome glyph is chroma-keyed to transparency for system template rendering.

These files are project assets, not replacements for upstream AltStore artwork. Changes to production app-icon catalogs should preserve the same flat direction and be verified in Xcode at all exported icon sizes.
