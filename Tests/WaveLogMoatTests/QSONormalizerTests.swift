import WaveLogMoat
import XCTest

final class QSONormalizerTests: XCTestCase {
  func testNormalizePowerInWatts() {
    XCTAssertEqual(QSONormalizer.normalizePower("100w"), "100")
    XCTAssertEqual(QSONormalizer.normalizePower("25"), "25")
  }

  func testNormalizePowerInKilowatts() {
    XCTAssertEqual(QSONormalizer.normalizePower("1kw"), "1000")
    XCTAssertEqual(QSONormalizer.normalizePower("0.5kW"), "500")
  }

  func testNormalizePowerInMilliwatts() {
    XCTAssertEqual(QSONormalizer.normalizePower("500mW"), "0.500")
    XCTAssertEqual(QSONormalizer.normalizePower("1000mw"), "1")
  }

  func testNormalizeMode() {
    XCTAssertEqual(QSONormalizer.normalizeMode("USB"), "SSB")
    XCTAssertEqual(QSONormalizer.normalizeMode("LSB"), "SSB")
    XCTAssertEqual(QSONormalizer.normalizeMode("FT8"), "FT8")
  }

  func testNormalizeKIndexClamping() {
    XCTAssertEqual(QSONormalizer.normalizeKIndex("-1"), "0")
    XCTAssertEqual(QSONormalizer.normalizeKIndex("3.6"), "4")
    XCTAssertEqual(QSONormalizer.normalizeKIndex("11"), "9")
  }

  func testNormalizeKIndexEmptyReturnsEmpty() {
    XCTAssertEqual(QSONormalizer.normalizeKIndex(""), "")
    XCTAssertEqual(QSONormalizer.normalizeKIndex("  "), "  ")
  }

  func testNormalizeKIndexNonNumericReturnsEmpty() {
    XCTAssertEqual(QSONormalizer.normalizeKIndex("abc"), "")
    XCTAssertEqual(QSONormalizer.normalizeKIndex("N/A"), "")
  }

  func testNormalizeKIndexBoundaryValues() {
    XCTAssertEqual(QSONormalizer.normalizeKIndex("0"), "0")
    XCTAssertEqual(QSONormalizer.normalizeKIndex("9"), "9")
    XCTAssertEqual(QSONormalizer.normalizeKIndex("4.5"), "5")
  }

  func testNormalizeModeCaseInsensitive() {
    XCTAssertEqual(QSONormalizer.normalizeMode("usb"), "SSB")
    XCTAssertEqual(QSONormalizer.normalizeMode("lsb"), "SSB")
    XCTAssertEqual(QSONormalizer.normalizeMode("Usb"), "SSB")
  }

  func testNormalizePowerEmptyPassthrough() {
    XCTAssertEqual(QSONormalizer.normalizePower(""), "")
    XCTAssertEqual(QSONormalizer.normalizePower("  "), "  ")
  }

  func testNormalizePowerNonNumericPassthrough() {
    XCTAssertEqual(QSONormalizer.normalizePower("QRP"), "QRP")
  }

  func testNormalizePreservesBandWhenAlreadySet() {
    var qso = QSO()
    qso.call = "DL5MN"
    qso.frequency = "14.074000"
    qso.band = "20m"

    let normalized = QSONormalizer.normalize(qso)
    XCTAssertEqual(normalized.band, "20m")
  }

  func testNormalizeAddsBandFromFrequency() {
    var qso = QSO()
    qso.call = "DL5MN"
    qso.frequency = "14.074000"
    qso.mode = "USB"
    qso.kIndex = "8.2"

    let normalized = QSONormalizer.normalize(qso)

    XCTAssertEqual(normalized.band, "20m")
    XCTAssertEqual(normalized.mode, "SSB")
    XCTAssertEqual(normalized.kIndex, "8")
  }
}
