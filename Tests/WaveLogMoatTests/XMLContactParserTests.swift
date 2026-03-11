import Testing
import WaveLogMoat

@Suite struct XMLContactParserTests {
  @Test func parseValidWSJTXContactInfo() throws {
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

    #expect(qso.call == "DJ7NT")
    #expect(qso.mode == "FT8")
    #expect(qso.frequency == "7.074000")
    #expect(qso.frequencyRx == "7.074000")
    #expect(qso.qsoDate == "20240110")
    #expect(qso.timeOn == "120000")
  }

  @Test func parsePreservesRawMode() throws {
    let usbXML = "<contactinfo><call>W1AW</call><mode>USB</mode></contactinfo>"
    let lsbXML = "<contactinfo><call>K1ABC</call><mode>LSB</mode></contactinfo>"
    let ft8XML = "<contactinfo><call>DL5MN</call><mode>FT8</mode></contactinfo>"

    #expect(try XMLContactParser.parse(usbXML).mode == "USB")
    #expect(try XMLContactParser.parse(lsbXML).mode == "LSB")
    #expect(try XMLContactParser.parse(ft8XML).mode == "FT8")
  }

  @Test func parseSupportsMultipleTimestampFormats() throws {
    let n1mm =
      "<contactinfo><call>W1AW</call><timestamp>2024-01-10 12:00:00</timestamp></contactinfo>"
    let dxlog =
      "<contactinfo><call>W1AW</call><timestamp>2024-01-10T12:00:00.000Z</timestamp></contactinfo>"
    let iso =
      "<contactinfo><call>W1AW</call><timestamp>2024-01-10T12:00:00Z</timestamp></contactinfo>"

    #expect(try XMLContactParser.parse(n1mm).timeOn == "120000")
    #expect(try XMLContactParser.parse(dxlog).timeOn == "120000")
    #expect(try XMLContactParser.parse(iso).timeOn == "120000")
  }

  @Test func parseUsesTxAsRxWhenRxMissing() throws {
    let xml = "<contactinfo><call>W1AW</call><txfreq>14074000</txfreq></contactinfo>"
    let qso = try XMLContactParser.parse(xml)
    #expect(qso.frequency == "14.074000")
    #expect(qso.frequencyRx == "14.074000")
  }

  @Test func parseThrowsForMissingCall() {
    let xml = "<contactinfo><mode>FT8</mode></contactinfo>"
    #expect(throws: XMLContactParser.ParseError.missingRequiredField("call")) {
      try XMLContactParser.parse(xml)
    }
  }

  @Test func parseThrowsForInvalidTimestamp() {
    let xml = "<contactinfo><call>DJ7NT</call><timestamp>bad-date</timestamp></contactinfo>"
    #expect(throws: XMLContactParser.ParseError.invalidTimestamp("bad-date")) {
      try XMLContactParser.parse(xml)
    }
  }
}
