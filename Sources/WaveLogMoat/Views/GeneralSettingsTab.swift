import SwiftUI
import UserNotifications

public struct GeneralSettingsTab: View {
  @Bindable var appState: AppState
  @State private var notificationsDenied = false
  @Environment(\.scenePhase) private var scenePhase

  public init(appState: AppState) {
    self.appState = appState
  }

  public var body: some View {
    Form {
      Section("Appearance") {
        Toggle("Show in menu bar", isOn: $appState.config.showInMenuBar)
          .disabled(appState.config.showInMenuBar && !appState.config.showInDock)

        Toggle("Show in dock", isOn: $appState.config.showInDock)
          .disabled(!appState.config.showInMenuBar && appState.config.showInDock)
        Toggle("Show frequency in menu bar", isOn: $appState.config.showFrequencyInMenuBar)

        if appState.config.showFrequencyInMenuBar && appState.config.udpProtocol != .binary {
          Label(
            "Frequency data requires the binary protocol. Switch to it in the WSJT-X tab.",
            systemImage: "exclamationmark.triangle.fill"
          )
          .font(.callout)
          .foregroundStyle(.yellow)
        }
      }

      Section("Behavior") {
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
                  notificationsDenied = true
                }
              }
            }
          }

        if notificationsDenied {
          VStack(alignment: .leading, spacing: 6) {
            Label(
              "Notifications are disabled in System Settings.",
              systemImage: "exclamationmark.triangle.fill"
            )
            .font(.callout)
            .foregroundStyle(.yellow)

            Button("Open Notification Settings") {
              if let url = URL(
                string: "x-apple.systempreferences:com.apple.preference.notifications")
              {
                NSWorkspace.shared.open(url)
              }
            }
            .font(.callout)
          }
        } else {
          Text("Get notified when a QSO is logged or fails to log.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
    }
    .formStyle(.grouped)
    .onAppear {
      appState.config.launchAtLogin = LaunchAtLoginService.isEnabled
      checkNotificationStatus()
    }
    .onChange(of: scenePhase) { _, newPhase in
      if newPhase == .active {
        checkNotificationStatus()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification))
    { _ in
      checkNotificationStatus()
    }
  }

  private func checkNotificationStatus() {
    Task { @MainActor in
      let settings = await UNUserNotificationCenter.current().notificationSettings()
      let denied = settings.authorizationStatus == .denied
      notificationsDenied = denied
      if denied {
        appState.config.showNotifications = false
      }
    }
  }
}
