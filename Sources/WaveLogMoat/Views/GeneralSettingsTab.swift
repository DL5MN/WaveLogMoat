import SwiftUI

public struct GeneralSettingsTab: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle("Show in menu bar", isOn: $appState.config.showInMenuBar)
                Toggle("Show in dock", isOn: $appState.config.showInDock)
                Toggle("Show frequency in menu bar", isOn: $appState.config.showFrequencyInMenuBar)
            }

            Section(header: Text("Behavior")) {
                Toggle("Launch at login", isOn: $appState.config.launchAtLogin)
                    .onChange(of: appState.config.launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try LaunchAtLoginService.enable()
                            } else {
                                try LaunchAtLoginService.disable()
                            }
                        } catch {
                            appState.lastError = "Failed to toggle launch at login: \(error.localizedDescription)"
                            appState.showingError = true
                            appState.config.launchAtLogin = !newValue
                        }
                    }

                Toggle("Show notifications", isOn: $appState.config.showNotifications)
                    .onChange(of: appState.config.showNotifications) { _, newValue in
                        if newValue {
                            Task {
                                let granted = await NotificationService.requestAuthorization()
                                if !granted {
                                    appState.config.showNotifications = false
                                }
                            }
                        }
                    }
            }
        }
        .padding()
        .onAppear {
            appState.config.launchAtLogin = LaunchAtLoginService.isEnabled
        }
    }
}
