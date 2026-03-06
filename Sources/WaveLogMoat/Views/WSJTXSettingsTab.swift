import SwiftUI

public struct WSJTXSettingsTab: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        Form {
            Section {
                TextField("Listen Address", text: $appState.config.listenAddress)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Text Protocol (ADIF/XML)") {
                Toggle("Enabled", isOn: $appState.config.enableTextUDP)

                TextField("Port", value: $appState.config.textUDPPort, format: .number)
                    .textFieldStyle(.roundedBorder)

                LabeledContent("Status") {
                    HStack {
                        Circle()
                            .fill(appState.udpService.isTextListening ? .green : .gray)
                            .frame(width: 8, height: 8)
                        Text(appState.udpService.isTextListening ? "Listening" : "Disabled")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Binary Protocol (QDataStream)") {
                Toggle("Enabled", isOn: $appState.config.enableBinaryUDP)

                TextField("Port", value: $appState.config.binaryUDPPort, format: .number)
                    .textFieldStyle(.roundedBorder)

                LabeledContent("Status") {
                    HStack {
                        Circle()
                            .fill(appState.udpService.isBinaryListening ? .green : .gray)
                            .frame(width: 8, height: 8)
                        Text(appState.udpService.isBinaryListening ? "Listening" : "Disabled")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("May conflict with JTAlert or GridTracker")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
