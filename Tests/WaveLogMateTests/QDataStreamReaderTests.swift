import Foundation
import Testing
import WaveLogMate

@Suite struct QDataStreamReaderTests {
  @Test func readUInt32() throws {
    var data = Data()
    data.appendUInt32(0x1234_5678)

    let reader = QDataStreamReader(data: data)
    #expect(try reader.readUInt32() == 0x1234_5678)
    #expect(reader.bytesRemaining == 0)
  }

  @Test func readUInt64() throws {
    var data = Data()
    data.appendUInt64(0x1122_3344_5566_7788)

    let reader = QDataStreamReader(data: data)
    #expect(try reader.readUInt64() == 0x1122_3344_5566_7788)
    #expect(reader.bytesRemaining == 0)
  }

  @Test func readBool() throws {
    var data = Data()
    data.appendUInt8(1)
    data.appendUInt8(0)

    let reader = QDataStreamReader(data: data)
    #expect(try reader.readBool() == true)
    #expect(try reader.readBool() == false)
  }

  @Test func readUTF8String() throws {
    var data = Data()
    data.appendUTF8("WSJT-X")

    let reader = QDataStreamReader(data: data)
    #expect(try reader.readUTF8() == "WSJT-X")
  }

  @Test func readNullUTF8String() throws {
    var data = Data()
    data.appendUInt32(0xFFFF_FFFF)

    let reader = QDataStreamReader(data: data)
    #expect(try reader.readUTF8() == nil)
  }

  @Test func readQDateTime() throws {
    var data = Data()
    data.appendInt64(2_451_545)
    data.appendUInt32(3_600_000)
    data.appendUInt8(1)

    let reader = QDataStreamReader(data: data)
    let date = try reader.readQDateTime()

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    #expect(formatter.string(from: date) == "2000-01-01 01:00:00")
  }

  @Test func readDouble() throws {
    var data = Data()
    data.appendDouble(14.074)

    let reader = QDataStreamReader(data: data)
    let value = try reader.readDouble()
    #expect(abs(value - 14.074) < 0.000_000_1)
  }

