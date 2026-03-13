public struct StationProfile: Codable, Identifiable, Sendable, Hashable {
  public var id: String { stationId }
  public let stationId: String
  public let stationProfileName: String
  public let stationGridsquare: String
  public let stationCallsign: String
  public let stationActive: String?

  public init(
    stationId: String,
    stationProfileName: String,
    stationGridsquare: String,
    stationCallsign: String,
    stationActive: String?
  ) {
    self.stationId = stationId
    self.stationProfileName = stationProfileName
    self.stationGridsquare = stationGridsquare
    self.stationCallsign = stationCallsign
    self.stationActive = stationActive
  }

  public enum CodingKeys: String, CodingKey {
    case stationId = "station_id"
    case stationProfileName = "station_profile_name"
    case stationGridsquare = "station_gridsquare"
    case stationCallsign = "station_callsign"
    case stationActive = "station_active"
  }
}
