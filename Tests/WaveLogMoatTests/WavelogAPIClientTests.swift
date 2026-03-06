import Foundation
import XCTest
import WaveLogMoat

final class WavelogAPIClientTests: XCTestCase {
    func testBuildQSOPayload() throws {
        let adif = "<CALL:5>DJ7NT <MODE:3>FT8 <EOR>"
        let payload = WavelogAPIClient.buildQSOPayload(
            adifString: adif,
            apiKey: "API_KEY",
            stationProfileID: "42"
        )

        let json = try decodeJSON(payload)
        XCTAssertEqual(json["key"] as? String, "API_KEY")
        XCTAssertEqual(json["station_profile_id"] as? String, "42")
        XCTAssertEqual(json["type"] as? String, "adif")
        XCTAssertEqual(json["string"] as? String, adif)
    }

    func testBuildVersionPayload() throws {
        let payload = WavelogAPIClient.buildVersionPayload(apiKey: "VERSION_KEY")
        let json = try decodeJSON(payload)

        XCTAssertEqual(json.count, 1)
        XCTAssertEqual(json["key"] as? String, "VERSION_KEY")
    }

    private func decodeJSON(_ data: Data) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            XCTFail("Expected JSON dictionary")
            return [:]
        }
        return dictionary
    }
}
