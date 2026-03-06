import Foundation

public struct WSJTXStatus: Sendable, Equatable {
    public var dialFrequencyHz: UInt64 = 0
    public var mode: String = ""
    public var dxCall: String = ""
    public var report: String = ""
    public var txMode: String = ""
    public var txEnabled: Bool = false
    public var transmitting: Bool = false
    public var decoding: Bool = false
    public var rxDF: UInt32 = 0
    public var txDF: UInt32 = 0
    public var deCall: String = ""
    public var deGrid: String = ""
    public var dxGrid: String = ""
    public var txWatchdog: Bool = false
    public var subMode: String = ""
    public var fastMode: Bool = false
    public var specialOperationMode: UInt8 = 0
    public var frequencyTolerance: UInt32 = 0
    public var trPeriod: UInt32 = 0
    public var configurationName: String = ""
    public var txMessage: String = ""

    public init() {}

    public var dialFrequencyMHz: Double {
        Double(dialFrequencyHz) / 1_000_000.0
    }

    public var formattedFrequency: String {
        String(format: "%.3f", dialFrequencyMHz)
    }
}
