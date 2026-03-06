import SwiftUI

public struct WSJTXSettingsTab: View {
    @Bindable var appState: AppState

    private static let portFormat = IntegerFormatStyle<UInt16>().grouping(.never)

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        Form {
            Section("Connection") {
                TextField("Listen Address", text: $appState.config.listenAddress)
                    .textContentType(.none)
                    .autocorrectionDisabled()

                Text("IP address to listen on. Use 127.0.0.1 for local connections or 0.0.0.0 to accept from other machines.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Text Protocol (ADIF/XML)") {
                Toggle("Enable Text Protocol", isOn: $appState.config.enableTextUDP)

                TextField("Port", value: $appState.config.textUDPPort, format: Self.portFormat)
                    .textContentType(.none)

                Text("Receives logged QSOs as ADIF text from WSJT-X. This is the standard method — enable this unless you have a specific reason not to.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                LabeledContent("Status") {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(appState.udpService.isTextListening ? .green : .gray)
                            .frame(width: 8, height: 8)
                        Text(appState.udpService.isTextListening ? "Listening" : "Disabled")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Binary Protocol (QDataStream)") {
                Toggle("Enable Binary Protocol", isOn: $appState.config.enableBinaryUDP)

                TextField("Port", value: $appState.config.binaryUDPPort, format: Self.portFormat)
                    .textContentType(.none)

                Text("Receives real-time status updates (frequency, mode, DX call) via WSJT-X's native binary protocol. Only one application can listen on this port at a time.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                LabeledContent("Status") {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(appState.udpService.isBinaryListening ? .green : .gray)
                            .frame(width: 8, height: 8)
                        Text(appState.udpService.isBinaryListening ? "Listening" : "Disabled")
                            .foregroundStyle(.secondary)
                    }
                }

                Label("May conflict with JTAlert or GridTracker if they use the same port.", systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.yellow)
            }
        }
        .formStyle(.grouped)
    }
}
