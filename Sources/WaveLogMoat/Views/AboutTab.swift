import SwiftUI

public struct AboutTab: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(.blue)
            
            Text("WaveLogMoat")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 0.1.0")
                .foregroundStyle(.secondary)
            
            Text("A macOS menu bar app for logging QSOs from WSJT-X to Wavelog.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                Link("GitHub: dl5mn/WaveLogMoat", destination: URL(string: "https://github.com/dl5mn/WaveLogMoat")!)
                Link("Wavelog: wavelog.org", destination: URL(string: "https://wavelog.org")!)
                Link("WSJT-X: wsjt.sourceforge.io", destination: URL(string: "https://wsjt.sourceforge.io")!)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
