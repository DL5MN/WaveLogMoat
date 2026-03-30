public enum ConnectionStatus: String, Sendable {
  case connected
  case disconnected
  case connecting
  case listening
  case error

  public var label: String {
    switch self {
    case .connected: return "Connected"
    case .disconnected: return "Disconnected"
    case .connecting: return "Connecting"
    case .listening: return "Waiting for WSJT-X"
    case .error: return "Error"
    }
  }
}
