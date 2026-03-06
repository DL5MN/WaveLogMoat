import Foundation

public enum ADIFParser {
    public enum ParseError: Error, LocalizedError, Equatable {
        case emptyInput
        case noRecordsFound
        case missingRequiredField(String)

        public var errorDescription: String? {
            switch self {
            case .emptyInput: return "Empty ADIF input"
            case .noRecordsFound: return "No QSO records found in ADIF data"
            case .missingRequiredField(let field): return "Missing required field: \(field)"
            }
        }
    }

    public static func parse(_ adifString: String) throws -> [QSO] {
        let trimmed = adifString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ParseError.emptyInput }

        let records = splitRecords(trimmed)
        guard !records.isEmpty else { throw ParseError.noRecordsFound }

        var output: [QSO] = []
        for record in records {
            let fields = parseFields(record)
            if fields.isEmpty {
                continue
            }
            output.append(try buildQSO(from: fields))
        }

        guard !output.isEmpty else { throw ParseError.noRecordsFound }
        return output
    }

    private static func splitRecords(_ text: String) -> [String] {
        var content = text
        if let eohRange = content.range(of: "<EOH>", options: .caseInsensitive) {
            content = String(content[eohRange.upperBound...])
        }

        let eorRegex = try? NSRegularExpression(pattern: "(?i)<eor>")
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let separated = eorRegex?.stringByReplacingMatches(in: content, range: range, withTemplate: "\u{1E}") ?? content

        return separated
            .split(separator: "\u{1E}")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    public static func parseFields(_ record: String) -> [String: String] {
        var fields: [String: String] = [:]
        var index = record.startIndex

        while index < record.endIndex {
            guard let tagStart = record[index...].firstIndex(of: "<") else { break }
            guard let tagEnd = record[tagStart...].firstIndex(of: ">") else { break }

            let tagContent = String(record[record.index(after: tagStart)..<tagEnd])
            let afterTag = record.index(after: tagEnd)
            let tagParts = tagContent.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)

            if tagParts.count >= 2,
               let fieldName = tagParts.first.map(String.init),
               let length = Int(tagParts[1]) {
                let valueStart = afterTag
                let maxLen = record.distance(from: valueStart, to: record.endIndex)
                let boundedLength = max(0, min(length, maxLen))
                let valueEnd = record.index(valueStart, offsetBy: boundedLength)
                let value = String(record[valueStart..<valueEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                fields[fieldName.uppercased()] = value
                index = valueEnd
            } else {
                index = afterTag
            }
        }

        return fields
    }

    private static func buildQSO(from fields: [String: String]) throws -> QSO {
        guard let call = fields["CALL"], !call.isEmpty else {
            throw ParseError.missingRequiredField("CALL")
        }

        var qso = QSO()
        qso.call = call

        for field in ADIFField.allCases {
            if let value = fields[field.rawValue], !value.isEmpty {
                qso[field] = value
            }
        }

        return qso
    }
}