  @Test func parseHeartbeatMessage() throws {
    var payload = Data()
    payload.appendUInt32(WSJTXHeader.magic)
    payload.appendUInt32(3)
    payload.appendUInt32(WSJTXMessageType.heartbeat.rawValue)
    payload.appendUTF8("WSJT-X")
    payload.appendUInt32(3)
    payload.appendUTF8("2.7.0")
    payload.appendUTF8("r123")

    let reader = QDataStreamReader()
    let message = try reader.parseMessage(payload)

    #expect(
      message
        == .heartbeat(clientId: "WSJT-X", maxSchema: 3, version: "2.7.0", revision: "r123")
    )
  }

  @Test func parseQSOLoggedMessage() throws {
    var payload = Data()
    payload.appendUInt32(WSJTXHeader.magic)
    payload.appendUInt32(3)
    payload.appendUInt32(WSJTXMessageType.qsoLogged.rawValue)
    payload.appendUTF8("WSJT-X")

    payload.appendQDateTime(
      julianDay: 2_460_711, millisecondsSinceMidnight: 45_610_000, timeSpec: 1)
    payload.appendUTF8("DJ7NT")
    payload.appendUTF8("JN49")
    payload.appendUInt64(14_074_000)
    payload.appendUTF8("FT8")
    payload.appendUTF8("-10")
    payload.appendUTF8("-08")
    payload.appendUTF8("50")
    payload.appendUTF8("TNX")
    payload.appendUTF8("Max")
    payload.appendQDateTime(
      julianDay: 2_460_711, millisecondsSinceMidnight: 45_600_000, timeSpec: 1)
    payload.appendUTF8("DL5MN")
    payload.appendUTF8("DL5MN")
    payload.appendUTF8("JO30")
    payload.appendUTF8("001")
    payload.appendUTF8("002")
    payload.appendUTF8("TR")

    let reader = QDataStreamReader()
    let message = try reader.parseMessage(payload)

    guard case .qsoLogged(let clientId, let qso) = message else {
      Issue.record("Expected .qsoLogged")
      return
    }

    #expect(clientId == "WSJT-X")
    #expect(qso.call == "DJ7NT")
    #expect(qso.gridsquare == "JN49")
    #expect(qso.frequency == "14.074000")
    #expect(qso.mode == "FT8")
    #expect(qso.rstSent == "-10")
    #expect(qso.rstReceived == "-08")
    #expect(qso.txPower == "50")
    #expect(qso.comment == "TNX")
    #expect(qso.name == "Max")
    #expect(qso.operatorCall == "DL5MN")
    #expect(qso.myCall == "DL5MN")
    #expect(qso.myGridsquare == "JO30")
    #expect(qso.stxString == "001")
    #expect(qso.srxString == "002")
    #expect(qso.propMode == "TR")
  }

  @Test func parseLoggedADIFMessage() throws {
    let adif = "<CALL:5>DJ7NT <MODE:3>FT8 <EOR>"

    var payload = Data()
    payload.appendUInt32(WSJTXHeader.magic)
    payload.appendUInt32(3)
    payload.appendUInt32(WSJTXMessageType.loggedADIF.rawValue)
    payload.appendUTF8("WSJT-X")
    payload.appendUTF8(adif)

    let reader = QDataStreamReader()
    let message = try reader.parseMessage(payload)
    #expect(message == .loggedADIF(clientId: "WSJT-X", adifText: adif))
  }

  @Test func invalidMagicThrows() throws {
    var payload = Data()
    payload.appendUInt32(0xDEAD_BEEF)
    payload.appendUInt32(3)
    payload.appendUInt32(WSJTXMessageType.heartbeat.rawValue)
    payload.appendUTF8("WSJT-X")

    let reader = QDataStreamReader()
    #expect(throws: QDataStreamReader.ReaderError.self) {
      try reader.parseMessage(payload)
    }
  }

  @Test func insufficientDataThrows() throws {
    let reader = QDataStreamReader(data: Data([0x00, 0x01]))
    #expect(throws: QDataStreamReader.ReaderError.self) {
      try reader.readUInt32()
    }
  }
}

extension Data {
  fileprivate mutating func appendUInt8(_ value: UInt8) {
    append(contentsOf: [value])
  }

  fileprivate mutating func appendUInt32(_ value: UInt32) {
    var v = value.bigEndian
    append(Data(bytes: &v, count: MemoryLayout<UInt32>.size))
  }

  fileprivate mutating func appendUInt64(_ value: UInt64) {
    var v = value.bigEndian
    append(Data(bytes: &v, count: MemoryLayout<UInt64>.size))
  }

  fileprivate mutating func appendInt64(_ value: Int64) {
    var v = value.bigEndian
    append(Data(bytes: &v, count: MemoryLayout<Int64>.size))
  }

  fileprivate mutating func appendUTF8(_ string: String?) {
    guard let string else {
      appendUInt32(0xFFFF_FFFF)
      return
    }

    let bytes = Array(string.utf8)
    appendUInt32(UInt32(bytes.count))
    append(contentsOf: bytes)
  }

  fileprivate mutating func appendDouble(_ value: Double) {
    appendUInt64(value.bitPattern)
  }

  fileprivate mutating func appendQDateTime(
    julianDay: Int64,
    millisecondsSinceMidnight: UInt32,
    timeSpec: UInt8,
    offsetSeconds: Int32? = nil
  ) {
    appendInt64(julianDay)
    appendUInt32(millisecondsSinceMidnight)
    appendUInt8(timeSpec)
    if let offsetSeconds {
      var offset = offsetSeconds.bigEndian
      append(Data(bytes: &offset, count: MemoryLayout<Int32>.size))
    }
  }
}
