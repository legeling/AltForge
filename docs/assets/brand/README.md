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
| `altforge-app-icon-frost.png` | Cool cyan alternate app icon | 1024 x 1024 PNG |
| `altforge-app-icon-paper.png` | High-contrast light alternate app icon | 1024 x 1024 PNG |
| `altforge-app-icon-neon.png` | Dark cyan-and-coral alternate app icon | 1024 x 1024 PNG |
| `altforge-app-icon-blueprint.png` | Technical grid alternate app icon | 1024 x 1024 PNG |
| `altforge-app-icon-titanium.png` | Forged titanium dimensional alternate app icon | 1024 x 1024 PNG |
| `altforge-app-icon-glass.png` | Optical glass dimensional alternate app icon | 1024 x 1024 PNG |
| `altforge-app-icon-ceramic.png` | Ceramic enamel dimensional alternate app icon | 1024 x 1024 PNG |
| `altforge-wordmark.png` | Complete horizontal AltForge wordmark | 1600 x 533 PNG |
| `altforge-template-icon.png` | Transparent monochrome source for template-rendered UI icons | 1024 x 1024 PNG |

## Direction

- The app icon uses a flat geometric `A` with a central diamond-shaped negative space.
- Graphite, warm white, coral, and mint are the primary identity colors.
- The default app icon remains flat and authoritative. Alternate icons may use restrained material depth when the `A` silhouette and central negative space remain readable at small sizes.
- The horizontal wordmark may be used in documentation and release artwork when the full project name is needed.
- Keep clear space around either mark. Do not stretch, rotate, recolor, or place extra text inside the app icon.

## Platform Assets

Run `ruby Scripts/generate_brand_assets.rb` from the repository root after changing an icon source. The script deterministically generates the iOS default and alternate Icon Composer layers and previews, every macOS AppIcon size, the macOS menu-bar template images, the Widget template image, and both Windows ICO resources. `swift Scripts/generate_altforge_app_icons.swift` regenerates only the four derived iOS alternate styles when a shorter icon-only workflow is needed.

The selectable iOS icon family contains nine repository-owned treatments: AltForge, Coral, Frost, Paper, Neon, Blueprint, Titanium, Glass, and Ceramic. The default and five color treatments remain flat; the three material treatments provide an explicitly optional dimensional direction. Every treatment preserves the approved `A` silhouette. Inherited AltStore theme catalogs and previews are intentionally removed so no upstream artwork ships as an AltForge brand option.

## Generation Record

The app-icon artwork was generated with OpenAI image generation on 2026-08-09 using the established AltForge `A` as the required geometry. The selected PNG preserves the white front planes, coral and mint folds, central black negative space, and balanced graphite underside facets. The Coral treatment was generated from that approved image with geometry locked and only the background/accent direction changed. Titanium, Glass, and Ceramic were generated on 2026-08-13 as project-owned material studies and retained as authoritative 1024px RGB sources. The wordmark prompt specified the exact `AltForge` name and a wide developer-tool lockup. A separate generated monochrome glyph is chroma-keyed to transparency for system template rendering.

These files are project assets, not replacements for upstream AltStore artwork. Changes to the default icon must preserve the flat direction; dimensional alternates must stay optional and be verified in Xcode at all exported icon sizes.
