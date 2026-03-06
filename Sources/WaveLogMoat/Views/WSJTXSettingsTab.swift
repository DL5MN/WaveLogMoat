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

            Section("Protocol") {
                Picker("Protocol", selection: $appState.config.udpProtocol) {
                    Text("Text (ADIF/XML)").tag(UDPProtocol.text)
                    Text("Binary (QDataStream)").tag(UDPProtocol.binary)
                }
                .pickerStyle(.segmented)

                switch appState.config.udpProtocol {
                case .text:
                    TextField("Port", value: $appState.config.textUDPPort, format: Self.portFormat)
                        .textContentType(.none)

                    Text("Listens on the WSJT-X Secondary UDP Server for logged QSOs as ADIF text. Simple and reliable — works alongside JTAlert, GridTracker, and other tools without conflict.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                case .binary:
                    TextField("Port", value: $appState.config.binaryUDPPort, format: Self.portFormat)
                        .textContentType(.none)

                    Text("Listens on the WSJT-X primary UDP port for logged QSOs and real-time status updates including frequency, mode, and DX call. Only one application can use this port — do not use if JTAlert or GridTracker need it.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Label("Only one application can listen on the primary UDP port. This will conflict with JTAlert, GridTracker, or any other tool using this port.", systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.yellow)
                }

                LabeledContent("Status") {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isListening ? .green : .gray)
                            .frame(width: 8, height: 8)
                        Text(isListening ? "Listening" : "Not listening")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var isListening: Bool {
        switch appState.config.udpProtocol {
        case .text: appState.udpService.isTextListening
        case .binary: appState.udpService.isBinaryListening
        }
    }
}
