import SwiftUI

public struct WavelogSettingsTab: View {
    @Bindable var appState: AppState
    @State private var isTestingConnection = false
    @State private var testResult: Bool?
    @State private var testErrorMessage: String?
    @State private var isFetchingProfiles = false
    @State private var stationProfilesErrorMessage: String?
    @State private var showAPIKey = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        Form {
            Section("Server") {
                TextField("URL", text: $appState.config.wavelogURL, prompt: Text("log.example.com/index.php"))
                    .textContentType(.URL)
                    .autocorrectionDisabled()

                HStack {
                    Group {
                        if showAPIKey {
                            TextField("API Key", text: $appState.apiKey)
                        } else {
                            SecureField("API Key", text: $appState.apiKey)
                        }
                    }
                    .textContentType(.none)
                    .autocorrectionDisabled()

                    Button {
                        showAPIKey.toggle()
                    } label: {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(showAPIKey ? "Hide API key" : "Show API key")
                }
            }

            Section("Station Profile") {
                Picker("Station", selection: $appState.config.stationProfileID) {
                    Text("Select Station").tag("")
                    ForEach(appState.stationProfiles) { profile in
                        Text("\(profile.stationProfileName) (\(profile.stationCallsign))")
                            .tag(profile.stationId)
                    }
                }

                HStack {
                    Button {
                        Task {
                            isFetchingProfiles = true
                            stationProfilesErrorMessage = nil
                            await appState.fetchStationProfiles()
                            isFetchingProfiles = false
                            if appState.wavelogConnectionStatus == .error {
                                stationProfilesErrorMessage = appState.lastError ?? "Failed to fetch station profiles"
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if isFetchingProfiles {
                                ProgressView().controlSize(.small)
                            }
                            Text("Refresh Stations")
                        }
                    }
                    .disabled(appState.apiKey.isEmpty || appState.config.wavelogURL.isEmpty || isFetchingProfiles)

                    Spacer()
                }

                if let stationProfilesErrorMessage {
                    Label(stationProfilesErrorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }

            Section("Connection Test") {
                HStack {
                    Button("Test Connection") {
                        Task {
                            isTestingConnection = true
                            testErrorMessage = nil
                            testResult = await appState.testWavelogConnection()
                            isTestingConnection = false
                            if testResult == false {
                                testErrorMessage = appState.lastError ?? "Connection test failed"
                            }
                        }
                    }
                    .disabled(appState.apiKey.isEmpty || appState.config.wavelogURL.isEmpty || appState.config.stationProfileID.isEmpty || isTestingConnection)

                    if isTestingConnection {
                        ProgressView().controlSize(.small)
                    } else if let result = testResult {
                        Label(
                            result ? "Connected" : "Failed",
                            systemImage: result ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundStyle(result ? .green : .red)
                    }

                    Spacer()
                }

                if testResult == false, let testErrorMessage {
                    Label(testErrorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }

            Section("Security") {
                Toggle("Allow self-signed certificates", isOn: $appState.config.allowSelfSignedCerts)

                Text("Enable this if your Wavelog instance uses a self-signed TLS certificate.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            if !appState.apiKey.isEmpty && !appState.config.wavelogURL.isEmpty && appState.stationProfiles.isEmpty {
                Task {
                    stationProfilesErrorMessage = nil
                    await appState.fetchStationProfiles()
                    if appState.wavelogConnectionStatus == .error {
                        stationProfilesErrorMessage = appState.lastError ?? "Failed to fetch station profiles"
                    }
                }
            }
        }
    }
}
