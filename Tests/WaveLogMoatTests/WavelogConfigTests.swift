import XCTest
import WaveLogMoat

final class WavelogConfigTests: XCTestCase {

    // MARK: - Migration from old format (enableBinaryUDP → udpProtocol)

    func testDecodeLegacyFormatWithBinaryEnabled() throws {
        let json = """
        {"wavelogURL":"https://log.example.com","enableBinaryUDP":true,"textUDPPort":2333,"binaryUDPPort":2237}
        """
        let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))
        XCTAssertEqual(config.udpProtocol, .binary)
    }

    func testDecodeLegacyFormatWithBinaryDisabled() throws {
        let json = """
        {"wavelogURL":"https://log.example.com","enableBinaryUDP":false,"textUDPPort":2333}
        """
        let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))
        XCTAssertEqual(config.udpProtocol, .text)
    }

    func testDecodeLegacyFormatWithoutBinaryField() throws {
        let json = """
        {"wavelogURL":"https://log.example.com","textUDPPort":2333}
        """
        let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))
        XCTAssertEqual(config.udpProtocol, .text)
    }

    func testDecodeNewFormatUsesUDPProtocolDirectly() throws {
        let json = """
        {"wavelogURL":"https://log.example.com","udpProtocol":"binary","textUDPPort":2333}
        """
        let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))
        XCTAssertEqual(config.udpProtocol, .binary)
    }

    func testNewFormatTakesPrecedenceOverLegacy() throws {
        let json = """
        {"wavelogURL":"https://log.example.com","udpProtocol":"text","enableBinaryUDP":true}
        """
        let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))
        XCTAssertEqual(config.udpProtocol, .text)
    }

    // MARK: - Encode omits legacy key

    func testEncodeDoesNotIncludeLegacyBinaryKey() throws {
        var config = WavelogConfig()
        config.udpProtocol = .binary
        let data = try JSONEncoder().encode(config)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNil(json?["enableBinaryUDP"], "Legacy key should not be encoded")
        XCTAssertEqual(json?["udpProtocol"] as? String, "binary")
    }

    // MARK: - Round-trip

    func testRoundTripPreservesAllFields() throws {
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

        XCTAssertEqual(config, decoded)
    }

    // MARK: - Defaults

    func testDefaultsAreAppliedForMissingKeys() throws {
        let json = "{}"
        let config = try JSONDecoder().decode(WavelogConfig.self, from: Data(json.utf8))

        XCTAssertEqual(config.wavelogURL, "")
        XCTAssertEqual(config.stationProfileID, "")
        XCTAssertEqual(config.udpProtocol, .text)
        XCTAssertEqual(config.textUDPPort, 2333)
        XCTAssertEqual(config.binaryUDPPort, 2237)
        XCTAssertEqual(config.listenAddress, "127.0.0.1")
        XCTAssertEqual(config.showInDock, false)
        XCTAssertEqual(config.showInMenuBar, true)
        XCTAssertEqual(config.launchAtLogin, false)
        XCTAssertEqual(config.showNotifications, true)
        XCTAssertEqual(config.allowSelfSignedCerts, true)
        XCTAssertEqual(config.httpTimeout, 5000)
        XCTAssertEqual(config.showFrequencyInMenuBar, false)
    }
}
