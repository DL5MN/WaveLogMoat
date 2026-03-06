import Foundation

public struct QSO: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID

    public var call: String = ""
    public var mode: String = ""
    public var submode: String = ""
    public var frequency: String = ""
    public var frequencyRx: String = ""
    public var band: String = ""
    public var qsoDate: String = ""
    public var timeOn: String = ""
    public var qsoDateOff: String = ""
    public var timeOff: String = ""
    public var rstSent: String = ""
    public var rstReceived: String = ""
    public var txPower: String = ""

    public var stationCallsign: String = ""
    public var operatorCall: String = ""
    public var myCall: String = ""
    public var myGridsquare: String = ""
    public var gridsquare: String = ""

    public var name: String = ""
    public var qth: String = ""
    public var state: String = ""
    public var country: String = ""
    public var cqZone: String = ""
    public var ituZone: String = ""
    public var continent: String = ""
    public var iota: String = ""
    public var dxcc: String = ""

    public var comment: String = ""
    public var notes: String = ""
    public var qslMessage: String = ""

    public var stx: String = ""
    public var srx: String = ""
    public var stxString: String = ""
    public var srxString: String = ""
    public var contestId: String = ""

    public var propMode: String = ""
    public var satName: String = ""
    public var satMode: String = ""

    public var sotaRef: String = ""
    public var wwffRef: String = ""
    public var potaRef: String = ""
    public var darcDok: String = ""

    public var email: String = ""
    public var county: String = ""
    public var region: String = ""
    public var latitude: String = ""
    public var longitude: String = ""
    public var antAzimuth: String = ""
    public var antElevation: String = ""
    public var antPath: String = ""
    public var aIndex: String = ""
    public var kIndex: String = ""
    public var sfi: String = ""
    public var rxPower: String = ""
    public var prefix: String = ""

    public var loggedSuccessfully: Bool?
    public var logError: String?
    public var loggedAt: Date?

    public init(id: UUID = UUID()) {
        self.id = id
    }
}
