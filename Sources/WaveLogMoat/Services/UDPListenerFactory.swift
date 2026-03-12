import Network

enum UDPListenerFactory {
  static func makeListener(host: String, port: NWEndpoint.Port) throws -> NWListener {
    let parameters = NWParameters.udp
    parameters.allowLocalEndpointReuse = true

    let normalizedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
    if normalizedHost.isEmpty || normalizedHost == "0.0.0.0" || normalizedHost == "::" {
      return try NWListener(using: parameters, on: port)
    }

    parameters.requiredLocalEndpoint = .hostPort(host: NWEndpoint.Host(normalizedHost), port: port)
    return try NWListener(using: parameters)
  }
}
