import WaveLogMoat
import XCTest

final class XMLContactParserTests: XCTestCase {
  func testParseValidWSJTXContactInfo() throws {
    let xml = """
      <contactinfo>
        <timestamp>2024-01-10T12:00:00</timestamp>
        <call>DJ7NT</call>
        <mode>FT8</mode>
        <txfreq>7074000</txfreq>
        <rxfreq>7074000</rxfreq>
        <rcv>-10</rcv>
        <snt>-15</snt>
        <power>100</power>
        <operator>DL5MN</operator>
        <comment>TNX QSO</comment>
        <mycall>DL5MN</mycall>
        <gridsquare>JO30</gridsquare>
      </contactinfo>
      """

    let qso = try XMLContactParser.parse(xml)

    XCTAssertEqual(qso.call, "DJ7NT")
    XCTAssertEqual(qso.mode, "FT8")
    XCTAssertEqual(qso.frequency, "7.074000")
    XCTAssertEqual(qso.frequencyRx, "7.074000")
    XCTAssertEqual(qso.qsoDate, "20240110")
    XCTAssertEqual(qso.timeOn, "120000")
  }

  func testParsePreservesRawMode() throws {
    let usbXML = "<contactinfo><call>W1AW</call><mode>USB</mode></contactinfo>"
    let lsbXML = "<contactinfo><call>K1ABC</call><mode>LSB</mode></contactinfo>"
    let ft8XML = "<contactinfo><call>DL5MN</call><mode>FT8</mode></contactinfo>"

    XCTAssertEqual(try XMLContactParser.parse(usbXML).mode, "USB")
    XCTAssertEqual(try XMLContactParser.parse(lsbXML).mode, "LSB")
    XCTAssertEqual(try XMLContactParser.parse(ft8XML).mode, "FT8")
  }

  func testParseSupportsMultipleTimestampFormats() throws {
    let n1mm =
      "<contactinfo><call>W1AW</call><timestamp>2024-01-10 12:00:00</timestamp></contactinfo>"
    let dxlog =
      "<contactinfo><call>W1AW</call><timestamp>2024-01-10T12:00:00.000Z</timestamp></contactinfo>"
    let iso =
      "<contactinfo><call>W1AW</call><timestamp>2024-01-10T12:00:00Z</timestamp></contactinfo>"

    XCTAssertEqual(try XMLContactParser.parse(n1mm).timeOn, "120000")
    XCTAssertEqual(try XMLContactParser.parse(dxlog).timeOn, "120000")
    XCTAssertEqual(try XMLContactParser.parse(iso).timeOn, "120000")
  }

  func testParseUsesTxAsRxWhenRxMissing() throws {
    let xml = "<contactinfo><call>W1AW</call><txfreq>14074000</txfreq></contactinfo>"
    let qso = try XMLContactParser.parse(xml)
    XCTAssertEqual(qso.frequency, "14.074000")
    XCTAssertEqual(qso.frequencyRx, "14.074000")
  }

  func testParseThrowsForMissingCall() {
    let xml = "<contactinfo><mode>FT8</mode></contactinfo>"
    XCTAssertThrowsError(try XMLContactParser.parse(xml)) { error in
      XCTAssertEqual(error as? XMLContactParser.ParseError, .missingRequiredField("call"))
    }
  }

  func testParseThrowsForInvalidTimestamp() {
    let xml = "<contactinfo><call>DJ7NT</call><timestamp>bad-date</timestamp></contactinfo>"
    XCTAssertThrowsError(try XMLContactParser.parse(xml)) { error in
      XCTAssertEqual(error as? XMLContactParser.ParseError, .invalidTimestamp("bad-date"))
    }
  }
}
