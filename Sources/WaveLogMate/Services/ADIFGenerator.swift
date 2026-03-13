import Foundation

public enum ADIFGenerator {
  private static let adifVersion = "3.1.6"
  private static var programName: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "WaveLogMate"
  }

  private static func generateHeader() -> String {
    formatField("ADIF_VER", value: adifVersion) + "\n"
      + formatField("PROGRAMID", value: programName) + "\n"
      + "<EOH>\n"
  }

  public static func generate(_ qsos: [QSO], includeHeader: Bool = true) -> String {
    var adif = ""
    if includeHeader {
      adif += generateHeader()
    }
    for qso in qsos {
      adif += generateRecord(qso)
    }
    return adif
  }

  public static func generateRecord(_ qso: QSO) -> String {
    var parts: [String] = []
    for field in ADIFField.allCases {
      let value = qso[field]
      if !value.isEmpty {
        parts.append(formatField(field.rawValue, value: value))
      }
    }
    return parts.joined(separator: " ") + " <EOR>\n"
  }

  public static func formatField(_ name: String, value: String) -> String {
    "<\(name):\(value.utf8.count)>\(value)"
  }
}
