# WaveLogMoat — Project Plan

> Native macOS menu bar application bridging WSJT-X and Wavelog for automatic QSO logging.

**Author**: DL5MN
**Status**: In Development
**Last Updated**: 2026-03-06

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

"WaveLogMoat" continues the Wavelog companion app naming convention:

- WaveLogGate (official Electron app)
- WaveLogGoat (Go-based CAT control)
- WaveLogStoat (Go-based QSO transport CLI)
- **WaveLogMoat** (native macOS QSO bridge)

A moat protects the castle — a bridge/guardian between WSJT-X and Wavelog.

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
| Linting           | SwiftLint                          | Standard Swift linting                          |

### 2b. Key Design Decisions

1. **ADIF-first data path**: All QSO data flows through the same pipeline regardless of source (text ADIF, XML, or binary). Binary QSO Logged messages (type 5) are converted to QSO models, then to ADIF for the Wavelog API.

2. **Exclusive protocol choice**: Text and binary protocols are mutually exclusive — the user picks one via a segmented control in settings. Text (port 2333) is the default because it uses the WSJT-X Secondary UDP Server and doesn't conflict with other tools. Binary (port 2237) adds real-time status but claims the primary UDP port exclusively.

3. **Keychain for API key**: Unlike WaveLogGate (plaintext config) and WaveLogStoat (plaintext INI), we store the API key in macOS Keychain for proper security.

4. **Menu bar-first, optional dock icon**: `NSApplication.shared.setActivationPolicy(.accessory)` by default (no dock icon). User can toggle dock icon in preferences.

5. **Station profile dropdown**: Instead of making users manually find their station profile ID, we call `/api/station_info` to populate a picker.

6. **@Observable over ObservableObject**: Requires macOS 14+ but produces cleaner code with the `@Observable` macro vs. `@Published` + `ObservableObject`.

7. **Self-signed certificate support**: Many Wavelog instances are self-hosted with self-signed TLS. We support this via `URLSessionDelegate` with a user-visible toggle and appropriate warnings.

8. **Structured concurrency**: All async work uses Swift structured concurrency (async/await, TaskGroup) rather than Combine or callback patterns.

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
│                         WaveLogMoatApp                               │
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

**Status**: Sparkle framework integrated, EdDSA key pair generated, `SUPublicEDKey` set in Info.plist. Release pipeline signs DMGs and generates appcast XML for GitHub Pages deployment.

**Remaining:**

- Enable GitHub Pages on the repository (requires public repo or GitHub Pro)
- Update `SUFeedURL` in Info.plist with the actual GitHub Pages URL
- Verify end-to-end update flow with a tagged release

### 3c. Homebrew — Official Cask

**Status**: Custom tap (`dl5mn/homebrew-wavelogmoat`) exists and auto-updates on release.

**Future:** Submit PR to `homebrew/homebrew-cask` when app has traction (GitHub stars, downloads).

### 3d. Live Testing

**Status**: All 44 unit tests pass. Tested against WSJT-X 3.1.0 and a live Wavelog instance.

**Completed:**

- Text UDP listener with WSJT-X Secondary UDP Server
- Binary UDP listener with WSJT-X Primary UDP Server (heartbeat, status, QSO logging)
- QSO logging end-to-end against a real Wavelog instance
- Settings persistence across app restarts

**Remaining:**

- Verify notification delivery
- Extended field testing across different bands and modes

### 3e. First Release

**Status**: Release pipeline (`release.yml`) is configured with lint, test, archive, DMG, changelog (git-cliff), GitHub Release, and Homebrew tap update.

**Remaining:**

- Take screenshots for README
- Tag `v0.1.0` and verify full pipeline
- Consider whether to make repos public before or after first release

### 3f. Optional Enhancements (Deferred)

- First-launch onboarding flow (guided setup wizard)
- Retry logic for failed QSO submissions
- QSO queue with offline persistence
- Menu bar icon variants (connected/disconnected states)
- Localization (German, at minimum)

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
| 9   | App name: WaveLogMoat            | Continues Gate/Goat/Stoat naming. Moat = bridge/guardian.                          | 2026-03-06 |
| 10  | CI signing deferred              | Developer ID account pending. Pipeline prepared for secrets.                       | 2026-03-06 |
| 11  | station_info key in URL path     | Wavelog expects API key at `/api/station_info/{key}`, not in JSON body.            | 2026-03-06 |
| 12  | In-memory API key cache          | Keychain prompts on every read from unsigned builds. Load once, write-through.     | 2026-03-06 |
| 13  | Grouped form settings UI         | `.formStyle(.grouped)` for native macOS card layout. Avoids clipping in 2-col.    | 2026-03-06 |
| 14  | Auto-prefix https:// on URLs     | Users often omit protocol. Prefix https://, hint about http:// on TLS errors.     | 2026-03-06 |
| 15  | Notification denied UX           | Sync toggle to OS state, show warning + "Open Notification Settings" button.       | 2026-03-06 |
| 16  | Dock visibility via policy       | `NSApp.setActivationPolicy(.regular/.accessory)` applied on init and config save.  | 2026-03-06 |
| 17  | Exclusive protocol choice        | Text and binary UDP are mutually exclusive (segmented picker). Eliminates dedup.   | 2026-03-06 |
