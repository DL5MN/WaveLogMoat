public enum ConnectionStatus: String, Sendable {
  case connected
  case disconnected
  case connecting
  case listening
  case error

  public var color: String {
    switch self {
    case .connected: return "green"
    case .disconnected: return "gray"
    case .connecting, .listening: return "yellow"
    case .error: return "red"
    }
  }

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
