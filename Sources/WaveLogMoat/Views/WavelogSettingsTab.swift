import SwiftUI

public struct WavelogSettingsTab: View {
    @Bindable var appState: AppState
    @State private var isTestingConnection = false
    @State private var testResult: Bool? = nil
    @State private var isFetchingProfiles = false
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
                    
                    Button(action: { showAPIKey.toggle() }) {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                    }
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
                    
                    Button(action: {
                        Task {
                            isFetchingProfiles = true
                            await appState.fetchStationProfiles()
                            isFetchingProfiles = false
                        }
                    }) {
                        if isFetchingProfiles {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.apiKey.isEmpty || appState.config.wavelogURL.isEmpty)
                }
            }
            
            Section {
                HStack {
                    Button("Test Connection") {
                        Task {
                            isTestingConnection = true
                            testResult = await appState.testWavelogConnection()
                            isTestingConnection = false
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
            }
            
            Section {
                Toggle("Allow self-signed certificates", isOn: $appState.config.allowSelfSignedCerts)
                
                HStack {
                    Text("Timeout:")
                    TextField("ms", value: $appState.config.httpTimeout, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                    Text("ms")
                }
            }
        }
        .padding()
        .onAppear {
            if !appState.apiKey.isEmpty && !appState.config.wavelogURL.isEmpty && appState.stationProfiles.isEmpty {
                Task {
                    await appState.fetchStationProfiles()
                }
            }
        }
    }
}
