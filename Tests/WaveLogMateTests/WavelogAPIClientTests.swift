import Foundation
import Testing
import WaveLogMate

@Suite struct WavelogAPIClientTests {
  @Test func buildQSOPayload() throws {
    let adif = "<CALL:5>DJ7NT <MODE:3>FT8 <EOR>"
    let payload = WavelogAPIClient.buildQSOPayload(
      adifString: adif,
      apiKey: "API_KEY",
      stationProfileID: "42"
    )

    let json = try decodeJSON(payload)
    #expect(json["key"] as? String == "API_KEY")
    #expect(json["station_profile_id"] as? String == "42")
    #expect(json["type"] as? String == "adif")
    #expect(json["string"] as? String == adif)
  }

  @Test func buildVersionPayload() throws {
    let payload = WavelogAPIClient.buildVersionPayload(apiKey: "VERSION_KEY")
    let json = try decodeJSON(payload)

    #expect(json.count == 1)
    #expect(json["key"] as? String == "VERSION_KEY")
  }

  @Test func normalizeURLPrefixesHTTPS() {
    #expect(WavelogAPIClient.normalizeURL("log.example.com") == "https://log.example.com")
    #expect(WavelogAPIClient.normalizeURL("  log.example.com  ") == "https://log.example.com")
  }

  @Test func normalizeURLPreservesExistingScheme() {
    #expect(
      WavelogAPIClient.normalizeURL("https://log.example.com") == "https://log.example.com")
    #expect(
      WavelogAPIClient.normalizeURL("http://log.example.com") == "http://log.example.com")
    #expect(
      WavelogAPIClient.normalizeURL("HTTP://log.example.com") == "HTTP://log.example.com")
  }

  @Test func normalizeURLHandlesEmpty() {
    #expect(WavelogAPIClient.normalizeURL("") == "")
    #expect(WavelogAPIClient.normalizeURL("   ") == "")
  }

  private func decodeJSON(_ data: Data) throws -> [String: Any] {
    let object = try JSONSerialization.jsonObject(with: data)
    guard let dictionary = object as? [String: Any] else {
      Issue.record("Expected JSON dictionary")
      return [:]
    }
    return dictionary
  }
}
