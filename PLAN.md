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

1. **Listens** on UDP ports for QSO data from WSJT-X
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

| Concern | Choice | Rationale |
|---------|--------|-----------|
| UI Framework | SwiftUI + `MenuBarExtra` | macOS 14+ native API, perfect for menu bar apps |
| Min macOS | macOS 14 (Sonoma) | `@Observable` macro, modern SwiftUI features |
| Networking (UDP) | `Network.framework` (`NWListener`) | Apple's modern networking, native UDP support |
| Networking (HTTP) | `URLSession` | Native, async/await, certificate trust handling |
| Auto-updates | Sparkle 2.x via SPM | Industry standard for non-App Store macOS apps |
| Settings storage | `@AppStorage` / `UserDefaults` | Simple, native, automatic sync |
| Secure storage | Keychain (Security framework) | API keys must not be in plaintext |
| Launch at login | `ServiceManagement` framework | `SMAppService.mainApp.register()` (macOS 13+) |
| Notifications | `UserNotifications` framework | Native macOS notification center |
| Package manager | Swift Package Manager | Xcode-native, minimal dependencies |
| CI/CD | GitHub Actions | macOS runners for build/test/sign/notarize |
| Linting | SwiftLint | Standard Swift linting |

### 2b. Key Design Decisions

1. **ADIF-first data path**: All QSO data flows through the same pipeline regardless of source (text ADIF, XML, or binary). Binary QSO Logged messages are converted to QSO models, then to ADIF for the Wavelog API. The Logged ADIF message (type 12) provides ready-made ADIF and is the preferred path.

2. **Binary protocol opt-in**: The primary UDP binary protocol (port 2237) is **disabled by default** because it may conflict with JTAlert, GridTracker, or other tools that also listen on that port. Users enable it explicitly in settings with clear documentation.

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
  ├──UDP:2333 (text)──► TextUDPListener ──► Format Detection
  │                                              │
  │                                    ┌─────────┴─────────┐
  │                                    ▼                   ▼
  │                              ADIFParser          XMLContactParser
  │                                    │                   │
  │                                    └─────────┬─────────┘
  │                                              ▼
  ├──UDP:2237 (binary)─► BinaryUDPListener ──► QDataStreamReader
  │                                              │
  │                              ┌───────────────┼───────────────┐
  │                              ▼               ▼               ▼
  │                         Heartbeat        Status          QSO Logged /
  │                         → update         → update        Logged ADIF
  │                           connection       WSJTXStatus      │
  │                           indicator        in AppState      ▼
  │                                                         QSO (model)
  │                                                             │
  └─────────────────────────────────────────────────────────────┘
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
                                                   │                        │
                                            Notification:            Notification:
                                           "QSO logged:             "Failed to log
                                            DJ7NT on 20m"            QSO: [reason]"
                                                   │                        │
                                             AppState.recentQSOs updated (success/fail indicator)
