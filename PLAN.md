# WaveLogMoat — Project Plan

> Native macOS menu bar application bridging WSJT-X and Wavelog for automatic QSO logging.

**Author**: DL5MN
**Status**: Planning
**Last Updated**: 2026-03-06

---

## Table of Contents

- [1. Overview](#1-overview)
- [2. Technical Findings](#2-technical-findings)
  - [2a. WSJT-X Protocol](#2a-wsjt-x-protocol)
  - [2b. Wavelog API](#2b-wavelog-api)
  - [2c. Configuration Surface](#2c-configuration-surface)
  - [2d. Data Normalization](#2d-data-normalization)
- [3. Architecture](#3-architecture)
  - [3a. Project Structure](#3a-project-structure)
  - [3b. Technology Choices](#3b-technology-choices)
  - [3c. Key Design Decisions](#3c-key-design-decisions)
  - [3d. Data Flow](#3d-data-flow)
  - [3e. Module Breakdown](#3e-module-breakdown)
  - [3f. QDataStream Binary Parser](#3f-qdatastream-binary-parser)
  - [3g. Services](#3g-services)
  - [3h. Settings Model](#3h-settings-model)
  - [3i. Menu Bar UX](#3i-menu-bar-ux)
  - [3j. Settings Window](#3j-settings-window)
- [4. Distribution Pipeline](#4-distribution-pipeline)
- [5. Implementation Plan](#5-implementation-plan)
- [6. Reference Implementations](#6-reference-implementations)
- [7. Design Decisions Log](#7-design-decisions-log)

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

## 2. Technical Findings

### 2a. WSJT-X Protocol

There are **two distinct UDP paths** for receiving QSO data from WSJT-X:

| Path | Port | Format | When Sent | Used By |
|------|------|--------|-----------|---------|
| **Secondary UDP Server** | 2333 (default) | Raw ADIF text or XML `<contactinfo>` | User clicks "Log QSO" | WaveLogGate, WaveLogStoat |
| **Primary UDP Server** | 2237 (default) | Binary QDataStream (Qt serialization) | Heartbeat, Status changes, QSO Logged, etc. | JTAlert, GridTracker |

#### Secondary UDP (Text Protocol)

Simple text payloads. Two formats:

**ADIF format:**
```
<call:5>DJ7NT<mode:3>FT8<freq:8>7.074000<qso_date:8>20240110<time_on:6>120000<rst_sent:3>-15<rst_rcvd:3>-10<band:3>20m<eor>
```

**XML format** (from some loggers like N1MM):
```xml
<contactinfo>
  <timestamp>2024-01-10T12:00:00</timestamp>
  <call>DJ7NT</call>
  <mode>FT8</mode>
  <txfreq>7074000</txfreq>
  <rxfreq>7074000</rxfreq>
  <rcv>-10</rcv>
  <snt>-15</snt>
  <power>100</power>
  <operator>DL5MN</operator>
  <comment></comment>
  <sntnr></sntnr>
  <rcvnr></rcvnr>
  <mycall>DL5MN</mycall>
  <gridsquare>JO30</gridsquare>
</contactinfo>
```

Format detection: presence of `"xml"` in the string → XML, otherwise ADIF.

#### Primary UDP (Binary Protocol)

Documented in WSJT-X source: `Network/NetworkMessage.hpp`
Source: https://github.com/saitohirga/WSJT-X/blob/master/Network/NetworkMessage.hpp

**Wire format (big-endian):**

```
[magic: 0xadbccbda (4 bytes)]
[schema: UInt32 (4 bytes)]        // Currently 3 (Qt_5_4)
[type: UInt32 (4 bytes)]          // Message type enum
[id: utf8]                        // Client identifier string
[...payload fields per type...]
```

**Message types we care about:**

| Type | Value | Direction | Purpose |
|------|-------|-----------|---------|
| Heartbeat | 0 | Out/In | Connection keepalive (every 15s) |
| Status | 1 | Out | Dial freq, mode, DX call, TX state, etc. |
| QSO Logged | 5 | Out | Structured QSO data on "Log QSO" click |
| Close | 6 | Out/In | Graceful shutdown notification |
| Logged ADIF | 12 | Out | Complete ADIF record on "Log QSO" click |

**Message Type 0 — Heartbeat:**
- Id (utf8)
- Maximum schema number (quint32)
- Version (utf8)
- Revision (utf8)

**Message Type 1 — Status:**
- Id (utf8)
- Dial Frequency Hz (quint64)
- Mode (utf8)
- DX call (utf8)
- Report (utf8)
- Tx Mode (utf8)
- Tx Enabled (bool)
- Transmitting (bool)
- Decoding (bool)
- Rx DF (quint32)
- Tx DF (quint32)
- DE call (utf8)
- DE grid (utf8)
- DX grid (utf8)
- Tx Watchdog (bool)
- Sub-mode (utf8)
- Fast mode (bool)
- Special Operation Mode (quint8)
- Frequency Tolerance (quint32)
- T/R Period (quint32)
- Configuration Name (utf8)
- Tx Message (utf8)

**Message Type 5 — QSO Logged:**
- Id (utf8)
- Date & Time Off (QDateTime)
- DX call (utf8)
- DX grid (utf8)
- Tx frequency Hz (quint64)
- Mode (utf8)
- Report sent (utf8)
- Report received (utf8)
- Tx power (utf8)
- Comments (utf8)
- Name (utf8)
- Date & Time On (QDateTime)
- Operator call (utf8)
- My call (utf8)
- My grid (utf8)
- Exchange sent (utf8)
- Exchange received (utf8)
- ADIF Propagation mode (utf8)

**Message Type 12 — Logged ADIF:**
- Id (utf8)
- ADIF text (utf8) — complete ADIF file with header + one record

**QDataStream type encoding:**

| Qt Type | Wire Format | Swift |
|---------|-------------|-------|
| quint32 | 4 bytes big-endian unsigned | UInt32 |
| quint64 | 8 bytes big-endian unsigned | UInt64 |
| qint32 | 4 bytes big-endian signed | Int32 |
| qint64 | 8 bytes big-endian signed | Int64 |
| bool | 1 byte (0x00 or 0x01) | Bool |
| utf8 (QByteArray) | quint32 length + N bytes (0xFFFFFFFF = null) | String? |
| float (as double) | 8 bytes IEEE 754 big-endian | Double |
| QTime | quint32 milliseconds since midnight | → Date |
| QDateTime | qint64 Julian day + quint32 ms + quint8 timespec [+ offset/tz] | → Date |

**Schema negotiation:** Server and client negotiate via Heartbeat. Current schema is 3 (Qt_5_4). Older schemas (1, 2) used different QDataStream versions. We should support schema 2+ for compatibility.

**Backward compatibility rules:**
1. Ignore unknown message types silently
2. New fields are always appended; ignore extra data after known fields

### 2b. Wavelog API

Documentation: https://docs.wavelog.org/developer/api/

**Primary endpoint — Log QSO:**

```
POST {wavelog_url}/api/qso
Content-Type: application/json
Accept: application/json
```

Payload:
```json
{
  "key": "YOUR_API_KEY",
  "station_profile_id": "1",
  "type": "adif",
  "string": "<call:5>DJ7NT<mode:3>FT8<freq:8>7.074000<qso_date:8>20240110<time_on:6>120000<rst_sent:3>-15<rst_rcvd:3>-10<band:3>20m<eor>"
}
```

Response (success):
```json
{"status": "created"}
```

Response (failure):
```json
{"status": "failed", "messages": ["reason"]}
```

**Dry-run test endpoint:**
```
POST {wavelog_url}/api/qso/true
```
Same payload, but does not persist the QSO. Used by WaveLogGate for "Test Connection".

**Station info endpoint:**
```
POST {wavelog_url}/api/station_info
```
Payload: `{"key": "YOUR_API_KEY"}`

Response:
```json
[
  {
    "station_id": "1",
    "station_profile_name": "JO30oo / DL5MN",
    "station_gridsquare": "JO30OO",
    "station_callsign": "DL5MN",
    "station_active": "1"
  }
]
```

**Version check endpoint:**
```
POST {wavelog_url}/api/version
```
Payload: `{"key": "YOUR_API_KEY"}`

Response: `{"status": "ok", "version": "2.0"}`

**Important notes:**
- API key must be Read+Write type
- `station_profile_id` is found in station location settings (or via `/api/station_info`)
- URL typically includes `/index.php` (e.g., `https://log.example.com/index.php`)
- Self-signed TLS certificates are common (self-hosted Wavelog instances)
- Posted QSOs do NOT trigger live QRZ posting or callbook lookups (done separately)
- Headers: `Content-Type: application/json`, User-Agent recommended

### 2c. Configuration Surface

| Setting | Required | Default | Notes |
|---------|----------|---------|-------|
| Wavelog URL | Yes | — | Base URL including `/index.php` |
| API Key | Yes | — | Read+Write key, stored in Keychain |
| Station Profile ID | Yes | — | Selected from dropdown (fetched via API) |
| Text UDP Port | No | 2333 | Secondary UDP server port |
| Binary UDP Port | No | 2237 | Primary UDP server port |
| Listen Address | No | 127.0.0.1 | 0.0.0.0 for LAN access |
| Enable Text UDP | No | true | Default ON |
| Enable Binary UDP | No | false | Default OFF (may conflict with JTAlert) |
| HTTP Timeout | No | 5000ms | API request timeout |
| Allow Self-Signed Certs | No | true | For self-hosted Wavelog |
| Show in Dock | No | false | Toggle dock icon |
| Show in Menu Bar | No | true | Toggle menu bar icon |
| Launch at Login | No | false | ServiceManagement |
| Show Notifications | No | true | macOS notifications |
| Show Frequency in Menu Bar | No | true | From binary Status messages |

### 2d. Data Normalization

Based on WaveLogStoat's normalizer:

1. **Power**: Convert kW→W (×1000), mW→W (×0.001), strip unit suffixes
2. **Band**: Calculate from frequency using standard amateur band map:
   - 1.800–2.000 → 160m, 3.500–4.000 → 80m, 5.330–5.400 → 60m
   - 7.000–7.300 → 40m, 10.100–10.150 → 30m, 14.000–14.350 → 20m
   - 18.068–18.168 → 17m, 21.000–21.450 → 15m, 24.890–24.990 → 12m
   - 28.000–29.700 → 10m, 50.000–54.000 → 6m, 144.000–148.000 → 2m
   - 222.000–225.000 → 1.25m, 420.000–450.000 → 70cm
   - 902.000–928.000 → 33cm, 1240.000–1300.000 → 23cm
3. **Mode**: USB/LSB → SSB for ADIF compatibility
4. **Frequency**: Hz → MHz when parsing XML (XML sends Hz, ADIF uses MHz)
5. **K-Index**: Clamp to 0–9 integer range (if present)
6. **Timestamps**: Support multiple formats (ISO 8601, N1MM, DXLog variants)

---

## 3. Architecture

### 3a. Project Structure

```
WaveLogMoat/
├── .github/
│   ├── workflows/
│   │   ├── build.yml              # CI: build + test on PRs
│   │   ├── release.yml            # CD: build, sign, notarize, release
│   │   └── update-homebrew.yml    # Update Homebrew tap on release
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
├── WaveLogMoat/                   # Xcode project source
│   ├── App/
│   │   ├── WaveLogMoatApp.swift   # @main, MenuBarExtra, App lifecycle
│   │   ├── AppDelegate.swift      # NSApplicationDelegate for deeper control
│   │   └── AppState.swift         # @Observable app state (single source of truth)
│   ├── Views/
│   │   ├── MenuBarView.swift      # Menu bar dropdown content
│   │   ├── SettingsView.swift     # Preferences window (tabbed)
│   │   ├── WavelogSettingsTab.swift
│   │   ├── WSJTXSettingsTab.swift
│   │   ├── GeneralSettingsTab.swift
│   │   ├── AboutTab.swift
│   │   ├── QSOLogView.swift       # Recent QSO activity list
│   │   └── ConnectionStatusView.swift
│   ├── Services/
│   │   ├── UDPService.swift       # Manages both UDP listeners
│   │   ├── TextUDPListener.swift  # Plain ADIF/XML listener (port 2333)
│   │   ├── BinaryUDPListener.swift # QDataStream binary listener (port 2237)
│   │   ├── QDataStreamReader.swift # Qt QDataStream binary decoder
│   │   ├── ADIFParser.swift       # ADIF text → QSO
│   │   ├── XMLContactParser.swift # WSJT-X XML <contactinfo> → QSO
│   │   ├── QSONormalizer.swift    # Power/band/mode normalization
│   │   ├── ADIFGenerator.swift    # QSO → ADIF string
│   │   ├── WavelogAPIClient.swift # HTTP client for Wavelog REST API
│   │   ├── NotificationService.swift # macOS UserNotifications
│   │   └── LaunchAtLoginService.swift # ServiceManagement integration
│   ├── Models/
│   │   ├── QSO.swift              # QSO data model (all ADIF fields)
│   │   ├── WSJTXStatus.swift      # Live WSJT-X status from binary Status msg
│   │   ├── WSJTXMessage.swift     # Enum for binary message types
│   │   ├── WavelogConfig.swift    # Settings model (Codable, @AppStorage)
│   │   ├── ConnectionStatus.swift # Connection state enum
│   │   ├── StationProfile.swift   # Wavelog station profile model
│   │   └── ADIFField.swift        # ADIF field type definitions
│   ├── Utilities/
│   │   ├── BandMap.swift          # Frequency → band lookup table
│   │   ├── KeychainHelper.swift   # Secure API key storage
│   │   └── Logger.swift           # os.Logger wrappers
│   ├── Resources/
│   │   ├── Assets.xcassets        # App icon, menu bar icon
│   │   └── Localizable.strings
│   └── Info.plist
├── WaveLogMoatTests/
│   ├── ADIFParserTests.swift
│   ├── XMLContactParserTests.swift
│   ├── QDataStreamReaderTests.swift
│   ├── QSONormalizerTests.swift
│   ├── BandMapTests.swift
│   ├── ADIFGeneratorTests.swift
│   └── WavelogAPIClientTests.swift
├── WaveLogMoat.xcodeproj/
├── Homebrew/
│   └── wavelogmoat.rb             # Homebrew cask formula (for tap)
├── README.md
├── CONTRIBUTING.md
├── LICENSE                         # MIT
├── CHANGELOG.md
├── PLAN.md                         # This file
├── Makefile                        # Convenience build commands
└── .swiftlint.yml
```

### 3b. Technology Choices

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

### 3c. Key Design Decisions

1. **ADIF-first data path**: All QSO data flows through the same pipeline regardless of source (text ADIF, XML, or binary). Binary QSO Logged messages are converted to QSO models, then to ADIF for the Wavelog API. The Logged ADIF message (type 12) provides ready-made ADIF and is the preferred path.

2. **Binary protocol opt-in**: The primary UDP binary protocol (port 2237) is **disabled by default** because it may conflict with JTAlert, GridTracker, or other tools that also listen on that port. Users enable it explicitly in settings with clear documentation.

3. **Keychain for API key**: Unlike WaveLogGate (plaintext config) and WaveLogStoat (plaintext INI), we store the API key in macOS Keychain for proper security.

4. **Menu bar-first, optional dock icon**: `NSApplication.shared.setActivationPolicy(.accessory)` by default (no dock icon). User can toggle dock icon in preferences.

5. **Station profile dropdown**: Instead of making users manually find their station profile ID, we call `/api/station_info` to populate a picker.

6. **@Observable over ObservableObject**: Requires macOS 14+ but produces cleaner code with the `@Observable` macro vs. `@Published` + `ObservableObject`.

7. **Self-signed certificate support**: Many Wavelog instances are self-hosted with self-signed TLS. We support this via `URLSessionDelegate` with a user-visible toggle and appropriate warnings.

8. **Structured concurrency**: All async work uses Swift structured concurrency (async/await, TaskGroup) rather than Combine or callback patterns.

### 3d. Data Flow

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

### 3e. Module Breakdown

```
┌──────────────────────────────────────────────────────────────────────┐
│                         WaveLogMoatApp                                │
│  @main, MenuBarExtra, Settings Window, AppDelegate                   │
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

### 3f. QDataStream Binary Parser

The WSJT-X binary protocol uses Qt's QDataStream serialization. We implement a `QDataStreamReader` in Swift:

```swift
/// Reads Qt QDataStream serialized data from a byte buffer.
/// Big-endian format, schema version 2 or 3.
class QDataStreamReader {
    func readUInt32() throws -> UInt32
    func readUInt64() throws -> UInt64
    func readInt32() throws -> Int32
    func readInt64() throws -> Int64
    func readBool() throws -> Bool
    func readUTF8() throws -> String?       // QByteArray: len + bytes, null = 0xFFFFFFFF
    func readDouble() throws -> Double
    func readQTime() throws -> UInt32       // ms since midnight
    func readQDateTime() throws -> Date?    // Julian day + ms + timespec
}
```

**QDateTime decoding:**
- Read `qint64` Julian day number
- Read `quint32` milliseconds since midnight
- Read `quint8` timespec (0=local, 1=UTC, 2=offset, 3=timezone)
- If timespec=2, read `qint32` offset seconds
- Convert Julian day to Gregorian date, add milliseconds

**Message parsing flow:**
1. Verify magic number `0xadbccbda`
2. Read schema version
3. Read message type
4. Read client ID (utf8)
5. Based on message type, read remaining fields in order
6. Ignore any extra bytes (backward compatibility)

### 3g. Services

**UDPService** — Orchestrates both listeners:
```swift
@Observable
class UDPService {
    var isTextListening: Bool
    var isBinaryListening: Bool
    
    func startTextListener(port: UInt16, address: String) async throws
    func startBinaryListener(port: UInt16, address: String) async throws
    func stop()
    
    // Callbacks
    var onQSOReceived: ((QSO) -> Void)?
    var onHeartbeat: ((String, String) -> Void)?     // id, version
    var onStatusUpdate: ((WSJTXStatus) -> Void)?
    var onClose: ((String) -> Void)?                  // id
}
```

**WavelogAPIClient:**
```swift
class WavelogAPIClient {
    func logQSO(adif: String, config: WavelogConfig, apiKey: String) async throws -> Bool
    func testConnection(config: WavelogConfig, apiKey: String) async throws -> Bool
    func fetchStationProfiles(config: WavelogConfig, apiKey: String) async throws -> [StationProfile]
    func fetchVersion(config: WavelogConfig, apiKey: String) async throws -> String
}
```

Self-signed cert support via `URLSessionDelegate`:
```swift
func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async 
    -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    if config.allowSelfSignedCerts {
        return (.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    return (.performDefaultHandling, nil)
}
```

### 3h. Settings Model

```swift
struct WavelogConfig: Codable {
    // Wavelog connection
    var wavelogURL: String = ""              // e.g., "https://log.example.com/index.php"
    var stationProfileID: String = ""        // Selected from dropdown
    // API key stored separately in Keychain
    
    // UDP listener — Text protocol
    var textUDPPort: UInt16 = 2333
    var enableTextUDP: Bool = true
    
    // UDP listener — Binary protocol
    var binaryUDPPort: UInt16 = 2237
    var enableBinaryUDP: Bool = false        // OFF by default (may conflict with JTAlert)
    
    // UDP listener — Common
    var listenAddress: String = "127.0.0.1"
    
    // Behavior
    var showInDock: Bool = false
    var showInMenuBar: Bool = true
    var launchAtLogin: Bool = false
    var showNotifications: Bool = true
    var allowSelfSignedCerts: Bool = true
    var httpTimeout: Int = 5000              // milliseconds
    
    // Display
    var showFrequencyInMenuBar: Bool = true  // From binary Status messages
}
```

### 3i. Menu Bar UX

```
┌─────────────────────────────────────┐
│  📡 WaveLogMoat  14.074 FT8        │  ← Menu bar icon + optional freq/mode
├─────────────────────────────────────┤
│  ● Connected to WSJT-X             │  ← Green dot (heartbeat active)
│  ● Connected to Wavelog            │  ← Green dot (last API call OK)
├─────────────────────────────────────┤
│  Recent QSOs:                       │
│  12:34 DL5MN ↔ W1AW  20m FT8  ✓   │  ← Last 5 QSOs with status
│  12:31 DL5MN ↔ JA1ABC 40m FT8 ✓   │
│  12:28 DL5MN ↔ VK3XX  15m CW  ✗   │  ← Failed ones marked
├─────────────────────────────────────┤
│  Settings...              ⌘,        │
│  About WaveLogMoat                  │
│  Check for Updates...               │
│  Quit                     ⌘Q        │
└─────────────────────────────────────┘
```

Connection status indicators:
- 🟢 Green: Connected / last operation successful
- 🔴 Red: Error / disconnected
- ⚪ Gray: Not configured / disabled
- 🟡 Yellow: Connecting / warning

Menu bar label options (user-configurable):
- Icon only (minimal)
- Icon + frequency + mode (when binary protocol provides Status)
- Icon + "WaveLogMoat" text

### 3j. Settings Window

**Tab 1: Wavelog**
- URL text field with placeholder "https://log.example.com/index.php"
- API Key secure field with paste button
- Station Profile picker (auto-populated via `/api/station_info`)
- "Test Connection" button → calls `/api/qso/true` → green checkmark or red X
- Allow self-signed certificates toggle
- HTTP timeout stepper

**Tab 2: WSJT-X**
- Listen address field (default: 127.0.0.1)
- Text UDP section:
  - Enable toggle (default: ON)
  - Port field (default: 2333)
- Binary UDP section:
  - Enable toggle (default: OFF)
  - Port field (default: 2237)
  - Note: "May conflict with JTAlert or GridTracker if they use the same port"
- Connection status indicators for each listener

**Tab 3: General**
- Launch at login toggle
- Show in dock toggle
- Show in menu bar toggle (always on if dock is off)
- Show frequency in menu bar toggle
- Enable notifications toggle
- Notification sound toggle

**Tab 4: About**
- App icon and version
- Build info (commit hash, build date)
- Links: GitHub repository, Wavelog docs, WSJT-X docs
- "Check for Updates" button
- Credits / license info

---

## 4. Distribution Pipeline

### 4a. Code Signing & Notarization

**Status**: Developer ID account to be acquired soon.

**Setup (when ready):**
- Apple Developer ID Application certificate
- Store certificate + password as GitHub Actions encrypted secrets
- Use `apple-actions/import-codesign-certs` in CI
- Notarize with `notarytool` (Xcode 14+)
- Staple notarization ticket to DMG

**Without signing (initial):**
- Users run: `xattr -d com.apple.quarantine /Applications/WaveLogMoat.app`
- Document this clearly in README

**CI secrets needed:**
- `APPLE_CERTIFICATE_P12` — Base64-encoded .p12 certificate
- `APPLE_CERTIFICATE_PASSWORD` — Certificate password
- `APPLE_ID` — Apple ID email
- `APPLE_TEAM_ID` — Apple Developer Team ID
- `APPLE_APP_PASSWORD` — App-specific password for notarization

### 4b. Auto-Updates (Sparkle)

- Sparkle 2.x integrated via Swift Package Manager
- `SPUStandardUpdaterController` initialized in app
- Appcast XML hosted on GitHub Pages (or in release assets)
- EdDSA (Ed25519) signing for update packages (Sparkle's built-in)
- Update check on app launch + manual "Check for Updates" button
- Download URL points to GitHub Releases DMG

**Sparkle integration pattern** (from reference apps):
```swift
import Sparkle

let updaterController = SPUStandardUpdaterController(
    startingUpdater: true,
    updaterDelegate: nil,
    userDriverDelegate: nil
)
```

### 4c. Homebrew

**Phase 1: Custom tap**
- Create `homebrew-wavelogmoat` repository
- Cask formula points to GitHub Release DMG
- Install: `brew tap dl5mn/wavelogmoat && brew install --cask wavelogmoat`

**Phase 2: Official homebrew-cask** (when app is stable with users)
- Submit PR to `homebrew/homebrew-cask`
- Must meet minimum requirements: notable (GitHub stars, downloads)

### 4d. GitHub Actions Workflows

**build.yml** (on PR + push to main):
```yaml
- Checkout
- Set up Xcode (latest stable)
- Resolve SPM dependencies
- Build (xcodebuild)
- Run tests (xcodebuild test)
- SwiftLint
```

**release.yml** (on tag push v*):
```yaml
- Checkout
- Set up Xcode
- Import signing certificate (when available)
- Build release
- Sign app (when available)
- Notarize (when available)
- Create DMG
- Generate Sparkle appcast
- Create GitHub Release with DMG + appcast
```

**update-homebrew.yml** (on release published):
```yaml
- Update Homebrew tap formula with new version + SHA256
- Commit and push to tap repository
```

---

## 5. Implementation Plan

### Phase 1: Foundation (Core Logic)

| # | Task | Files | Tests |
|---|------|-------|-------|
| 1 | Xcode project setup (SPM, SwiftUI lifecycle, folder structure) | Project config | — |
| 2 | QSO data model (all ADIF fields) | `QSO.swift`, `ADIFField.swift` | — |
| 3 | ADIF parser (text → QSO) | `ADIFParser.swift` | `ADIFParserTests.swift` |
| 4 | ADIF generator (QSO → text) | `ADIFGenerator.swift` | `ADIFGeneratorTests.swift` |
| 5 | XML contact parser (WSJT-X XML → QSO) | `XMLContactParser.swift` | `XMLContactParserTests.swift` |
| 6 | QSO normalizer (power, band, mode) | `QSONormalizer.swift` | `QSONormalizerTests.swift` |
| 7 | Band map utility | `BandMap.swift` | `BandMapTests.swift` |

### Phase 2: Networking

| # | Task | Files | Tests |
|---|------|-------|-------|
| 8 | Text UDP listener (Network.framework) | `TextUDPListener.swift` | — |
| 9 | QDataStream binary reader | `QDataStreamReader.swift` | `QDataStreamReaderTests.swift` |
| 10 | Binary message parser (all types) | `WSJTXMessage.swift`, `BinaryUDPListener.swift` | Included in QDataStream tests |
| 11 | UDP service (orchestrates both listeners) | `UDPService.swift` | — |
| 12 | Wavelog API client | `WavelogAPIClient.swift` | `WavelogAPIClientTests.swift` |
| 13 | Keychain helper | `KeychainHelper.swift` | — |
| 14 | Notification service | `NotificationService.swift` | — |

### Phase 3: UI

| # | Task | Files |
|---|------|-------|
| 15 | App shell (MenuBarExtra, AppState, lifecycle) | `WaveLogMoatApp.swift`, `AppDelegate.swift`, `AppState.swift` |
| 16 | Menu bar view (status, recent QSOs) | `MenuBarView.swift`, `ConnectionStatusView.swift`, `QSOLogView.swift` |
| 17 | Settings window — Wavelog tab | `SettingsView.swift`, `WavelogSettingsTab.swift` |
| 18 | Settings window — WSJT-X tab | `WSJTXSettingsTab.swift` |
| 19 | Settings window — General tab | `GeneralSettingsTab.swift` |
| 20 | Settings window — About tab | `AboutTab.swift` |
| 21 | Launch at login service | `LaunchAtLoginService.swift` |
| 22 | First-launch onboarding flow | (Optional, can be deferred) |

### Phase 4: Polish & Distribution

| # | Task | Files |
|---|------|-------|
| 23 | Sparkle integration | SPM dependency, `AppDelegate.swift` |
| 24 | App icon (placeholder/initial) | `Assets.xcassets` |
| 25 | README.md | `README.md` |
| 26 | CONTRIBUTING.md | `CONTRIBUTING.md` |
| 27 | LICENSE (MIT) | `LICENSE` |
| 28 | CHANGELOG.md | `CHANGELOG.md` |
| 29 | SwiftLint configuration | `.swiftlint.yml` |
| 30 | GitHub Actions — build + test | `.github/workflows/build.yml` |
| 31 | GitHub Actions — release pipeline | `.github/workflows/release.yml` |
| 32 | Homebrew tap setup | `Homebrew/wavelogmoat.rb` |
| 33 | Makefile (convenience commands) | `Makefile` |

---

## 6. Reference Implementations

### WaveLogStoat (Go CLI)
- **Repository**: https://github.com/int2001/WaveLogStoat
- **Relevance**: Direct reference for UDP→Wavelog data flow, ADIF parsing, normalization
- **Key files**: `main.go` (UDP server), `parser.go` (ADIF/XML parsing), `normalizer.go` (power/band), `wavelog.go` (API client)
- **Architecture**: `UDP Listener → Format Detection → Parse → Normalize → Generate ADIF → POST /api/qso`

### WaveLogGate (Electron)
- **Repository**: https://github.com/wavelog/WaveLogGate
- **Relevance**: Official companion app, defines the expected UX and API usage patterns
- **Key files**: `main.js` (UDP listener, API client, notifications), `renderer.js` (UI), `index.html`
- **Notable**: Uses `tcadif` npm library for ADIF parsing, Electron Forge for packaging
- **License**: MIT

### WSJT-X Protocol Spec
- **Source**: `Network/NetworkMessage.hpp` in WSJT-X source
- **Mirror**: https://github.com/saitohirga/WSJT-X/blob/master/Network/NetworkMessage.hpp
- **Relevance**: Complete binary protocol documentation including all message types and QDataStream encoding

### Wavelog API Documentation
- **URL**: https://docs.wavelog.org/developer/api/
- **Relevance**: Official API spec for all endpoints

### Exemplary macOS Menu Bar Apps (architecture reference)
- **Karabiner-Elements**: https://github.com/pqrs-org/Karabiner-Elements — MenuBarExtra + Settings
- **AeroSpace**: https://github.com/nikitabobko/AeroSpace — MenuBarExtra pattern
- **Loop**: https://github.com/MrKai77/Loop — MenuBarExtra + Sparkle auto-updates
- **Easydict**: https://github.com/tisfeng/Easydict — MenuBarExtra + comprehensive SwiftUI app
- **Tuist**: https://github.com/tuist/tuist — FluidMenuBarExtra + Sparkle

---

## 7. Design Decisions Log

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
