import Foundation

public enum ADIFGenerator {
    public static func generate(_ qso: QSO, includeHeader: Bool = true) -> String {
        var adif = ""
        if includeHeader {
            adif += "<ADIF_VER:5>3.1.4\n"
            adif += "<PROGRAMID:12>WaveLogMoat\n"
            adif += "<EOH>\n"
        }
        adif += generateRecord(qso)
        return adif
    }

    public static func generate(_ qsos: [QSO], includeHeader: Bool = true) -> String {
        var adif = ""
        if includeHeader {
            adif += "<ADIF_VER:5>3.1.4\n"
            adif += "<PROGRAMID:12>WaveLogMoat\n"
            adif += "<EOH>\n"
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
