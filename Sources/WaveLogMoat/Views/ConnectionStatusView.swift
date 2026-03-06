import SwiftUI

public struct ConnectionStatusView: View {
    let label: String
    let status: ConnectionStatus
    var detail: String?

    public init(label: String, status: ConnectionStatus, detail: String? = nil) {
        self.label = label
        self.status = status
        self.detail = detail
    }

    private var statusColor: Color {
        switch status {
        case .connected: return .green
        case .disconnected: return .gray
        case .connecting: return .yellow
        case .error: return .red
        }
    }

    public var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(label)
            Spacer()
            if let detail {
                Text(detail)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            Text(status.label)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}
