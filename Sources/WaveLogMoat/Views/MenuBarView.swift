import SwiftUI

public struct MenuBarView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openSettings) private var openSettings
    let checkForUpdates: () -> Void

    public init(appState: AppState, checkForUpdates: @escaping () -> Void) {
        self.appState = appState
        self.checkForUpdates = checkForUpdates
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                ConnectionStatusView(
                    label: "WSJT-X",
                    status: appState.wsjtxConnectionStatus,
                    detail: appState.wsjtxVersion.isEmpty ? nil : "v\(appState.wsjtxVersion)"
                )

                ConnectionStatusView(
                    label: "Wavelog",
                    status: appState.wavelogConnectionStatus,
                    detail: nil
                )
            }
            .padding()

            Divider()

            if appState.wsjtxConnectionStatus == .connected {
                HStack {
                    Text("\(appState.wsjtxStatus.formattedFrequency) MHz")
                        .monospacedDigit()
                    Text(appState.wsjtxStatus.mode)
                    if !appState.wsjtxStatus.dxCall.isEmpty {
                        Text("(DX: \(appState.wsjtxStatus.dxCall) \(appState.wsjtxStatus.dxGrid))")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()

                Divider()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Recent QSOs")
                    .font(.headline)

                QSOLogView(qsos: appState.recentQSOs)
            }
            .padding()

            Divider()

            HStack {
                Text("Total: \(appState.totalQSOsLogged) logged, \(appState.totalQSOsFailed) failed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Button {
                    dismiss()
                    openSettings()
                } label: {
                    Label("Settings...", systemImage: "gear")
                }
                .keyboardShortcut(",", modifiers: .command)
                .buttonStyle(.plain)

                Button {
                    dismiss()
                    checkForUpdates()
                } label: {
                    Label("Check for Updates...", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.plain)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit WaveLogMoat", systemImage: "power")
                }
                .keyboardShortcut("q", modifiers: .command)
                .buttonStyle(.plain)
            }
            .padding()
        }
        .frame(width: 350)
    }
}
