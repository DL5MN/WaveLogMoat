import Foundation

public enum WSJTXParsedMessage: Sendable, Equatable {
    case heartbeat(clientId: String, maxSchema: UInt32, version: String, revision: String)
    case status(clientId: String, status: WSJTXStatus)
    case qsoLogged(clientId: String, qso: QSO)
    case loggedADIF(clientId: String, adifText: String)
    case close(clientId: String)
    case unknown(typeValue: UInt32, clientId: String)
}

public final class QDataStreamReader: @unchecked Sendable {
    public enum ReaderError: Error, LocalizedError {
        case insufficientData(operation: String, expected: Int, remaining: Int)
        case invalidBool(UInt8)
        case invalidUTF8
        case invalidMagic(UInt32)
        case invalidMessageType(UInt32)
        case missingClientId
        case invalidQTime(UInt32)
        case invalidJulianDay(Int64)
        case invalidTimeSpec(UInt8)
        case invalidDateComponents(year: Int, month: Int, day: Int)

        public var errorDescription: String? {
            switch self {
            case .insufficientData(let operation, let expected, let remaining):
                return "Insufficient data while reading \(operation): expected \(expected) bytes, remaining \(remaining)"
            case .invalidBool(let value):
                return "Invalid bool value: \(value). Expected 0 or 1"
            case .invalidUTF8:
                return "Invalid UTF-8 string data"
            case .invalidMagic(let value):
                return String(format: "Invalid WSJT-X magic number: 0x%08x", value)
            case .invalidMessageType(let value):
                return "Invalid WSJT-X message type value: \(value)"
            case .missingClientId:
                return "WSJT-X message is missing client ID"
            case .invalidQTime(let value):
                return "Invalid QTime milliseconds value: \(value)"
            case .invalidJulianDay(let value):
                return "Invalid Julian day value: \(value)"
            case .invalidTimeSpec(let value):
                return "Invalid QDateTime timespec value: \(value)"
            case .invalidDateComponents(let year, let month, let day):
                return "Invalid Gregorian date from Julian day: \(year)-\(month)-\(day)"
            }
        }
    }

    private var buffer: Data
    private var position: Int

    public init(data: Data = Data()) {
        self.buffer = data
        self.position = 0
    }

    public var bytesRemaining: Int {
        max(0, buffer.count - position)
    }

    public func reset() {
        position = 0
    }

    public func readUInt32() throws -> UInt32 {
        let data = try readRaw(byteCount: 4, operation: "UInt32")
        var value: UInt32 = 0
        for byte in data {
            value = (value << 8) | UInt32(byte)
        }
        return value
    }

    public func readUInt64() throws -> UInt64 {
        let data = try readRaw(byteCount: 8, operation: "UInt64")
        var value: UInt64 = 0
        for byte in data {
            value = (value << 8) | UInt64(byte)
        }
        return value
    }

    public func readInt32() throws -> Int32 {
        let raw = try readUInt32()
        return Int32(bitPattern: raw)
    }

    public func readInt64() throws -> Int64 {
        let raw = try readUInt64()
        return Int64(bitPattern: raw)
    }

    public func readBool() throws -> Bool {
        let value = try readUInt8()
        switch value {
        case 0: return false
        case 1: return true
        default: throw ReaderError.invalidBool(value)
        }
    }

    public func readUTF8() throws -> String? {
        let length = try readUInt32()
        if length == 0xFFFFFFFF {
            return nil
        }

        let byteCount = Int(length)
        let data = try readRaw(byteCount: byteCount, operation: "UTF-8 string")
        guard let string = String(data: data, encoding: .utf8) else {
            throw ReaderError.invalidUTF8
        }
        return string
    }

    public func readDouble() throws -> Double {
        let raw = try readUInt64()
        return Double(bitPattern: raw)
    }

    public func readQTime() throws -> UInt32 {
        let milliseconds = try readUInt32()
        guard milliseconds < 86_400_000 else {
            throw ReaderError.invalidQTime(milliseconds)
        }
        return milliseconds
    }

    public func readQDateTime() throws -> Date {
        let julianDay = try readInt64()
        guard julianDay > 0 else {
            throw ReaderError.invalidJulianDay(julianDay)
        }

        let milliseconds = try readQTime()
        let timeSpec = try readUInt8()

        let offsetSeconds: Int32
        switch timeSpec {
        case 0, 1, 3:
            offsetSeconds = 0
        case 2:
            offsetSeconds = try readInt32()
        default:
            throw ReaderError.invalidTimeSpec(timeSpec)
        }

        let (year, month, day) = try gregorianDateComponents(fromJulianDay: julianDay)
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = Int(milliseconds / 3_600_000)
        components.minute = Int((milliseconds % 3_600_000) / 60_000)
        components.second = Int((milliseconds % 60_000) / 1_000)
        components.nanosecond = Int(milliseconds % 1_000) * 1_000_000

        guard let date = components.date else {
            throw ReaderError.invalidDateComponents(year: year, month: month, day: day)
        }

        if timeSpec == 2 {
            return date.addingTimeInterval(TimeInterval(-offsetSeconds))
        }

        return date
    }

