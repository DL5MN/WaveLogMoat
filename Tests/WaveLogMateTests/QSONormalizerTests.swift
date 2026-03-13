import Testing
import WaveLogMate

@Suite struct QSONormalizerTests {
  @Test func normalizePowerInWatts() {
    #expect(QSONormalizer.normalizePower("100w") == "100")
    #expect(QSONormalizer.normalizePower("25") == "25")
  }

  @Test func normalizePowerInKilowatts() {
    #expect(QSONormalizer.normalizePower("1kw") == "1000")
    #expect(QSONormalizer.normalizePower("0.5kW") == "500")
  }

  @Test func normalizePowerInMilliwatts() {
    #expect(QSONormalizer.normalizePower("500mW") == "0.500")
    #expect(QSONormalizer.normalizePower("1000mw") == "1")
  }

  @Test func normalizeMode() {
    #expect(QSONormalizer.normalizeMode("USB") == "SSB")
    #expect(QSONormalizer.normalizeMode("LSB") == "SSB")
    #expect(QSONormalizer.normalizeMode("FT8") == "FT8")
  }

  @Test func normalizeKIndexClamping() {
    #expect(QSONormalizer.normalizeKIndex("-1") == "0")
    #expect(QSONormalizer.normalizeKIndex("3.6") == "4")
    #expect(QSONormalizer.normalizeKIndex("11") == "9")
  }

  @Test func normalizeKIndexEmptyReturnsEmpty() {
    #expect(QSONormalizer.normalizeKIndex("") == "")
    #expect(QSONormalizer.normalizeKIndex("  ") == "  ")
  }

  @Test func normalizeKIndexNonNumericReturnsEmpty() {
    #expect(QSONormalizer.normalizeKIndex("abc") == "")
    #expect(QSONormalizer.normalizeKIndex("N/A") == "")
  }

  @Test func normalizeKIndexBoundaryValues() {
    #expect(QSONormalizer.normalizeKIndex("0") == "0")
    #expect(QSONormalizer.normalizeKIndex("9") == "9")
    #expect(QSONormalizer.normalizeKIndex("4.5") == "5")
  }

  @Test func normalizeModeCaseInsensitive() {
    #expect(QSONormalizer.normalizeMode("usb") == "SSB")
    #expect(QSONormalizer.normalizeMode("lsb") == "SSB")
    #expect(QSONormalizer.normalizeMode("Usb") == "SSB")
  }

  @Test func normalizePowerEmptyPassthrough() {
    #expect(QSONormalizer.normalizePower("") == "")
    #expect(QSONormalizer.normalizePower("  ") == "  ")
  }

  @Test func normalizePowerNonNumericPassthrough() {
    #expect(QSONormalizer.normalizePower("QRP") == "QRP")
  }

  @Test func normalizePreservesBandWhenAlreadySet() {
    var qso = QSO()
    qso.call = "DL5MN"
    qso.frequency = "14.074000"
    qso.band = "20m"

    let normalized = QSONormalizer.normalize(qso)
    #expect(normalized.band == "20m")
  }

  @Test func normalizeAddsBandFromFrequency() {
    var qso = QSO()
    qso.call = "DL5MN"
    qso.frequency = "14.074000"
    qso.mode = "USB"
    qso.kIndex = "8.2"

    let normalized = QSONormalizer.normalize(qso)

    #expect(normalized.band == "20m")
    #expect(normalized.mode == "SSB")
    #expect(normalized.kIndex == "8")
  }
}
