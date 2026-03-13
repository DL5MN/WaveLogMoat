# WaveLogMate — Project Plan

> Native macOS menu bar application bridging WSJT-X and Wavelog for automatic QSO logging.

**Author**: DL5MN
**Status**: Active (public repos)
**Last Updated**: 2026-03-11

---

## Table of Contents

- [1. Overview](#1-overview)
- [2. Architecture](#2-architecture)
  - [2a. Technology Choices](#2a-technology-choices)
  - [2b. Key Design Decisions](#2b-key-design-decisions)
  - [2c. Data Flow](#2c-data-flow)
  - [2d. Module Breakdown](#2d-module-breakdown)
- [3. Open Tasks](#3-open-tasks)
- [4. Reference Implementations](#4-reference-implementations)
- [5. Design Decisions Log](#5-design-decisions-log)

---

## 1. Overview

### What This App Does

A native macOS menu bar app that:

1. **Receives** QSO data from WSJT-X via UDP
2. **Parses** incoming ADIF text, XML, or binary QDataStream payloads
3. **Normalizes** data (power units, band from frequency, mode normalization)
4. **Forwards** to the Wavelog `POST /api/qso` endpoint as JSON-wrapped ADIF
5. **Notifies** the user of success/failure via macOS notifications
6. **Displays** real-time WSJT-X status (frequency, mode, DX call) from binary protocol

**NO CAT control** — QSO logging only (unlike WaveLogGate which also does FLRig/Hamlib).

### Naming

"WaveLogMate" continues the Wavelog companion app naming convention:

- WaveLogGate (official Electron app)
- WaveLogGoat (Go-based CAT control)
- WaveLogStoat (Go-based QSO transport CLI)
- **WaveLogMate** (native macOS QSO bridge)

A mate — your companion at the radio, bridging WSJT-X and Wavelog.

---

## 2. Architecture

### 2a. Technology Choices

| Concern           | Choice                             | Rationale                                       |
| ----------------- | ---------------------------------- | ----------------------------------------------- |
| UI Framework      | SwiftUI + `MenuBarExtra`           | macOS 14+ native API, perfect for menu bar apps |
| Min macOS         | macOS 14 (Sonoma)                  | `@Observable` macro, modern SwiftUI features    |
| Networking (UDP)  | `Network.framework` (`NWListener`) | Apple's modern networking, native UDP support   |
| Networking (HTTP) | `URLSession`                       | Native, async/await, certificate trust handling |
| Auto-updates      | Sparkle 2.x via SPM                | Industry standard for non-App Store macOS apps  |
| Settings storage  | `@AppStorage` / `UserDefaults`     | Simple, native, automatic sync                  |
| Secure storage    | Keychain (Security framework)      | API keys must not be in plaintext               |
| Launch at login   | `ServiceManagement` framework      | `SMAppService.mainApp.register()` (macOS 13+)   |
| Notifications     | `UserNotifications` framework      | Native macOS notification center                |
| Package manager   | Swift Package Manager              | Xcode-native, minimal dependencies              |
| CI/CD             | GitHub Actions                     | macOS runners for build/test/sign/notarize      |
| Formatting/Linting | `swift format`                    | Built-in Swift toolchain, no external dependency |

### 2b. Key Design Decisions

1. **ADIF-first data path**: All QSO data flows through the same pipeline regardless of source (text ADIF, XML, or binary). Binary QSO Logged messages (type 5) are converted to QSO models, then to ADIF for the Wavelog API.

2. **Exclusive protocol choice**: Text and binary protocols are mutually exclusive — the user picks one via a segmented control in settings. Text (port 2333) is the default because it uses the WSJT-X Secondary UDP Server and doesn't conflict with other tools. Binary (port 2237) adds real-time status but claims the primary UDP port exclusively.

3. **Keychain for API key**: Unlike WaveLogGate (plaintext config) and WaveLogStoat (plaintext INI), we store the API key in macOS Keychain for proper security.

4. **Menu bar-first, optional dock icon**: `NSApplication.shared.setActivationPolicy(.accessory)` by default (no dock icon). User can toggle dock icon in preferences.

5. **Station profile dropdown**: Instead of making users manually find their station profile ID, we call `/api/station_info` to populate a picker.

6. **@Observable over ObservableObject**: Requires macOS 14+ but produces cleaner code with the `@Observable` macro vs. `@Published` + `ObservableObject`.

7. **Self-signed certificate support**: Many Wavelog instances are self-hosted with self-signed TLS. We support this via `URLSessionDelegate` with a user-visible toggle and appropriate warnings, but the toggle defaults off for secure-by-default behavior.

8. **Structured concurrency**: All async work uses Swift structured concurrency (async/await, TaskGroup) rather than Combine or callback patterns. `AppState` and `UDPService` are `@MainActor`-isolated; UDP listener callbacks hop to the main actor via `Task { @MainActor in }`. Swift 6.2 strict concurrency — zero errors, zero warnings.

### 2c. Data Flow

```
WSJT-X
  │
  │  ┌─────────────────── User selects one protocol ──────────────────┐
  │  │                                                                │
  ├──UDP:2333 (text)──► TextUDPListener ──► Format Detection          │
  │                                              │                    │
  │                                    ┌─────────┴─────────┐          │
  │                                    ▼                   ▼          │
  │                              ADIFParser          XMLContactParser │
  │                                    │                   │          │
  │                                    └─────────┬─────────┘          │
  │                                              ▼                    │
  │                                          QSO (model) ─────────────┤
  │                                                                   │
  └──UDP:2237 (binary)─► BinaryUDPListener ──► QDataStreamReader      │
                                                 │                    │
                                 ┌───────────────┼──────────┐         │
                                 ▼               ▼          ▼         │
                            Heartbeat        Status     QSO Logged    │
                            → update         → update   (type 5)      │
                              connection       WSJTXStatus  │         │
                              indicator        in AppState  ▼         │
                                                        QSO (model) ──┘
                                                            │
                                                     QSONormalizer
                                                (power, band, mode)
                                                            │
                                                     ADIFGenerator
                                                   (QSO → ADIF string)
                                                            │
                                                  WavelogAPIClient
                                               POST /api/qso (JSON)
                                                            │
                                               ┌────────────┴────────────┐
                                            Success                  Failure
                                               │                         │
                                        Notification:            Notification:
                                       "QSO logged:             "Failed to log
                                        DJ7NT on 20m"            QSO: [reason]"
                                               │                         │
                                         AppState.recentQSOs updated (success/fail indicator)
```

### 2d. Module Breakdown

```
┌──────────────────────────────────────────────────────────────────────┐
│                         WaveLogMateApp                               │
│  @main, MenuBarExtra, Settings Window                                │
├──────────────────────────────────────────────────────────────────────┤
│                      AppState (@Observable)                          │
│  Single source of truth: connectionStatus, wsjtxStatus,              │
│  recentQSOs, stationProfiles, isListening, errors                    │
├────────────────┬────────────────┬────────────────┬───────────────────┤
│    Views       │   Services     │    Models      │   Utilities       │
│                │                │                │                   │
│ MenuBarView    │ UDPService     │ QSO            │ BandMap           │
│ SettingsView   │  ├ TextUDP     │ WSJTXStatus    │ ADIFGenerator     │
│  ├ WavelogTab  │  └ BinaryUDP   │ WSJTXMessage   │ KeychainHelper    │
│  ├ WSJTXTab    │ QDataStream    │ WavelogConfig  │ Logger            │
│  ├ GeneralTab  │  Reader        │ ConnectionSt.  │                   │
│  └ AboutTab    │ ADIFParser     │ StationProfile │                   │
│ QSOLogView     │ XMLContact     │ ADIFField      │                   │
│ ConnectionSt.  │  Parser        │                │                   │
│  View          │ QSONormalizer  │                │                   │
│                │ WavelogAPI     │                │                   │
│                │ Notification   │                │                   │
│                │  Service       │                │                   │
│                │ LaunchAtLogin  │                │                   │
│                │  Service       │                │                   │
└────────────────┴────────────────┴────────────────┴───────────────────┘
```

---

## 3. Open Tasks

### 3a. Code Signing & Notarization

**Status**: Done. Developer ID Application certificate (G2 Sub-CA) configured. Release workflow signs with `Developer ID Application`, notarizes via `notarytool`, and staples the ticket before packaging the DMG.

**CI secrets configured:**

- `APPLE_CERTIFICATE_P12` — Base64-encoded .p12 certificate
- `APPLE_CERTIFICATE_PASSWORD` — Certificate password
- `APPLE_ID` — Apple ID email
- `APPLE_TEAM_ID` — Apple Developer Team ID
- `APPLE_APP_PASSWORD` — App-specific password for notarization

### 3b. Sparkle Appcast Setup

**Status**: Done. Sparkle framework integrated, EdDSA key pair generated, `SUPublicEDKey` set in Info.plist. Release pipeline signs DMGs, generates appcast XML, and deploys to GitHub Pages. Appcast uses `CFBundleVersion` (build number) for `sparkle:version` to ensure correct version comparison.

**Completed:**

- GitHub Pages enabled, appcast deployed at `https://dl5mn.github.io/WaveLogMate/appcast.xml`
- `SUFeedURL` set in Info.plist
- `sparkle:version` fixed to use build number instead of version string (prevents false "up to date" results)

### 3c. Homebrew — Official Cask

**Status**: Custom tap (`dl5mn/homebrew-wavelogmate`) exists and auto-updates on release.

**Future:** Submit PR to `homebrew/homebrew-cask` when app has traction (GitHub stars, downloads).

### 3d. Live Testing

**Status**: All 62 unit tests pass. Tested against WSJT-X 3.1.0 and a live Wavelog instance.

**Completed:**

- Text UDP listener with WSJT-X Secondary UDP Server
- Binary UDP listener with WSJT-X Primary UDP Server (heartbeat, status, QSO logging)
- QSO logging end-to-end against a real Wavelog instance
- Settings persistence across app restarts

**Remaining:**

- Verify notification delivery
- Extended field testing across different bands and modes

### 3e. Release Pipeline

**Status**: Done. Multiple releases shipped. Both repos (`dl5mn/WaveLogMate` and `dl5mn/homebrew-wavelogmate`) are public.

**Pipeline**: `make release VERSION=x.y.z` bumps version, auto-increments `CFBundleVersion`, generates changelog (git-cliff), tags, and pushes. CI then builds, signs (Developer ID), notarizes, packages DMG, creates GitHub Release, deploys Sparkle appcast to GitHub Pages, and updates Homebrew cask.

**CI workflows**: Both `build.yml` (push/PR) and `release.yml` (tag) use `make` targets (`make format`, `make lint`, `make test`, `make build`) to keep CI and local dev commands in sync. Locally, `make check` runs all three (format, lint, test) in one command.

**Repo health**: Dependabot (Swift + GitHub Actions, weekly), PR template, security policy (private vulnerability reporting), CodeQL code scanning.

### 3f. Optional Enhancements (Deferred)

- First-launch onboarding flow (guided setup wizard)
- Retry logic for failed QSO submissions
- QSO queue with offline persistence
- Menu bar icon variants (connected/disconnected states)
- Localization (German, at minimum)
- Submit to `homebrew/homebrew-cask` when app has traction

---

## 4. Reference Implementations

### WaveLogStoat (Go CLI)

- **Repository**: https://github.com/int2001/WaveLogStoat
- **Relevance**: Direct reference for UDP→Wavelog data flow, ADIF parsing, normalization

### WaveLogGate (Electron)

- **Repository**: https://github.com/wavelog/WaveLogGate
- **Relevance**: Official companion app, defines the expected UX and API usage patterns

### WSJT-X Protocol Spec

- **Source**: `Network/NetworkMessage.hpp` in WSJT-X source
- **Mirror**: https://github.com/saitohirga/WSJT-X/blob/master/Network/NetworkMessage.hpp

### Wavelog API Documentation

- **URL**: https://docs.wavelog.org/developer/api/

---

## 5. Design Decisions Log

| #   | Decision                         | Rationale                                                                          | Date       |
| --- | -------------------------------- | ---------------------------------------------------------------------------------- | ---------- |
| 1   | macOS 14+ minimum                | `@Observable` macro, modern SwiftUI. Covers ~85%+ active Macs.                     | 2026-03-06 |
| 2   | Binary UDP disabled by default   | Port 2237 conflicts with JT-Bridge/GridTracker. Opt-in with documentation.           | 2026-03-06 |
| 3   | MIT license                      | Matches WaveLogGate (official companion). Permissive for ham radio community.      | 2026-03-06 |
| 4   | Keychain for API key             | Security best practice. WaveLogGate/Stoat use plaintext — we improve on this.      | 2026-03-06 |
| 5   | No CAT control                   | Scope limitation. WaveLogGate already does CAT. We focus on QSO logging.           | 2026-03-06 |
| 6   | Sparkle for updates              | Industry standard for non-App Store macOS. EdDSA signing, GitHub Releases hosting. | 2026-03-06 |
| 7   | Custom Homebrew tap first        | Instant publishing. Submit to homebrew-cask when app has traction.                 | 2026-03-06 |
| 8   | Station profile dropdown via API | Better UX than manual ID entry. `/api/station_info` provides the data.             | 2026-03-06 |
| 9   | App name: WaveLogMoat            | Continues Gate/Goat/Stoat naming. Moat = bridge/guardian. Renamed to WaveLogMate in #28. | 2026-03-06 |
| 10  | CI signing via manual codesign   | `xcodebuild archive` unsigned, then manual `codesign` with Developer ID. Avoids provisioning profile requirement. Sparkle nested bundles signed inside-out. | 2026-03-06 |
| 11  | station_info key in URL path     | Wavelog expects API key at `/api/station_info/{key}`, not in JSON body.            | 2026-03-06 |
| 12  | In-memory API key cache          | Keychain prompts on every read from unsigned builds. Load once, write-through.     | 2026-03-06 |
| 13  | Grouped form settings UI         | `.formStyle(.grouped)` for native macOS card layout. Avoids clipping in 2-col.    | 2026-03-06 |
| 14  | Auto-prefix https:// on URLs     | Users often omit protocol. Prefix https://, hint about http:// on TLS errors.     | 2026-03-06 |
| 15  | Notification denied UX           | Sync toggle to OS state, show warning + "Open Notification Settings" button.       | 2026-03-06 |
| 16  | Dock visibility via policy       | `NSApp.setActivationPolicy(.regular/.accessory)` applied on init and config save.  | 2026-03-06 |
| 17  | Exclusive protocol choice        | Text and binary UDP are mutually exclusive (segmented picker). Eliminates dedup.   | 2026-03-06 |
| 18  | Bundle ID `de.dl5mn.WaveLogMate` | Changed from `com.dl5mn` to `de.dl5mn` to match German country domain convention. | 2026-03-07 |
| 19  | MenuBarExtra local @State sync   | Binding `isInserted` directly to @Observable + UserDefaults causes cfprefsd deadlock in release builds. Fix: local @State with one-directional onChange sync. | 2026-03-08 |
| 20  | CFBundleVersion auto-increment   | Build number increments on each `make release`. Sparkle uses build number for version comparison — prevents false "up to date" when version strings aren't monotonically increasing. | 2026-03-08 |
| 21  | No keychain-access-groups        | This entitlement requires a provisioning profile for Developer ID distribution. Removed it; Keychain API works fine without it for non-sandboxed apps. | 2026-03-07 |
| 22  | `swift format` over SwiftLint    | Built into the Swift toolchain — no `brew install` needed locally or in CI. `.swift-format` config only sets `NeverForceUnwrap: true` (all other rules use defaults). Two lines use `// swift-format-ignore` for trailing-underscore names that avoid Swift keyword conflicts (`operator_`, `protocol_`). | 2026-03-11 |
| 23  | CI uses `make` targets           | Both workflows use `make format`, `make lint`, `make test` instead of raw commands. Single source of truth in the Makefile prevents command drift between local dev and CI. | 2026-03-11 |
| 24  | Swift Testing over XCTest        | All 62 tests migrated to Swift Testing (`@Test`, `#expect`, `@Suite struct`). Less boilerplate, better failure diagnostics, tests run in parallel by default. | 2026-03-11 |
| 25  | Swift Regex over NSRegularExpression | ADIFParser uses `#/(?i)<eor>/#` regex literal with `split(separator:)` instead of `NSRegularExpression` + `stringByReplacingMatches`. Type-safe, no `try!`, simpler code. | 2026-03-11 |
| 26  | Swift 6.2 strict concurrency | Migrated from Swift 5.9 to 6.2, enabling strict concurrency checking. `AppState` and `UDPService` annotated `@MainActor`; UDP listener callbacks wrapped in `Task { @MainActor in }` to hop from background DispatchQueues. All model types were already `Sendable`. Listener classes remain `@unchecked Sendable` (serial DispatchQueue isolation). Zero errors, zero warnings. | 2026-03-11 |
| 27  | Self-signed TLS is opt-in        | Preserve compatibility with self-hosted Wavelog instances, but default `allowSelfSignedCerts` to `false` so certificate trust bypass is an explicit user action instead of the default. | 2026-03-12 |
| 28  | Rename WaveLogMoat → WaveLogMate | "Mate" — your companion at the radio. Better name, same Gate/Goat/Stoat convention. Full rename: bundle ID, Keychain service, module names, Homebrew tap, CI workflows, docs. New bundle ID `de.dl5mn.WaveLogMate`. No migration needed (no existing users). | 2026-03-13 |
