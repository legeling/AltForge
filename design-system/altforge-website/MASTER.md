# AltForge Website Design System

**Updated:** 2026-08-14
**Direction:** Industrial editorial product release
**Design dials:** Variance 6/10, motion 4/10, density 5/10

## Product Intent

AltForge is an open-source sideloading tool, not a lifestyle brand or a generic SaaS product. The website must make three things obvious in the first viewport: the AltForge identity, the current GitHub Release, and the correct desktop download.

## Visual Principles

- Use one strong AltForge mark in the hero. Never stack or repeat oversized app icons.
- Use a full-bleed industrial product photograph behind hero copy, not a split hero or a framed preview.
- Keep repository provenance visible: source, releases, checksums, license, documentation, and issues all resolve to `legeling/AltForge`.
- Prefer full-width information bands and ruled lists. Cards are reserved for repeated download choices or FAQ disclosures.
- Use depth only where it carries hierarchy. Avoid decorative glass panels, floating blobs, gradients, and ornamental animation.

## Tokens

| Role | Light | Dark |
|---|---|---|
| Canvas | `#F4F6F7` | `#0A0B0C` |
| Surface | `#FFFFFF` | `#111315` |
| Strong text | `#101214` | `#F7F8F8` |
| Muted text | `#5E666D` | `#A9B0B5` |
| Rule | `#D9DEE2` | `#2B3034` |
| Forged red | `#D7353D` | `#FF5A61` |
| Signal teal | `#168C88` | `#55C7C0` |
| Link blue | `#2467D1` | `#75A7FF` |

Typography uses the local system stack: `-apple-system`, `BlinkMacSystemFont`, `Segoe UI`, `PingFang SC`, `Helvetica Neue`, and `Arial`. This avoids an external font request and keeps Simplified Chinese and Latin text balanced. Letter spacing is always `0`.

## Layout

- Content width: `1200px` maximum with `24px` desktop and `18px` mobile gutters.
- Hero: `calc(100svh - 72px)` with a `540px` floor and `820px` ceiling so the next band remains visible.
- Sections: `72-104px` vertical space on desktop and `56-72px` on mobile.
- Fixed-format controls use explicit dimensions. Interactive targets are at least `44px` high.
- Border radius is `8px` or less.

## Components

- Primary command: white on forged red in light sections, black on white in the dark hero.
- Secondary command: transparent with a visible rule and a directional or repository icon.
- Platform downloads: two ruled rows with platform mark, supported OS, artifact description, signature disclosure, and a single download command.
- Repository band: unframed source/release/license/integrity facts immediately below the hero.
- FAQ: native `details` rows with a stable disclosure indicator and keyboard focus.

## Motion And Accessibility

- Use 160-220ms control feedback, a single 520-1400ms hero arrival sequence, and small scroll-entry translations for supporting content.
- Keep essential content partially visible before enhancement; do not animate layout dimensions or make reading depend on JavaScript.
- Use IntersectionObserver once per bounded page element, unobserve after entry, and avoid scroll loops or pointer-tracking work.
- Respect `prefers-reduced-motion` and expose visible `:focus-visible` outlines.
- Maintain 4.5:1 text contrast, alt text, semantic headings, and 320px no-overflow support.

## Hero Asset

`website/assets/altforge-hero.jpg` is a project-owned generated raster based on the canonical AltForge app icon. It depicts a single precision-machined AltForge mark on a graphite workbench with red and teal material accents. It contains no text, people, third-party marks, or duplicated product icons.

## Avoid

- Repeated giant icon mockups or version badges floating over the icon.
- Beige or purple-dominated palettes.
- Nested cards, decorative dashboard tiles, stock-device mockups, fake ratings, or fabricated testimonials.
- External analytics, font CDNs, third-party download hosts, or a hard-coded release version.

## Pre-Delivery Checklist

- [ ] One H1 with the product name and one dominant hero mark.
- [ ] Platform-specific primary download and direct DMG/ZIP/IPA links.
- [ ] GitHub repository, Release, documentation, issue, license, and checksum paths are visible and valid.
- [ ] English and Simplified Chinese both fit at 320/375/768/1024/1440px.
- [ ] Light/dark, keyboard, reduced-motion, no-JS fallback, security headers, and live production readback pass.
