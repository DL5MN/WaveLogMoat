import Foundation

public struct WavelogConfig: Codable, Sendable, Equatable {
    public var wavelogURL: String = ""
    public var stationProfileID: String = ""

    public var textUDPPort: UInt16 = 2333
    public var enableTextUDP: Bool = true

    public var binaryUDPPort: UInt16 = 2237
    public var enableBinaryUDP: Bool = false

    public var listenAddress: String = "127.0.0.1"

    public var showInDock: Bool = false
    public var showInMenuBar: Bool = true
    public var launchAtLogin: Bool = false
    public var showNotifications: Bool = true
    public var allowSelfSignedCerts: Bool = true
    public var httpTimeout: Int = 5000

    public var showFrequencyInMenuBar: Bool = false

    public init() {}
}