    public func parseMessage(_ data: Data) throws -> WSJTXParsedMessage {
        buffer = data
        reset()

        let magic = try readUInt32()
        guard magic == WSJTXHeader.magic else {
            throw ReaderError.invalidMagic(magic)
        }

        _ = try readUInt32()

        let messageTypeValue = try readUInt32()
        let messageType = WSJTXMessageType(rawValue: messageTypeValue)

        guard let clientId = try readUTF8(), !clientId.isEmpty else {
            throw ReaderError.missingClientId
        }

        guard let messageType else {
            return .unknown(typeValue: messageTypeValue, clientId: clientId)
        }

        switch messageType {
        case .heartbeat:
            let maxSchema = try readUInt32()
            let version = try readUTF8() ?? ""
            let revision = try readUTF8() ?? ""
            return .heartbeat(clientId: clientId, maxSchema: maxSchema, version: version, revision: revision)

        case .status:
            var status = WSJTXStatus()
            status.dialFrequencyHz = try readUInt64()
            status.mode = try readUTF8() ?? ""
            status.dxCall = try readUTF8() ?? ""
            status.report = try readUTF8() ?? ""
            status.txMode = try readUTF8() ?? ""
            status.txEnabled = try readBool()
            status.transmitting = try readBool()
            status.decoding = try readBool()
            status.rxDF = try readUInt32()
            status.txDF = try readUInt32()
            status.deCall = try readUTF8() ?? ""
            status.deGrid = try readUTF8() ?? ""
            status.dxGrid = try readUTF8() ?? ""
            status.txWatchdog = try readBool()
            status.subMode = try readUTF8() ?? ""
            status.fastMode = try readBool()
            status.specialOperationMode = try readUInt8()
            status.frequencyTolerance = try readUInt32()
            status.trPeriod = try readUInt32()
            status.configurationName = try readUTF8() ?? ""
            status.txMessage = try readUTF8() ?? ""
            return .status(clientId: clientId, status: status)

        case .qsoLogged:
            let dateTimeOff = try readQDateTime()
            let dxCall = try readUTF8() ?? ""
            let dxGrid = try readUTF8() ?? ""
            let txFrequencyHz = try readUInt64()
            let mode = try readUTF8() ?? ""
            let reportSent = try readUTF8() ?? ""
            let reportReceived = try readUTF8() ?? ""
            let txPower = try readUTF8() ?? ""
            let comments = try readUTF8() ?? ""
            let name = try readUTF8() ?? ""
            let dateTimeOn = try readQDateTime()
            let operatorCall = try readUTF8() ?? ""
            let myCall = try readUTF8() ?? ""
            let myGrid = try readUTF8() ?? ""
            let exchangeSent = try readUTF8() ?? ""
            let exchangeReceived = try readUTF8() ?? ""
            let propMode = try readUTF8() ?? ""

            var qso = QSO()
            qso.call = dxCall
            qso.gridsquare = dxGrid
            qso.frequency = Self.formatFrequencyMHz(fromHz: txFrequencyHz)
            qso.frequencyRx = qso.frequency
            qso.mode = mode
            qso.rstSent = reportSent
            qso.rstReceived = reportReceived
            qso.txPower = txPower
            qso.comment = comments
            qso.name = name
            qso.operatorCall = operatorCall
            qso.myCall = myCall
            qso.stationCallsign = myCall
            qso.myGridsquare = myGrid
            qso.stxString = exchangeSent
            qso.srxString = exchangeReceived
            qso.propMode = propMode

            qso.qsoDate = Self.formatDate(dateTimeOn)
            qso.timeOn = Self.formatTime(dateTimeOn)
            qso.qsoDateOff = Self.formatDate(dateTimeOff)
            qso.timeOff = Self.formatTime(dateTimeOff)

            return .qsoLogged(clientId: clientId, qso: qso)

        case .loggedADIF:
            let adifText = try readUTF8() ?? ""
            return .loggedADIF(clientId: clientId, adifText: adifText)

        case .close:
            return .close(clientId: clientId)

        default:
            return .unknown(typeValue: messageTypeValue, clientId: clientId)
        }
    }

    private func readUInt8() throws -> UInt8 {
        let data = try readRaw(byteCount: 1, operation: "UInt8")
        return data[data.startIndex]
    }

    private func readRaw(byteCount: Int, operation: String) throws -> Data {
        guard byteCount >= 0 else {
            return Data()
        }

        guard bytesRemaining >= byteCount else {
            throw ReaderError.insufficientData(operation: operation, expected: byteCount, remaining: bytesRemaining)
        }

        let start = position
        let end = position + byteCount
        position = end
        return buffer[start..<end]
    }

    private func gregorianDateComponents(fromJulianDay julianDay: Int64) throws -> (Int, Int, Int) {
        var l = julianDay + 68569
        let n = (4 * l) / 146097
        l = l - (146097 * n + 3) / 4
        let i = (4000 * (l + 1)) / 1461001
        l = l - (1461 * i) / 4 + 31
        let j = (80 * l) / 2447
        let day = Int(l - (2447 * j) / 80)
        l = j / 11
        let month = Int(j + 2 - 12 * l)
        let year = Int(100 * (n - 49) + i + l)

        guard (1...12).contains(month), (1...31).contains(day) else {
            throw ReaderError.invalidJulianDay(julianDay)
        }

        return (year, month, day)
    }

    private static func formatFrequencyMHz(fromHz hz: UInt64) -> String {
        let mhz = Double(hz) / 1_000_000.0
        return String(format: "%.6f", mhz)
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HHmmss"
        return formatter.string(from: date)
    }
}
