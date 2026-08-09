# AltForge

**English** | [简体中文](README.zh-CN.md)

> A maintained AltStore Classic derivative focused on reliable sideloading, Unicode compatibility, localization, and practical fixes.

[![Swift Language Mode](https://img.shields.io/badge/Swift_language_mode-5.0-orange.svg)](https://swift.org/)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/legeling/AltForge/pulls)

## About

AltForge is an independent derivative of [AltStore](https://github.com/altstoreio/AltStore). It keeps the familiar AltStore/AltServer architecture while maintaining compatibility fixes and user-facing improvements that are not yet available, or are no longer maintained, in the upstream Classic line.

AltForge is currently built as an **AltStore Classic** application. The `marketplace` branch name is historical and does not mean the release embeds the Marketplace extension or entitlement.

## What AltForge Changes

| Area | AltForge change |
|---|---|
| Product identity | Uses the AltForge brand, `com.legeling.AltForge` bundle identifier family, and the repository's official GitHub Release source. |
| Unicode IPA installation | Preserves Unicode display names and resource paths, supports UTF-8 and Info-ZIP Unicode Path metadata, and provides bounded fallbacks for common legacy East Asian ZIP filename encodings. |
| Apple App ID compatibility | Converts only the Apple App ID description to a safe ASCII value without changing the app's on-device Unicode display name. |
| Simplified Chinese | Includes Simplified Chinese resources and supports iOS per-app language selection while retaining English fallback behavior. |
| Developer teams | Supports individual, organization, and free developer-team fallback in the client and AltServer installation paths. |
| Maintenance fixes | Prevents negative expiration-day displays and makes macOS error details selectable while preserving attributed formatting. |
| Build and release | Defines bounded CI builds and tag-driven release packaging for the IPA, macOS AltServer, source metadata, and checksums. |
| Project documentation | Maintains requirements, architecture, verification, issues, change records, and contributor rules under [`docs/`](docs/README.md). |

General fixes remain separated from AltForge branding where practical so they can be contributed back to upstream projects.

## Features

- Install, refresh, and update sideloaded applications through AltServer over Wi-Fi or a connected device.
- Sign applications with an individual, organization, or free Apple developer team.
- Install IPA files containing Chinese or other Unicode app names and resource filenames.
- Use the interface in English or Simplified Chinese, including iOS per-app language switching.
- Add and update compatible AltStore sources with stable source identity handling.
- Preserve structured client/server error information for more useful diagnostics.
- Use the existing optional Widget, Backup, and JIT components where their platform requirements are met.

## Requirements

### Using AltForge

- iOS or iPadOS 17.4 or later.
- macOS 11 or later for AltServer.
- macOS 13 or later for the optional AltJIT target.
- An Apple ID and a compatible Apple developer team.

### Building AltForge

- macOS with Xcode 26.
- CocoaPods.
- Git with recursive submodule support.
- The project currently uses Swift language mode 5.0 under the Xcode 26 toolchain. It has not been migrated to Swift 6 language mode.

## Downloads And Installation

Published builds are available from this repository's [GitHub Releases](https://github.com/legeling/AltForge/releases). A tagged release is expected to contain:

- `AltForge.ipa`: an unsigned AltStore Classic package that AltServer signs for the selected Apple ID, team, and device.
- `AltForge-AltServer-macOS.zip`: the macOS AltServer application.
- `apps.json`: the official AltForge source metadata.
- `SHA256SUMS.txt`: SHA-256 checksums for the release artifacts.

The IPA cannot be installed by tapping it on an iPhone or iPad. Install the macOS AltServer package, connect and trust the device, then choose **Install AltForge** from AltServer. AltServer will request the Apple account information required by Apple's signing flow.

The current macOS archive is not Developer ID signed or notarized. macOS may require opening AltServer from Finder's context menu. Verify release checksums before installation.

## Build From Source

```sh
git clone --recurse-submodules https://github.com/legeling/AltForge.git
cd AltForge
git submodule update --init --recursive
pod install --deployment
open AltStore.xcworkspace
```

In Xcode:

1. Select your development team for the AltStore, AltWidgetExtension, and AltBackup targets.
2. When running AltForge directly from Xcode, set `ALTDeviceID` in the AltStore Info.plist to the target device UDID.
3. Optionally set `ALTServerID` to the Bonjour `serverID` advertised by your AltServer. Without it, AltForge can still fall back to another available server.
4. Select the AltStore or AltServer scheme and build the required target.

Repeatable command-line build and test commands are documented in the [verification guide](docs/workflow/04-verification/README.md). Signing, provisioning, device installation, and JIT changes still require an appropriately sanitized real-device validation plan.

## Release Process

Pull requests and pushes to `marketplace` use the repository CI workflow. Semantic version tags trigger the release workflow:

```sh
VERSION=2.3.4
git tag "v${VERSION}"
git push origin "v${VERSION}"
```

The workflow builds an unsigned IPA and a universal macOS AltServer archive, generates `apps.json` and checksums, and attaches the artifacts to a GitHub Release. Tag creation and publishing should only be performed by a release maintainer after the documented quality gates have been checked.

## Project Structure

| Path | Responsibility |
|---|---|
| `AltStore/` | iOS user interface and app-management workflow. |
| `AltServer/` | macOS authentication, signing preparation, and device installation. |
| `AltStoreCore/` | Shared domain models, persistence, sources, and utilities. |
| `Shared/` | Client/server protocol and shared application behavior. |
| `Dependencies/AltSign/` | Apple Developer API, signing, application models, and IPA/ZIP handling. |
| `AltTests/` | XCTest coverage for shared and application behavior. |
| `docs/` | Requirements, design, verification, issues, changes, ADRs, releases, and rules. |

The repository keeps historical `AltStore`, `AltServer`, and `ALT*` code identifiers where renaming would create unnecessary upstream conflicts. Public product text and official source identity use AltForge.

## Documentation And Contributing

Start with the [documentation index](docs/README.md) and the project-level [agent/contributor rules](AGENTS.md). Commit conventions and engineering gates are defined in [`docs/rules/`](docs/rules/README.md).

The current roadmap, test gaps, and known risks are tracked in:

- [Current tasks](docs/workflow/05-tasks/README.md)
- [Verification and coverage](docs/workflow/04-verification/README.md)
- [Issue register](docs/issues/README.md)
- [Change records](docs/changes/README.md)

## Known Limitations

- This repository does not currently contain a Windows AltServer build target.
- The macOS release archive is not yet Developer ID signed or notarized.
- Unicode archive compatibility has implementation-level validation, but persistent automated AltSign fixtures and broader real-device coverage are still being expanded.

## Upstream And License

AltForge is derived from [altstoreio/AltStore](https://github.com/altstoreio/AltStore). The upstream repository remains configured as a separate Git remote so compatible fixes can move in either direction. AltSign-specific compatibility work is maintained in the [AltForge AltSign fork](https://github.com/legeling/AltSign) while remaining traceable to [AltSign upstream](https://github.com/rileytestut/AltSign).

AltForge is distributed under the [GNU Affero General Public License v3.0](LICENSE). Third-party dependencies remain under their respective licenses.
