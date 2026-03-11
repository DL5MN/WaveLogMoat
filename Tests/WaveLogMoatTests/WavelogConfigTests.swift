import Foundation
import Testing
import WaveLogMoat

@Suite struct WavelogConfigTests {

  @Test func decodeLegacyFormatWithBinaryEnabled() throws {
    let json = """
      {"wavelogURL":"https://log.example.com","enableBinaryUDP":true,"textUDPPort":2333,"binaryUDPPort":2237}
      """
    let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))
    #expect(config.udpProtocol == .binary)
  }

  @Test func decodeLegacyFormatWithBinaryDisabled() throws {
    let json = """
      {"wavelogURL":"https://log.example.com","enableBinaryUDP":false,"textUDPPort":2333}
      """
    let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))
    #expect(config.udpProtocol == .text)
  }

  @Test func decodeLegacyFormatWithoutBinaryField() throws {
    let json = """
      {"wavelogURL":"https://log.example.com","textUDPPort":2333}
      """
    let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))
    #expect(config.udpProtocol == .text)
  }

  @Test func decodeNewFormatUsesUDPProtocolDirectly() throws {
    let json = """
      {"wavelogURL":"https://log.example.com","udpProtocol":"binary","textUDPPort":2333}
      """
    let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))
    #expect(config.udpProtocol == .binary)
  }

  @Test func newFormatTakesPrecedenceOverLegacy() throws {
    let json = """
      {"wavelogURL":"https://log.example.com","udpProtocol":"text","enableBinaryUDP":true}
      """
    let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))
    #expect(config.udpProtocol == .text)
  }

  @Test func encodeDoesNotIncludeLegacyBinaryKey() throws {
    var config = WavelogConfig()
    config.udpProtocol = .binary
    let data = try JSONEncoder().encode(config)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(json?["enableBinaryUDP"] == nil)
    #expect(json?["udpProtocol"] as? String == "binary")
  }

  @Test func roundTripPreservesAllFields() throws {
    var config = WavelogConfig()
    config.wavelogURL = "https://log.example.com"
    config.stationProfileID = "42"
    config.udpProtocol = .binary
    config.textUDPPort = 3000
    config.binaryUDPPort = 4000
    config.listenAddress = "0.0.0.0"
    config.showInDock = true
    config.showInMenuBar = false
    config.launchAtLogin = true
    config.showNotifications = false
    config.allowSelfSignedCerts = false
    config.httpTimeout = 10000
    config.showFrequencyInMenuBar = true

    let data = try JSONEncoder().encode(config)
    let decoded = try JSONDecoder().decode(WavelogConfig.self, from: data)

    #expect(config == decoded)
  }

  @Test func defaultsAreAppliedForMissingKeys() throws {
    let json = "{}"
    let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))

    #expect(config.wavelogURL == "")
    #expect(config.stationProfileID == "")
    #expect(config.udpProtocol == .text)
    #expect(config.textUDPPort == 2333)
    #expect(config.binaryUDPPort == 2237)
    #expect(config.listenAddress == "127.0.0.1")
    #expect(config.showInDock == false)
    #expect(config.showInMenuBar == true)
    #expect(config.launchAtLogin == false)
    #expect(config.showNotifications == true)
    #expect(config.allowSelfSignedCerts == true)
    #expect(config.httpTimeout == 5000)
    #expect(config.showFrequencyInMenuBar == false)
  }
}
