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
                    detail: appState.wavelogVersion.isEmpty ? nil : "v\(appState.wavelogVersion)"
                )
            }
            .padding()

            Divider()

            if appState.config.udpProtocol == .binary,
               appState.wsjtxConnectionStatus == .connected {
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
                Text(
                    "Total: \(appState.totalQSOsLogged) logged, \(appState.totalQSOsFailed) failed"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                Button {
                    dismiss()
                    openSettings()
                    NSApplication.shared.activate(ignoringOtherApps: true)
                } label: {
                    MenuRow(title: "Settings", systemImage: "gear", shortcut: "⌘,")
                }
                .buttonStyle(.accessoryBar)

                Button {
                    dismiss()
                    checkForUpdates()
                } label: {
                    MenuRow(
                        title: "Check for Updates", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.accessoryBar)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    MenuRow(title: "Quit WaveLogMoat", systemImage: "power", shortcut: "⌘Q")
                }
                .buttonStyle(.accessoryBar)
            }
            .padding(.vertical, 4)
        }
        .frame(width: 350)
    }
}

private struct MenuRow: View {
    let title: String
    let systemImage: String
    var shortcut: String?

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage).foregroundStyle(.primary)
            Spacer()
            if let shortcut {
                Text(shortcut)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
    }
}
