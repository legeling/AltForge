#!/usr/bin/env ruby

require "set"

root = File.expand_path("..", __dir__)
website = File.join(root, "website")

def assert(condition, message)
  abort("Website contract failed: #{message}") unless condition
end

required_files = %w[index.html styles.css app.js _headers robots.txt README.md assets/altforge-icon.png assets/altforge-hero.jpg]
required_files.each do |relative_path|
  path = File.join(website, relative_path)
  assert(File.file?(path) && File.size(path).positive?, "missing or empty #{relative_path}")
end

html = File.read(File.join(website, "index.html"))
css = File.read(File.join(website, "styles.css"))
javascript = File.read(File.join(website, "app.js"))
headers = File.read(File.join(website, "_headers"))
product_version = File.read(File.join(root, "VERSION")).strip

assert(html.start_with?("<!doctype html>"), "HTML must declare the HTML5 doctype")
assert(html.scan(/<html(?:\s|>)/).length == 1 && html.scan(%r{</html>}).length == 1, "HTML document boundaries are invalid")
assert(html.include?('lang="zh-Hans"'), "HTML must declare the Simplified Chinese fallback language")
assert(html.include?('name="viewport"'), "HTML must include a mobile viewport")
assert(html.include?('name="color-scheme"'), "HTML must advertise light and dark color schemes")
assert(html.include?('class="skip-link"'), "HTML must include a keyboard skip link")
assert(html.scan(/<h1(?:\s|>)/).length == 1, "HTML must contain one h1")
assert(!html.match?(/<img(?![^>]*\balt=)/), "every image must declare alt text")
svg_tags = html.scan(/<svg\b[^>]*>/)
assert(svg_tags.all? { |tag| tag.include?('width="') && tag.include?('height="') }, "every inline SVG must keep bounded fallback dimensions")
assert(html.scan('assets/altforge-hero.jpg').length >= 2, "hero artwork must be preloaded and rendered")
assert(!html.include?("altforge-icon-glass.png") && !html.include?("altforge-icon-titanium.png"), "hero must not repeat oversized app icon variants")
hero_path = File.join(website, "assets/altforge-hero.jpg")
assert(File.size(hero_path).between?(100_000, 2_500_000), "hero artwork must stay bounded for web delivery")

i18n_keys = html.scan(/data-i18n="([^"]+)"/).flatten.to_set
catalogs = javascript.scan(/^\s{4}([A-Za-z][A-Za-z0-9]+):\s/m).flatten.to_set
missing_translations = i18n_keys - catalogs
assert(missing_translations.empty?, "missing translations for #{missing_translations.to_a.sort.join(', ')}")
assert(javascript.include?('"zh-Hans"') && javascript.include?("en:"), "website must support English and Simplified Chinese")
assert(javascript.include?('localStorage.getItem("altforge-language")'), "language choice must persist")

repository_prefix = "https://github.com/legeling/AltForge"
urls = html.scan(/(?:href|src)="([^"]+)"/).flatten + javascript.scan(%r{https://[^"'`$\s]+})
external_urls = urls.select { |value| value.start_with?("http://", "https://") }
invalid_urls = external_urls.reject do |value|
  value.start_with?(repository_prefix) ||
    value.start_with?("https://api.github.com/repos/legeling/AltForge/") ||
    value.start_with?("https://github.com/altstoreio/AltStore")
end
assert(invalid_urls.empty?, "unexpected external URL: #{invalid_urls.join(', ')}")
assert(![html, css, javascript].join.include?(product_version), "website must not duplicate the current release version")

%w[AltForge-AltServer-macOS.dmg AltForge-AltServer-Windows.zip AltForge.ipa].each do |asset|
  assert([html, javascript].join.include?("releases/latest/download/#{asset}"), "missing latest Release URL for #{asset}")
end
assert(javascript.include?("https://api.github.com/repos/legeling/AltForge/releases/latest"), "version display must use the latest GitHub Release API")

assert(css.include?("@media (prefers-color-scheme: dark)"), "website must include a dark color scheme")
assert(css.include?("@media (prefers-reduced-motion: reduce)"), "website must respect reduced motion")
assert(css.include?("animation-duration: 0.01ms !important"), "reduced motion must disable website animations")
assert(css.include?("@keyframes hero-settle") && css.include?("@keyframes hero-content-arrive"), "website must keep the bounded hero motion system")
assert(javascript.include?("IntersectionObserver") && javascript.include?("observer.unobserve"), "website must progressively enhance and release scroll observers")
assert(css.include?(":focus-visible"), "website must expose keyboard focus")
assert(css.include?("min-width: 320px"), "website must define a small-screen floor")
assert(css.include?("min-height: 44px"), "website controls must keep a 44px target")

assert(headers.include?("Content-Security-Policy"), "website must publish a CSP")
assert(headers.include?("frame-ancestors 'none'"), "CSP must block framing")
assert(headers.include?("Permissions-Policy"), "website must restrict browser capabilities")

brand_generator = File.read(File.join(root, "Scripts/generate_brand_assets.rb"))
%w[assets/altforge-icon.png].each do |relative_path|
  assert(brand_generator.include?("website/#{relative_path}"), "brand generator must own #{relative_path}")
end

design_system = File.read(File.join(root, "design-system/altforge-website/MASTER.md"))
assert(design_system.include?("website/assets/altforge-hero.jpg"), "design system must document the generated hero asset")

workflow_path = File.join(root, ".github/workflows/website.yml")
assert(File.file?(workflow_path), "repository-linked website workflow is missing")
workflow = File.read(workflow_path)
assert(workflow.include?("branches:\n      - marketplace"), "website workflow must target marketplace")
assert(workflow.include?("submodules: recursive"), "website verification must check out repository contract dependencies")
assert(workflow.include?("pages deploy website --project-name=altforge --branch=marketplace"), "website workflow must deploy the repository website directory")
assert(workflow.include?("CLOUDFLARE_PAGES_DEPLOY_ENABLED") && workflow.include?("CLOUDFLARE_API_TOKEN"), "website deployment must stay fail-closed behind repository configuration")

puts "Website contract passed for bilingual content, Release URLs, accessibility, security headers, and generated brand assets."
