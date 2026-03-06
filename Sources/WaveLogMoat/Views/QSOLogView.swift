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
    
    private func formatTime(_ timeString: String) -> String {
        guard timeString.count >= 4 else { return timeString }
        let index = timeString.index(timeString.startIndex, offsetBy: 2)
        return "\(timeString[..<index]):\(timeString[index...].prefix(2))"
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
    }
}
