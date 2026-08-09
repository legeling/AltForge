<p align="center">
  <img src="altforge-wordmark.png" width="520" alt="AltForge">
</p>

# AltForge Brand Assets

This directory contains the repository-owned visual identity used by project documentation.

## Assets

| File | Purpose | Format |
|---|---|---|
| `altforge-app-icon.png` | Authoritative square app icon and compact project mark | 1024 x 1024 PNG |
| `altforge-app-icon-coral.png` | Coral-background alternate app icon | 1024 x 1024 PNG |
| `altforge-wordmark.png` | Complete horizontal AltForge wordmark | 1600 x 533 PNG |
| `altforge-template-icon.png` | Transparent monochrome source for template-rendered UI icons | 1024 x 1024 PNG |

## Direction

- The app icon uses a flat geometric `A` with a central diamond-shaped negative space.
- Graphite, warm white, coral, and mint are the primary identity colors.
- The app icon must remain readable at small sizes and must not gain metallic, glass, bevel, shadow, or other three-dimensional effects.
- The horizontal wordmark may be used in documentation and release artwork when the full project name is needed.
- Keep clear space around either mark. Do not stretch, rotate, recolor, or place extra text inside the app icon.

## Platform Assets

Run `ruby Scripts/generate_brand_assets.rb` from the repository root after changing an icon source. The script deterministically generates the iOS default and alternate Icon Composer layers and previews, every macOS AppIcon size, the macOS menu-bar template images, the Widget template image, and both Windows ICO resources.

The selectable iOS icon family is limited to the approved AltForge and AltForge Coral treatments. Inherited AltStore theme catalogs and previews are intentionally removed so no upstream artwork ships as an AltForge brand option.

## Generation Record

The app-icon artwork was generated with OpenAI image generation on 2026-08-09 using the established AltForge `A` as the required geometry. The selected PNG preserves the white front planes, coral and mint folds, central black negative space, and balanced graphite underside facets. The Coral treatment was generated from that approved image with geometry locked and only the background/accent direction changed. The wordmark prompt specified the exact `AltForge` name and a wide developer-tool lockup. A separate generated monochrome glyph is chroma-keyed to transparency for system template rendering.

These files are project assets, not replacements for upstream AltStore artwork. Changes to production app-icon catalogs should preserve the same flat direction and be verified in Xcode at all exported icon sizes.
