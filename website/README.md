# AltForge Website

The public download and installation page is a dependency-free static site deployed from this directory. Its design source of truth is [`design-system/altforge-website/MASTER.md`](../design-system/altforge-website/MASTER.md).

## Local preview

```sh
ruby -run -e httpd website -p 4173
```

Open `http://127.0.0.1:4173`. The page reads the current version from the latest GitHub Release API; all downloads use stable `releases/latest/download/<artifact>` URLs from `legeling/AltForge`.

## Cloudflare Pages

- Project name: `altforge`
- Production branch: `marketplace`
- Build command: none
- Build output directory: `website`
- Root directory: repository root

The existing `altforge` project uses Cloudflare Pages Direct Upload. Cloudflare does not allow an existing Direct Upload project to be converted to native Git integration, so repository-linked deployment is implemented by `.github/workflows/website.yml` and Wrangler instead. The workflow always verifies pull requests and `marketplace` pushes. Production deployment is fail-closed until the repository has these settings:

- Secret `CLOUDFLARE_ACCOUNT_ID`: the Cloudflare account that owns `altforge`.
- Secret `CLOUDFLARE_API_TOKEN`: a scoped token with Account / Cloudflare Pages / Edit.
- Variable `CLOUDFLARE_PAGES_DEPLOY_ENABLED`: exactly `true` after both secrets are configured.

No Cloudflare credential belongs in this directory, workflow source, logs, or documentation.

For a deliberate direct deployment after local verification:

```sh
npx wrangler pages deploy website --project-name altforge --branch marketplace
```

The website must not contain release binaries, credentials, analytics, or a second version source. IPA, DMG, ZIP, metadata, and checksums remain GitHub Release assets.

## Visual assets

- `assets/altforge-icon.png` is generated from the canonical repository brand source by `Scripts/generate_brand_assets.rb`.
- `assets/altforge-hero.jpg` is a project-owned generated product photograph based on the canonical AltForge icon. It contains one precision-machined AltForge mark on a graphite workbench, with no text, people, or third-party branding.

The hero asset was generated with the built-in image generation tool for the 2026-08-14 website redesign. Its production prompt requested a wide industrial product photograph, left-side copy space, one preserved AltForge mark, graphite/white/red/teal materials, and explicitly excluded repeated icons, text, people, devices, watermarks, gradients, purple, bokeh, and cyberpunk styling.
