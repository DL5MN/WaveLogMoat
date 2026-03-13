import Testing
import WaveLogMate

@Suite struct ADIFParserTests {
  @Test func parseSingleRecordWithHeader() throws {
    let input = """
      <ADIF_VER:5>3.1.4
      <PROGRAMID:12>WaveLogMate
      <EOH>
      <CALL:5>DJ7NT <MODE:3>FT8 <FREQ:8>7.074000 <QSO_DATE:8>20240110 <TIME_ON:6>120000 <RST_SENT:3>-15 <RST_RCVD:3>-10 <BAND:3>40m <EOR>
      """

    let records = try ADIFParser.parse(input)
    #expect(records.count == 1)
    #expect(records[0].call == "DJ7NT")
    #expect(records[0].mode == "FT8")
    #expect(records[0].frequency == "7.074000")
    #expect(records[0].band == "40m")
  }

  @Test func parseMultipleRecordsWithMixedCaseEOR() throws {
    let input = "<CALL:5>W1AW <MODE:3>CW <EOR><call:5>K1ABC <mode:3>SSB <eor>"

    let records = try ADIFParser.parse(input)
    #expect(records.count == 2)
    #expect(records[0].call == "W1AW")
    #expect(records[1].call == "K1ABC")
    #expect(records[1].mode == "SSB")
  }

  @Test func parseFieldsHandlesTypeSpecifier() {
    let record = "<CALL:5:S>DL5MN <RST_RCVD:3:N>-10"
    let fields = ADIFParser.parseFields(record)

    #expect(fields["CALL"] == "DL5MN")
    #expect(fields["RST_RCVD"] == "-10")
  }

  @Test func parseThrowsMissingCall() {
    let input = "<MODE:3>FT8 <EOR>"
    #expect(throws: ADIFParser.ParseError.missingRequiredField("CALL")) {
      try ADIFParser.parse(input)
    }
  }

  @Test func parseThrowsEmptyInput() {
    #expect(throws: ADIFParser.ParseError.emptyInput) {
      try ADIFParser.parse("  \n  ")
    }
  }
}
