import Foundation

public enum UDPProtocol: String, Codable, Sendable, CaseIterable {
  case text
  case binary
}

public struct WavelogConfig: Codable, Sendable, Equatable {
  public var wavelogURL: String = ""
  public var stationProfileID: String = ""

  public var udpProtocol: UDPProtocol = .text
  public var textUDPPort: UInt16 = 2333
  public var binaryUDPPort: UInt16 = 2237

  public var listenAddress: String = "127.0.0.1"

  public var showInDock: Bool = false
  public var showInMenuBar: Bool = true
  public var launchAtLogin: Bool = false
  public var showNotifications: Bool = true
  public var allowSelfSignedCerts: Bool = true
  public var httpTimeout: Int = 5000

  public var showFrequencyInMenuBar: Bool = false

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    wavelogURL = try container.decodeIfPresent(String.self, forKey: .wavelogURL) ?? ""
    stationProfileID = try container.decodeIfPresent(String.self, forKey: .stationProfileID) ?? ""
    textUDPPort = try container.decodeIfPresent(UInt16.self, forKey: .textUDPPort) ?? 2333
    binaryUDPPort = try container.decodeIfPresent(UInt16.self, forKey: .binaryUDPPort) ?? 2237
    listenAddress =
      try container.decodeIfPresent(String.self, forKey: .listenAddress) ?? "127.0.0.1"
    showInDock = try container.decodeIfPresent(Bool.self, forKey: .showInDock) ?? false
    showInMenuBar = try container.decodeIfPresent(Bool.self, forKey: .showInMenuBar) ?? true
    launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
    showNotifications = try container.decodeIfPresent(Bool.self, forKey: .showNotifications) ?? true
    allowSelfSignedCerts =
      try container.decodeIfPresent(Bool.self, forKey: .allowSelfSignedCerts) ?? true
    httpTimeout = try container.decodeIfPresent(Int.self, forKey: .httpTimeout) ?? 5000
    showFrequencyInMenuBar =
      try container.decodeIfPresent(Bool.self, forKey: .showFrequencyInMenuBar) ?? false

    if let protocol_ = try container.decodeIfPresent(UDPProtocol.self, forKey: .udpProtocol) {
      udpProtocol = protocol_
    } else {
      let enableBinaryUDP =
        try container.decodeIfPresent(Bool.self, forKey: .enableBinaryUDP) ?? false
      udpProtocol = enableBinaryUDP ? .binary : .text
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(wavelogURL, forKey: .wavelogURL)
    try container.encode(stationProfileID, forKey: .stationProfileID)
    try container.encode(udpProtocol, forKey: .udpProtocol)
    try container.encode(textUDPPort, forKey: .textUDPPort)
    try container.encode(binaryUDPPort, forKey: .binaryUDPPort)
    try container.encode(listenAddress, forKey: .listenAddress)
    try container.encode(showInDock, forKey: .showInDock)
    try container.encode(showInMenuBar, forKey: .showInMenuBar)
    try container.encode(launchAtLogin, forKey: .launchAtLogin)
    try container.encode(showNotifications, forKey: .showNotifications)
    try container.encode(allowSelfSignedCerts, forKey: .allowSelfSignedCerts)
    try container.encode(httpTimeout, forKey: .httpTimeout)
    try container.encode(showFrequencyInMenuBar, forKey: .showFrequencyInMenuBar)
  }

  private enum CodingKeys: String, CodingKey {
    case wavelogURL, stationProfileID
    case udpProtocol, textUDPPort, binaryUDPPort
    case listenAddress
    case showInDock, showInMenuBar, launchAtLogin, showNotifications
    case allowSelfSignedCerts, httpTimeout, showFrequencyInMenuBar
    case enableBinaryUDP
  }
}
