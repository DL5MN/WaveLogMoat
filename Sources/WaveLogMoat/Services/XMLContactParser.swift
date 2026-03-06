import Foundation

public enum XMLContactParser {
    public enum ParseError: Error, LocalizedError, Equatable {
        case invalidXML(String)
        case missingRequiredField(String)
        case invalidFrequency(String)
        case invalidTimestamp(String)

        public var errorDescription: String? {
            switch self {
            case .invalidXML(let detail): return "Invalid XML: \(detail)"
            case .missingRequiredField(let field): return "Missing required field: \(field)"
            case .invalidFrequency(let value): return "Invalid frequency value: \(value)"
            case .invalidTimestamp(let value): return "Invalid timestamp: \(value)"
            }
        }
    }

    private static let timestampFormats = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        "yyyy-MM-dd'T'HH:mm:ss'Z'",
        "yyyy-MM-dd'T'HH:mm:ss",
    ]

    public static func parse(_ xmlString: String) throws -> QSO {
        let delegate = ContactInfoXMLDelegate()
        let parser = XMLParser(data: Data(xmlString.utf8))
        parser.delegate = delegate

        guard parser.parse() else {
            let errorDesc = parser.parserError?.localizedDescription ?? "Unknown XML parsing error"
            throw ParseError.invalidXML(errorDesc)
        }

        return try buildQSO(from: delegate.fields)
    }

    private static func buildQSO(from fields: [String: String]) throws -> QSO {
        guard let call = fields["call"], !call.isEmpty else {
            throw ParseError.missingRequiredField("call")
        }

        var qso = QSO()
        qso.call = call

        if let timestamp = fields["timestamp"] {
            guard let date = parseTimestamp(timestamp) else {
                throw ParseError.invalidTimestamp(timestamp)
            }

            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")

            dateFormatter.dateFormat = "yyyyMMdd"
            let qsoDate = dateFormatter.string(from: date)
            qso.qsoDate = qsoDate
            qso.qsoDateOff = qsoDate

            dateFormatter.dateFormat = "HHmmss"
            let time = dateFormatter.string(from: date)
            qso.timeOn = time
            qso.timeOff = time
        }

        if let mode = fields["mode"] {
            qso.mode = mode
        }

        if let txFreqStr = fields["txfreq"] {
            guard let txFreqHz = Double(txFreqStr) else {
                throw ParseError.invalidFrequency(txFreqStr)
            }
            let freqMHz = txFreqHz / 1_000_000.0
            qso.frequency = String(format: "%.6f", freqMHz)
        }

        if let rxFreqStr = fields["rxfreq"] {
            guard let rxFreqHz = Double(rxFreqStr) else {
                throw ParseError.invalidFrequency(rxFreqStr)
            }
            qso.frequencyRx = String(format: "%.6f", rxFreqHz / 1_000_000.0)
        } else {
            qso.frequencyRx = qso.frequency
        }

        qso.rstReceived = fields["rcv"] ?? ""
        qso.rstSent = fields["snt"] ?? ""
        qso.txPower = fields["power"] ?? ""
        qso.operatorCall = fields["operator"] ?? ""
        qso.comment = fields["comment"] ?? ""
        qso.stx = fields["sntnr"] ?? ""
        qso.srx = fields["rcvnr"] ?? ""
        qso.myCall = fields["mycall"] ?? ""
        qso.stationCallsign = fields["mycall"] ?? ""
        qso.gridsquare = fields["gridsquare"] ?? ""

        return qso
    }

    private static func parseTimestamp(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")

        for format in timestampFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: string) {
            return date
        }
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: string)
    }
}

private final class ContactInfoXMLDelegate: NSObject, XMLParserDelegate {
    var fields: [String: String] = [:]

    private var currentElement: String?
    private var currentValue = ""
    private var insideContactInfo = false

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        if elementName == "contactinfo" {
            insideContactInfo = true
            return
        }

        if insideContactInfo {
            currentElement = elementName
            currentValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement != nil {
            currentValue += string
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        if elementName == "contactinfo" {
            insideContactInfo = false
            currentElement = nil
            currentValue = ""
            return
        }

        if insideContactInfo, let currentElement {
            fields[currentElement] = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            self.currentElement = nil
            currentValue = ""
        }
    }
}
