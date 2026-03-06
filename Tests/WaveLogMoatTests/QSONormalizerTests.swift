import XCTest
import WaveLogMoat

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
