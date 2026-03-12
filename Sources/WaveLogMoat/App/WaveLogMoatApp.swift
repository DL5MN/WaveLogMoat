import SwiftUI

#if canImport(Sparkle)
  import Sparkle
#endif

#if !canImport(Sparkle)
  public final class SPUStandardUpdaterController {
    public init(startingUpdater: Bool, updaterDelegate: Any?, userDriverDelegate: Any?) {}

    public func checkForUpdates(_ sender: Any?) {}
  }
#endif

#if !BUILDING_FOR_SWIFT_PACKAGE
  @main
#endif
struct WaveLogMoatApp: App {
  @State private var appState: AppState
  @State private var updaterController: SPUStandardUpdaterController
  @State private var isMenuBarInserted: Bool

  init() {
    let initialAppState = AppState()
    _appState = State(initialValue: initialAppState)
    _updaterController = State(
      initialValue: SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    )
    _isMenuBarInserted = State(initialValue: initialAppState.config.showInMenuBar)
  }

  var body: some Scene {
    MenuBarExtra(isInserted: $isMenuBarInserted) {
      MenuBarView(appState: appState) {
        updaterController.checkForUpdates(nil)
      }
    } label: {
      MenuBarLabel(appState: appState)
    }
    .menuBarExtraStyle(.window)
    .onChange(of: appState.config.showInMenuBar) { _, newValue in
      isMenuBarInserted = newValue
    }

    Settings {
      SettingsView(appState: appState)
    }
  }
}

struct MenuBarLabel: View {
  let appState: AppState

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "antenna.radiowaves.left.and.right")
      if appState.config.showFrequencyInMenuBar,
        appState.config.udpProtocol == .binary,
        appState.wsjtxConnectionStatus == .connected
      {
        Text(appState.wsjtxStatus.formattedFrequency)
          .monospacedDigit()
        if !appState.wsjtxStatus.mode.isEmpty {
          Text(appState.wsjtxStatus.mode)
        }
      }
    }
  }
}
