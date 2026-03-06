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
            Section {
                TextField("URL", text: $appState.config.wavelogURL)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    if showAPIKey {
                        TextField("API Key", text: $appState.apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("API Key", text: $appState.apiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(
                        action: { showAPIKey.toggle() },
                        label: { Image(systemName: showAPIKey ? "eye.slash" : "eye") }
                    )
                    .buttonStyle(.plain)
                }

                HStack {
                    Picker("Station", selection: $appState.config.stationProfileID) {
                        Text("Select Station").tag("")
                        ForEach(appState.stationProfiles) { profile in
                            Text("\(profile.stationProfileName) (\(profile.stationCallsign))")
                                .tag(profile.stationId)
                        }
                    }

                    Button(
                        action: {
                            Task {
                                isFetchingProfiles = true
                                stationProfilesErrorMessage = nil
                                await appState.fetchStationProfiles()
                                isFetchingProfiles = false
                                if appState.wavelogConnectionStatus == .error {
                                    stationProfilesErrorMessage = appState.lastError ?? "Failed to fetch station profiles"
                                }
                            }
                        },
                        label: {
                            if isFetchingProfiles {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    )
                    .buttonStyle(.plain)
                    .disabled(appState.apiKey.isEmpty || appState.config.wavelogURL.isEmpty)
                }

                if let stationProfilesErrorMessage {
                    Text(stationProfilesErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
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
                    .disabled(appState.apiKey.isEmpty || appState.config.wavelogURL.isEmpty || isTestingConnection)

                    if isTestingConnection {
                        ProgressView().controlSize(.small)
                            .padding(.leading, 8)
                    } else if let result = testResult {
                        Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result ? .green : .red)
                            .padding(.leading, 8)
                        Text(result ? "Connected" : "Failed")
                            .foregroundStyle(result ? .green : .red)
                    }
                }

                if testResult == false, let testErrorMessage {
                    Text(testErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Toggle("Allow self-signed certificates", isOn: $appState.config.allowSelfSignedCerts)
            }
        }
        .padding()
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
