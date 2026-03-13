public enum BandMap {
  public struct BandRange: Sendable, Equatable {
    public let name: String
    public let lower: Double
    public let upper: Double

    public init(name: String, lower: Double, upper: Double) {
      self.name = name
      self.lower = lower
      self.upper = upper
    }
  }

  public static let bands: [BandRange] = [
    BandRange(name: "2190m", lower: 0.1357, upper: 0.1378),
    BandRange(name: "630m", lower: 0.472, upper: 0.479),
    BandRange(name: "560m", lower: 0.501, upper: 0.504),
    BandRange(name: "160m", lower: 1.800, upper: 2.000),
    BandRange(name: "80m", lower: 3.500, upper: 4.000),
    BandRange(name: "60m", lower: 5.060, upper: 5.450),
    BandRange(name: "40m", lower: 7.000, upper: 7.300),
    BandRange(name: "30m", lower: 10.100, upper: 10.150),
    BandRange(name: "20m", lower: 14.000, upper: 14.350),
    BandRange(name: "17m", lower: 18.068, upper: 18.168),
    BandRange(name: "15m", lower: 21.000, upper: 21.450),
    BandRange(name: "12m", lower: 24.890, upper: 24.990),
    BandRange(name: "10m", lower: 28.000, upper: 29.700),
    BandRange(name: "8m", lower: 40.000, upper: 45.000),
    BandRange(name: "6m", lower: 50.000, upper: 54.000),
    BandRange(name: "4m", lower: 70.000, upper: 71.000),
    BandRange(name: "2m", lower: 144.000, upper: 148.000),
    BandRange(name: "1.25m", lower: 222.000, upper: 225.000),
    BandRange(name: "70cm", lower: 420.000, upper: 450.000),
    BandRange(name: "33cm", lower: 902.000, upper: 928.000),
    BandRange(name: "23cm", lower: 1240.000, upper: 1300.000),
    BandRange(name: "13cm", lower: 2300.000, upper: 2450.000),
  ]

  public static func band(forFrequencyMHz freq: Double) -> String? {
    bands.first { freq >= $0.lower && freq <= $0.upper }?.name
  }

  public static func band(forFrequencyString freqStr: String) -> String? {
    guard let freq = Double(freqStr) else { return nil }
    return band(forFrequencyMHz: freq)
  }
}
