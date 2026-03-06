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
    @State private var appState = AppState()
    @State private var updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    init() {}

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState) {
                updaterController.checkForUpdates(nil)
            }
        } label: {
            MenuBarLabel(appState: appState)
        }
        .menuBarExtraStyle(.window)

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
               appState.wsjtxConnectionStatus == .connected {
                Text(appState.wsjtxStatus.formattedFrequency)
                    .monospacedDigit()
                if !appState.wsjtxStatus.mode.isEmpty {
                    Text(appState.wsjtxStatus.mode)
                }
            }
        }
    }
}
