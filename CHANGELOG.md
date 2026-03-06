# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure and implementation
- ADIF parser and generator
- XML contact parser for WSJT-X
- QDataStream binary protocol parser
- Text UDP listener (port 2333)
- Binary UDP listener (port 2237)
- Wavelog API client (QSO logging, station info, version check, connection test)
- QSO data normalization (power, band, mode)
- macOS menu bar UI with SwiftUI MenuBarExtra
- Settings window with Wavelog, WSJT-X, General, and About tabs
- Connection status indicators for WSJT-X and Wavelog
- Recent QSO log in menu bar dropdown
- macOS notification support
- Keychain storage for API key
- Launch at login support
- Self-signed certificate support for Wavelog
- Unit tests for core functionality (42 tests)