```

### 2d. Module Breakdown

```
┌──────────────────────────────────────────────────────────────────────┐
│                         WaveLogMoatApp                                │
│  @main, MenuBarExtra, Settings Window                                │
├──────────────────────────────────────────────────────────────────────┤
│                      AppState (@Observable)                           │
│  Single source of truth: connectionStatus, wsjtxStatus,              │
│  recentQSOs, stationProfiles, isListening, errors                    │
├────────────────┬────────────────┬────────────────┬───────────────────┤
│    Views       │   Services     │    Models      │   Utilities       │
│                │                │                │                   │
│ MenuBarView    │ UDPService     │ QSO            │ BandMap           │
│ SettingsView   │  ├ TextUDP     │ WSJTXStatus    │ ADIFGenerator     │
│  ├ WavelogTab  │  └ BinaryUDP  │ WSJTXMessage   │ KeychainHelper    │
│  ├ WSJTXTab    │ QDataStream   │ WavelogConfig  │ Logger            │
│  ├ GeneralTab  │  Reader       │ ConnectionSt.  │                   │
│  └ AboutTab    │ ADIFParser    │ StationProfile │                   │
│ QSOLogView     │ XMLContact    │ ADIFField      │                   │
│ ConnectionSt.  │  Parser       │                │                   │
│  View          │ QSONormalizer │                │                   │
│                │ WavelogAPI    │                │                   │
│                │ Notification  │                │                   │
│                │  Service      │                │                   │
│                │ LaunchAtLogin │                │                   │
│                │  Service      │                │                   │
└────────────────┴────────────────┴────────────────┴───────────────────┘
```

---

## 3. Open Tasks

### 3a. Code Signing & Notarization

**Status**: Developer ID account to be acquired.

**Setup (when ready):**
- Apple Developer ID Application certificate
- Store certificate + password as GitHub Actions encrypted secrets
- Use `apple-actions/import-codesign-certs` in CI
- Notarize with `notarytool` (Xcode 14+)
- Staple notarization ticket to DMG

**Without signing (current):**
- Users run: `xattr -d com.apple.quarantine /Applications/WaveLogMoat.app`
- Documented in README

**CI secrets needed:**
- `APPLE_CERTIFICATE_P12` — Base64-encoded .p12 certificate
- `APPLE_CERTIFICATE_PASSWORD` — Certificate password
- `APPLE_ID` — Apple ID email
- `APPLE_TEAM_ID` — Apple Developer Team ID
- `APPLE_APP_PASSWORD` — App-specific password for notarization

### 3b. Sparkle Appcast Setup

**Status**: Sparkle framework integrated, `SPUStandardUpdaterController` wired, "Check for Updates" menu item present. Appcast URL in Info.plist is placeholder.

**Remaining:**
- Generate EdDSA (Ed25519) key pair for update signing
- Create appcast XML (hosted on GitHub Pages or in release assets)
- Update `SUFeedURL` in Info.plist with real URL
- Add appcast generation step to release pipeline

### 3c. Homebrew — Official Cask

**Status**: Custom tap (`dl5mn/homebrew-wavelogmoat`) exists and auto-updates on release.

**Future:** Submit PR to `homebrew/homebrew-cask` when app has traction (GitHub stars, downloads).

### 3d. Live Testing

**Status**: All 42 unit tests pass. App builds and launches. Not yet tested against a live WSJT-X instance.

**Remaining:**
- Test text UDP listener with WSJT-X Secondary UDP Server
- Test binary UDP listener with WSJT-X Primary UDP Server
- Test QSO logging end-to-end against a real Wavelog instance
- Verify notification delivery
- Test settings persistence across app restarts

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

| # | Decision | Rationale | Date |
|---|----------|-----------|------|
| 1 | macOS 14+ minimum | `@Observable` macro, modern SwiftUI. Covers ~85%+ active Macs. | 2026-03-06 |
| 2 | Binary UDP disabled by default | Port 2237 conflicts with JTAlert/GridTracker. Opt-in with documentation. | 2026-03-06 |
| 3 | MIT license | Matches WaveLogGate (official companion). Permissive for ham radio community. | 2026-03-06 |
| 4 | Keychain for API key | Security best practice. WaveLogGate/Stoat use plaintext — we improve on this. | 2026-03-06 |
| 5 | No CAT control | Scope limitation. WaveLogGate already does CAT. We focus on QSO logging. | 2026-03-06 |
| 6 | Sparkle for updates | Industry standard for non-App Store macOS. EdDSA signing, GitHub Releases hosting. | 2026-03-06 |
| 7 | Custom Homebrew tap first | Instant publishing. Submit to homebrew-cask when app has traction. | 2026-03-06 |
| 8 | Station profile dropdown via API | Better UX than manual ID entry. `/api/station_info` provides the data. | 2026-03-06 |
| 9 | App name: WaveLogMoat | Continues Gate/Goat/Stoat naming. Moat = bridge/guardian. | 2026-03-06 |
| 10 | CI signing deferred | Developer ID account pending. Pipeline prepared for secrets. | 2026-03-06 |
