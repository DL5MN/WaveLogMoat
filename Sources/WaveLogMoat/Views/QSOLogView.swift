import SwiftUI

public struct QSOLogView: View {
    let qsos: [QSO]

    public init(qsos: [QSO]) {
        self.qsos = qsos
    }

    public var body: some View {
        if qsos.isEmpty {
            Text("No QSOs logged yet")
                .foregroundStyle(.secondary)
                .font(.caption)
        } else {
            ForEach(qsos.prefix(10)) { qso in
                QSORowView(qso: qso)
            }
        }
    }
}

struct QSORowView: View {
    let qso: QSO
    @State private var showErrorDetail = false

    private var hasFailed: Bool {
        qso.loggedSuccessfully == false
    }

    var body: some View {
        HStack {
            Text(formatTime(qso.timeOn))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            Text(qso.call)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)

            Spacer()

            Text(qso.band)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(qso.mode)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let success = qso.loggedSuccessfully {
                Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(success ? .green : .red)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if hasFailed {
                showErrorDetail.toggle()
            }
        }
        .popover(isPresented: $showErrorDetail, arrowEdge: .trailing) {
            QSOErrorDetailView(qso: qso)
        }
    }

    private func formatTime(_ timeString: String) -> String {
        guard timeString.count >= 4 else { return timeString }
        let index = timeString.index(timeString.startIndex, offsetBy: 2)
        return "\(timeString[..<index]):\(timeString[index...].prefix(2))"
    }
}

private struct QSOErrorDetailView: View {
    let qso: QSO
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("QSO Failed", systemImage: "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.red)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                GridRow {
                    Text("Call").foregroundStyle(.secondary)
                    Text(qso.call).fontWeight(.medium)
                }
                GridRow {
                    Text("Band").foregroundStyle(.secondary)
                    Text(qso.band)
                }
                GridRow {
                    Text("Mode").foregroundStyle(.secondary)
                    Text(qso.mode)
                }
                GridRow {
                    Text("Time").foregroundStyle(.secondary)
                    Text(formatDateTime(qso.qsoDate, qso.timeOn))
                }
                if let loggedAt = qso.loggedAt {
                    GridRow {
                        Text("Attempted").foregroundStyle(.secondary)
                        Text(loggedAt, style: .relative) + Text(" ago").foregroundStyle(.secondary)
                    }
                }
            }
            .font(.callout)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Error")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(qso.logError ?? "Unknown error")
                    .font(.callout)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            HStack {
                Spacer()
                if let rawBody = qso.logErrorRaw, !rawBody.isEmpty {
                    Button("Copy Raw JSON") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(rawBody, forType: .string)
                        dismiss()
                    }
                    .controlSize(.small)
                }
                Button("Copy Error") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(qso.logError ?? "Unknown error", forType: .string)
                    dismiss()
                }
                .controlSize(.small)
            }
        }
        .padding()
        .frame(width: 340)
    }

    private func formatDateTime(_ date: String, _ time: String) -> String {
        guard date.count == 8, time.count >= 4 else { return "\(date) \(time)" }
        let y = date.prefix(4)
        let m = date.dropFirst(4).prefix(2)
        let d = date.dropFirst(6).prefix(2)
        let h = time.prefix(2)
        let min = time.dropFirst(2).prefix(2)
        return "\(y)-\(m)-\(d) \(h):\(min) UTC"
    }

}
