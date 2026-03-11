import WaveLogMoat
import XCTest

final class BandMapTests: XCTestCase {
  func testBandLookupForHFFrequencies() {
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 1.85), "160m")
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 3.75), "80m")
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 7.074), "40m")
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 14.074), "20m")
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 28.5), "10m")
  }

  func testBandLookupForVHFUHF() {
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 50.313), "6m")
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 144.174), "2m")
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 432.174), "70cm")
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 1296.1), "23cm")
  }

  func testBandLookupStringInput() {
    XCTAssertEqual(BandMap.band(forFrequencyString: "18.100"), "17m")
    XCTAssertEqual(BandMap.band(forFrequencyString: "24.915"), "12m")
    XCTAssertNil(BandMap.band(forFrequencyString: "not-a-number"))
  }

  func testBandRangeEdgesAreInclusive() {
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 14.000), "20m")
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 14.350), "20m")
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 420.000), "70cm")
    XCTAssertEqual(BandMap.band(forFrequencyMHz: 450.000), "70cm")
  }

  func testOutOfBandReturnsNil() {
    XCTAssertNil(BandMap.band(forFrequencyMHz: 0.1))
    XCTAssertNil(BandMap.band(forFrequencyMHz: 5.9))
    XCTAssertNil(BandMap.band(forFrequencyMHz: 148.1))
    XCTAssertNil(BandMap.band(forFrequencyMHz: 3000.0))
  }
}
