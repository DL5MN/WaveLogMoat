import Testing
import WaveLogMoat

@Suite struct BandMapTests {
  @Test func bandLookupForHFFrequencies() {
    #expect(BandMap.band(forFrequencyMHz: 1.85) == "160m")
    #expect(BandMap.band(forFrequencyMHz: 3.75) == "80m")
    #expect(BandMap.band(forFrequencyMHz: 7.074) == "40m")
    #expect(BandMap.band(forFrequencyMHz: 14.074) == "20m")
    #expect(BandMap.band(forFrequencyMHz: 28.5) == "10m")
  }

  @Test func bandLookupForVHFUHF() {
    #expect(BandMap.band(forFrequencyMHz: 50.313) == "6m")
    #expect(BandMap.band(forFrequencyMHz: 144.174) == "2m")
    #expect(BandMap.band(forFrequencyMHz: 432.174) == "70cm")
    #expect(BandMap.band(forFrequencyMHz: 1296.1) == "23cm")
  }

  @Test func bandLookupStringInput() {
    #expect(BandMap.band(forFrequencyString: "18.100") == "17m")
    #expect(BandMap.band(forFrequencyString: "24.915") == "12m")
    #expect(BandMap.band(forFrequencyString: "not-a-number") == nil)
  }

  @Test func bandRangeEdgesAreInclusive() {
    #expect(BandMap.band(forFrequencyMHz: 14.000) == "20m")
    #expect(BandMap.band(forFrequencyMHz: 14.350) == "20m")
    #expect(BandMap.band(forFrequencyMHz: 420.000) == "70cm")
    #expect(BandMap.band(forFrequencyMHz: 450.000) == "70cm")
  }

  @Test func outOfBandReturnsNil() {
    #expect(BandMap.band(forFrequencyMHz: 0.1) == nil)
    #expect(BandMap.band(forFrequencyMHz: 5.9) == nil)
    #expect(BandMap.band(forFrequencyMHz: 148.1) == nil)
    #expect(BandMap.band(forFrequencyMHz: 3000.0) == nil)
  }
}
