# WaveLogMoat

[![Build](https://github.com/dl5mn/WaveLogMoat/actions/workflows/build.yml/badge.svg)](https://github.com/dl5mn/WaveLogMoat/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-14%2B-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)

> Native macOS menu bar application for automatic QSO logging from WSJT-X to [Wavelog](https://www.wavelog.org).

WaveLogMoat listens for QSO data from WSJT-X and automatically forwards it to your Wavelog instance in real-time. It supports both the text-based ADIF/XML protocol (Secondary UDP Server) and the binary QDataStream protocol for richer status information.

## Screenshots

![WaveLogMoat menu bar overview](docs/screenshots/menu-bar-overview.png)
![WaveLogMoat settings window](docs/screenshots/settings-window.png)

_Screenshots coming soon._

## Features

- **Automatic QSO Logging** - QSOs from WSJT-X are logged to Wavelog in real-time
- **Dual Protocol Support** - Text ADIF/XML (port 2333) and binary QDataStream (port 2237)
- **Menu Bar App** - Lives in your menu bar with live status display
- **Real-time Status** - Shows current frequency, mode, and DX call from WSJT-X
- **Connection Monitoring** - Heartbeat-based WSJT-X connection tracking
- **macOS Notifications** - Get notified when QSOs are logged (or fail)
- **Secure** - API key stored in macOS Keychain
- **Self-Signed Cert Support** - Works with self-hosted Wavelog instances
- **Auto-Updates** - Built-in update checking via Sparkle
- **Launch at Login** - Optional automatic startup
- **Native macOS** - Built with SwiftUI, feels right at home on macOS

## Requirements

- macOS 14 (Sonoma) or later
- [WSJT-X](https://wsjt-x.sourceforge.io/) or [WSJT-X Improved](https://wsjt-x-improved.sourceforge.io/)
- A [Wavelog](https://www.wavelog.org) instance with API access

## Installation

### Download

Download the latest release from the [Releases page](https://github.com/dl5mn/WaveLogMoat/releases).

### Homebrew (coming soon)

```bash
brew tap dl5mn/wavelogmoat
brew install --cask wavelogmoat
```

### macOS Security Note

If you see "WaveLogMoat can't be opened because Apple cannot check it for malicious software", run:

```bash
xattr -d com.apple.quarantine /Applications/WaveLogMoat.app
```

(Code signing and notarization are planned for a future release.)

## Setup

### 1. Configure WSJT-X

In WSJT-X, go to **Settings -> Reporting** and configure the **Secondary UDP Server**:

- **Address**: `127.0.0.1`
- **Port**: `2333`

> **Important**: Use the *Secondary* UDP Server, NOT the primary one.

### 2. Configure WaveLogMoat

1. Open WaveLogMoat from the menu bar (antenna icon)
2. Click **Settings**
3. **Wavelog tab**:
   - Enter your Wavelog URL (e.g., `https://log.example.com/index.php`)
   - Enter your API Key (from Wavelog -> User Menu -> API Keys, must be Read+Write)
   - Select your Station Profile from the dropdown
   - Click **Test Connection** to verify
4. **WSJT-X tab**:
   - Text UDP is enabled by default on port 2333
   - Optionally enable Binary UDP on port 2237 for live frequency/status display

### 3. Start Logging

Once configured, WaveLogMoat automatically listens for QSOs. When you log a QSO in WSJT-X, it appears in the menu bar dropdown and is forwarded to Wavelog.

## Configuration Options

| Setting | Default | Description |
|---------|---------|-------------|
| Wavelog URL | - | Your Wavelog instance URL including `/index.php` |
| API Key | - | Read+Write API key from Wavelog |
| Station Profile | - | Selected from your Wavelog station locations |
| Text UDP Port | 2333 | WSJT-X Secondary UDP Server port |
| Binary UDP Port | 2237 | WSJT-X Primary UDP Server port (optional) |
| Listen Address | 127.0.0.1 | Network interface to listen on |
| Allow Self-Signed Certs | On | For self-hosted Wavelog with self-signed TLS |
| Show in Menu Bar | On | Display icon in menu bar |
| Show in Dock | Off | Display icon in dock |
| Launch at Login | Off | Start automatically at login |
| Show Notifications | On | macOS notifications for QSO events |

## Binary Protocol (Optional)

Enabling the binary protocol (port 2237) provides:

- Real-time frequency and mode display in the menu bar
- WSJT-X connection heartbeat monitoring
- DX call and grid display

> **Note**: This may conflict with JTAlert, GridTracker, or other tools that use the same port. It's disabled by default.

## Building from Source

### Prerequisites

- macOS 14+
- Xcode 15+ or Swift 5.9+

### Build

```bash
git clone https://github.com/dl5mn/WaveLogMoat.git
cd WaveLogMoat
make build
```

### Test

```bash
make test
```

### Clean

```bash
make clean
```

## Architecture

WaveLogMoat is built with:

- **SwiftUI** - Native macOS UI with MenuBarExtra
- **Network.framework** - UDP listeners
- **URLSession** - Wavelog REST API client
- **Sparkle** - Auto-updates
- **Keychain** - Secure API key storage
- **UserNotifications** - macOS notifications

See [PLAN.md](PLAN.md) for detailed architecture documentation.

## Related Projects

- [WaveLogGate](https://github.com/wavelog/WaveLogGate) - Official Electron-based bridge (CAT + QSO logging)
- [WaveLogStoat](https://github.com/int2001/WaveLogStoat) - Lightweight Go CLI for QSO transport
- [WaveLogGoat](https://github.com/johnsonm/WaveLogGoat) - Go-based CAT control
- [Wavelog](https://github.com/wavelog/wavelog) - The logging platform

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

Made with love for the amateur radio community by DL5MN.
73!
