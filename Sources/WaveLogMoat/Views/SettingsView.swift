import SwiftUI

public struct SettingsView: View {
    @Bindable var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        TabView {
            WavelogSettingsTab(appState: appState)
                .tabItem { Label("Wavelog", systemImage: "globe") }
            WSJTXSettingsTab(appState: appState)
                .tabItem { Label("WSJT-X", systemImage: "antenna.radiowaves.left.and.right") }
            GeneralSettingsTab(appState: appState)
                .tabItem { Label("General", systemImage: "gear") }
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 500, height: 400)
    }
}
