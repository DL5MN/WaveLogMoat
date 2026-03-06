public enum ConnectionStatus: String, Sendable {
    case connected
    case disconnected
    case connecting
    case error

    public var color: String {
        switch self {
        case .connected: return "green"
        case .disconnected: return "gray"
        case .connecting: return "yellow"
        case .error: return "red"
        }
    }

    public var label: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .error: return "Error"
        }
    }
}
