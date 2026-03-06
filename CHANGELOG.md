# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

- Add linting to release pipeline and auto-update homebrew tap
- Add swiftlint step to build pipeline
- Upgrade runners to macos-15 with Xcode 16.4
- Add build and release GitHub Actions workflows

### Changed

- Fix all swiftlint violations

### Documentation

- Add motivation and feature comparison with related projects
- Add README, contributing guide, and changelog
- Add project plan and architecture

### Fixed

- Generate properly sized app icon PNGs and exclude asset catalog from SPM

### Other

- Initialize project structure

### Testing

- Add networking tests
- Add unit tests for parsers and models
