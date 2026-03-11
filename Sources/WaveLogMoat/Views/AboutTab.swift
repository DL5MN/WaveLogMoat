import SwiftUI

public struct AboutTab: View {
  private var appVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
  }

  private var buildNumber: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
  }

  public init() {}

  public var body: some View {
    VStack(spacing: 16) {
      Spacer()

      Image(systemName: "antenna.radiowaves.left.and.right")
        .resizable()
        .scaledToFit()
        .frame(width: 64, height: 64)
        .foregroundStyle(.blue)

      Text("WaveLogMoat")
        .font(.title)
        .fontWeight(.bold)

      Text("Version \(appVersion) (\(buildNumber))")
        .foregroundStyle(.secondary)

      Text("A macOS menu bar app for logging QSOs\nfrom WSJT-X to Wavelog.")
        .multilineTextAlignment(.center)

      VStack(spacing: 6) {
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
      .padding(.top, 4)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
