# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-08

### Added

- Add code signing and notarization to release workflow

### Documentation

- Replace JTAlert with JT-Bridge (macOS equivalent)
- Clarify that WaveLogMoat receives UDP data sent by WSJT-X
- Update changelog for v0.1.0

### Fixed

- Use manual codesign to avoid provisioning profile requirement
- Skip build workflow on version tags to avoid duplicate CI runs

### Bump

- Version 0.2.0

## [0.1.0] - 2026-03-07

### Added

- Show listening status instead of disconnected in text mode
- Add QSO error detail popover with raw response and HTML entity decoding
- Add hover highlighting to menu bar action buttons
- Polish settings UI with grouped forms, contextual hints, and improved error display
- Show Wavelog version in menu bar status
- Check connection status on startup and poll Wavelog periodically
- Add app icon
- Add Xcode project with app target and Sparkle integration
- Add settings window with all tabs
- Implement menu bar UI
- Add app entry point and state management
- Add notification and launch-at-login services
- Implement Wavelog API client
- Add UDP listeners for text and binary protocols
- Implement QDataStream binary protocol reader
- Add band map utility and logging
- Add XML contact parser and QSO normalizer
- Implement ADIF parser and generator
- Add Wavelog configuration and station profile models
- Add WSJT-X protocol models
- Add QSO data model and ADIF field definitions

### CI/CD

- Disable code signing on GitHub Actions runners
- Sign DMG with Sparkle and deploy appcast to GitHub Pages
- Integrate git-cliff into release pipeline and Makefile
- Add linting to release pipeline and auto-update homebrew tap
- Add swiftlint step to build pipeline
- Upgrade runners to macos-15 with Xcode 16.4
- Add build and release GitHub Actions workflows

### Changed

- Remove duplicated mode normalization and minor cleanups
- Avoid unnecessary listener restarts and API client recreation on config change
- Make text and binary UDP protocols mutually exclusive
- Remove single-QSO generate overload from ADIFGenerator
- Fix all swiftlint violations

### Documentation

- Remove index.php suffix from Wavelog URL examples
- Update README and PLAN to reflect exclusive protocol choice and live testing
- Format README tables and remove binary size comparison row
- Update PLAN.md with recent design decisions and progress
- Trim PLAN.md to open tasks and remove broken screenshot links
- Add git-cliff config and generate changelog
- Add motivation and feature comparison with related projects
- Add README, contributing guide, and changelog
- Add project plan and architecture

### Fixed

- Use step output to check secret availability in release workflow
- Remove expression wrapper from secrets checks in release workflow
- Harden release workflow for first-run and missing secrets
- Prevent sticky focus highlight on menu bar action buttons
- Make log messages visible by marking interpolated values as public
- Deduplicate QSOs when both UDP listeners are active
- Bring settings window to front when opened from menu bar
- Remove keyboard shortcuts from menu bar buttons to prevent auto-focus
- Remove force unwrap to satisfy SwiftLint
- Turn off notification toggle when OS has denied permission
- Re-check notification authorization when app regains focus
- Show guidance when macOS notifications are denied
- Apply dock visibility setting via NSApp activation policy
- Auto-prefix https:// for Wavelog URLs without a protocol scheme
- Deduplicate ADIF header generation, fix PROGRAMID length, update to ADIF 3.1.6
- Disable menu bar frequency display by default
- Add keychain-access-groups entitlement
- Cache API key in memory to avoid repeated Keychain prompts
- Dismiss menu bar panel when opening settings or checking updates
- Correct WSJT-X settings tab layout clipping
- Pass API key in URL path for station_info endpoint
- Generate properly sized app icon PNGs and exclude asset catalog from SPM

### Other

- Add make release target for one-command version bumping and tagging
- Normalize ellipsis usage in status text and templates
- Add 'make open' to launch latest debug build
- Add GitHub issue form templates for bugs and feature requests
- Add Sparkle EdDSA public key for update verification
- Gitignore xcuserdata inside project.xcworkspace
- Enable automatic code signing in Xcode project
- Initialize project structure

### Testing

- Add WavelogConfig migration and edge case coverage
- Add networking tests
- Add unit tests for parsers and models


