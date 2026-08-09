# AltForge Brand Assets

This directory contains the repository-owned visual identity used by project documentation.

## Assets

| File | Purpose | Format |
|---|---|---|
| `altforge-app-icon.png` | Primary square app icon and compact project mark | 1024 x 1024 PNG |
| `altforge-app-icon.svg` | Editable flat app-icon master | 1024 x 1024 SVG |
| `altforge-wordmark.png` | Horizontal AltForge logo for wide layouts | 1600 x 533 PNG |

## Direction

- The app icon uses a flat geometric `A` with a central diamond-shaped negative space.
- Graphite, warm white, coral, and mint are the primary identity colors.
- The app icon must remain readable at small sizes and must not gain metallic, glass, bevel, shadow, or other three-dimensional effects.
- The horizontal wordmark may be used in documentation and release artwork when the full project name is needed.
- Keep clear space around either mark. Do not stretch, rotate, recolor, or place extra text inside the app icon.

## Generation Record

The initial concepts were generated with OpenAI image generation on 2026-08-09. The final app-icon prompt used the established AltForge `A` artwork as the required geometry and removed its metallic texture, extrusion, highlights, and shadows without redesigning the mark. The selected direction was redrawn as a solid-color SVG master with light graphite underside facets, then exported to PNG. The wordmark prompt specified the exact `AltForge` name and a wide developer-tool lockup.

These files are project assets, not replacements for upstream AltStore artwork. Changes to production app-icon catalogs should preserve the same flat direction and be verified in Xcode at all exported icon sizes.
