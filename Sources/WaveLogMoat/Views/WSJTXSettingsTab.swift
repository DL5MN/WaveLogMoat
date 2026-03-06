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

            Section(header: Text("Text Protocol (ADIF/XML)")) {
                HStack {
                    Toggle("Enabled", isOn: $appState.config.enableTextUDP)
                    Spacer()
                    Text("Port:")
                    TextField("Port", value: $appState.config.textUDPPort, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Status:")
                    Circle()
                        .fill(appState.udpService.isTextListening ? .green : .gray)
                        .frame(width: 8, height: 8)
                    Text(appState.udpService.isTextListening ? "Listening" : "Disabled")
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("Binary Protocol (QDataStream)")) {
                HStack {
                    Toggle("Enabled", isOn: $appState.config.enableBinaryUDP)
                    Spacer()
                    Text("Port:")
                    TextField("Port", value: $appState.config.binaryUDPPort, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("May conflict with JTAlert or GridTracker")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Status:")
                    Circle()
                        .fill(appState.udpService.isBinaryListening ? .green : .gray)
                        .frame(width: 8, height: 8)
                    Text(appState.udpService.isBinaryListening ? "Listening" : "Disabled")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
