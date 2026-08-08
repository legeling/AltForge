# AltForge

> A maintained and enhanced AltStore derivative focused on reliability, compatibility, and better sideloading.

[![Swift Version](https://img.shields.io/badge/swift-5.0-orange.svg)](https://swift.org/)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

AltForge builds on [AltStore](https://github.com/altstoreio/AltStore), an iOS application that allows you to sideload other apps (`.ipa` files) with your Apple ID. It preserves the existing AltStore and AltServer architecture while providing an actively maintained home for compatibility fixes and practical enhancements.

## Project Goals

- Resolve long-standing installation and signing issues
- Support Unicode app names and international workflows reliably
- Improve diagnostics, device handling, and installation ergonomics
- Track new iOS and macOS releases without abandoning older regressions
- Contribute suitable fixes back upstream whenever practical

## Features
- Installs apps over WiFi using AltServer
- Resigns and installs any app with your Apple ID
- Preserves Unicode app and resource filenames while extracting and rebuilding IPA files
- Refreshes apps periodically in the background to prevent them from expiring (when on same WiFi as AltServer)
- Handles app updates directly through AltStore 
- Supports Simplified Chinese and iOS per-app language switching

## Minimum Project Requirements
- Xcode 15
- Swift 5.9
- iOS 14.0 (AltStore)
- macOS 11.0 (AltServer)

## Documentation

Project requirements, architecture, verification strategy, change records, known issues, and contributor rules live in [`docs/`](docs/README.md). Start with the [documentation index](docs/README.md) and the project-level [`AGENTS.md`](AGENTS.md) before making cross-module or signing-related changes.

## Project Overview

### AltStore
AltStore is a just regular, sandboxed iOS application. The AltStore app target contains the vast majority of AltStore's functionality, including all the logic for downloading and updating apps through AltStore. AltStore makes heavy use of standard iOS frameworks and technologies most iOS developers are familiar with, such as:
* Core Data
* Storyboards/Nibs
* Auto Layout
* Background App Refresh
* Network.framework (new in iOS 12)

### AltServer
AltServer is also just a regular, sandboxed macOS application. AltServer is significantly less complex than AltStore though, and for that reason consists of only a handful of files.

### AltKit
AltKit is a shared framework that includes common code between AltStore and AltServer.

### AltSign
AltSign is my internal framework used by both AltStore and AltServer to communicate with Apple's servers and resign apps. For more info, check the [AltSign repo](https://github.com/rileytestut/altsign).

### Roxas
Roxas is my internal framework used across all my iOS projects, developed to simplify a variety of common tasks used in iOS development. For more info, check the [Roxas repo](https://github.com/rileytestut/roxas).

## Compilation Instructions
AltStore and AltServer are both fairly straightforward to compile and run if you're already an iOS or macOS developer. To compile AltStore and/or AltServer:

1. Clone the repository 
	``` 
	git clone --recurse-submodules https://github.com/legeling/AltForge.git
	```
2. Update submodules: 
	```
	cd AltForge
	git submodule update --init --recursive
	```
3. Open `AltStore.xcworkspace` and select the AltStore project in the project navigator. On the `Signing & Capabilities` tab, change the team from `Yvette Testut` to your own account.
4. **(AltStore only)** Change the value for `ALTDeviceID` in the Info.plist to your device's UDID. Normally, AltServer embeds the device's UDID in AltStore's Info.plist during installation. When running through Xcode you'll need to set the value yourself or else AltStore won't resign (or even install) apps for the proper device.
5. **(AltStore only)** Change the value for `ALTServerID` in the Info.plist to your AltServer's serverID. This is embedded by AltServer during installation to help AltStore distinguish between multiple AltServers on the same network, and you can find this by using a Bonjour browsing application and noting the serverID advertised by AltServer. This isn't strictly necessary, because if AltStore can't find the AltServer with the embedded serverID it still falls back to trying another AltServer. However, this will help in cases where there are multiple AltServers running (plus the error messages are more helpful).
6. Build + run app! 🎉

## Upstream and Licensing

AltForge is derived from [altstoreio/AltStore](https://github.com/altstoreio/AltStore). Upstream remains configured as a separate Git remote so compatible updates and fixes can move in either direction.

The project is distributed under the **GNU Affero General Public License v3.0**. Third-party dependencies remain under their respective licenses. See [LICENSE](LICENSE) for details.
