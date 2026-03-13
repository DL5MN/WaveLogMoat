import Foundation

public enum QSONormalizer {
  public static func normalize(_ qso: QSO) -> QSO {
    var normalized = qso
    normalized.txPower = normalizePower(qso.txPower)

    if normalized.band.isEmpty, !normalized.frequency.isEmpty,
      let band = BandMap.band(forFrequencyString: normalized.frequency)
    {
      normalized.band = band
    }

    normalized.mode = normalizeMode(normalized.mode)
    normalized.kIndex = normalizeKIndex(normalized.kIndex)

    return normalized
  }

  public static func normalizePower(_ power: String) -> String {
    let trimmed = power.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !trimmed.isEmpty else { return power }

    let numericPrefix = trimmed.prefix { $0.isNumber || $0 == "." }
    guard let value = Double(numericPrefix) else { return power }

    var watts = value
    if trimmed.contains("kw") {
      watts *= 1000.0
    } else if trimmed.contains("mw") {
      watts *= 0.001
    }

    if watts == watts.rounded(), watts.isFinite {
      return String(Int(watts))
    }
    return String(format: "%.3f", watts)
  }

  public static func normalizeMode(_ mode: String) -> String {
    let upper = mode.uppercased()
    if upper == "USB" || upper == "LSB" {
      return "SSB"
    }
    return mode
  }

  public static func normalizeKIndex(_ kIndex: String) -> String {
    let trimmed = kIndex.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return kIndex }
    guard let value = Double(trimmed) else { return "" }

    let clamped = max(0, min(9, Int(value.rounded())))
    return String(clamped)
  }
}
