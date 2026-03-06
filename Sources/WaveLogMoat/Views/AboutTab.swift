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
                if let githubURL = URL(string: "https://github.com/dl5mn/WaveLogMoat") {
                    Link("GitHub: dl5mn/WaveLogMoat", destination: githubURL)
                }
                if let wavelogURL = URL(string: "https://wavelog.org") {
                    Link("Wavelog: wavelog.org", destination: wavelogURL)
                }
                if let wsjtxURL = URL(string: "https://wsjt.sourceforge.io") {
                    Link("WSJT-X: wsjt.sourceforge.io", destination: wsjtxURL)
                }
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
