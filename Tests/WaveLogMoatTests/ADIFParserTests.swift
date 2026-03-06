import XCTest
import WaveLogMoat

final class ADIFParserTests: XCTestCase {
    func testParseSingleRecordWithHeader() throws {
        let input = """
        <ADIF_VER:5>3.1.4
        <PROGRAMID:12>WaveLogMoat
        <EOH>
        <CALL:5>DJ7NT <MODE:3>FT8 <FREQ:8>7.074000 <QSO_DATE:8>20240110 <TIME_ON:6>120000 <RST_SENT:3>-15 <RST_RCVD:3>-10 <BAND:3>40m <EOR>
        """

        let records = try ADIFParser.parse(input)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].call, "DJ7NT")
        XCTAssertEqual(records[0].mode, "FT8")
        XCTAssertEqual(records[0].frequency, "7.074000")
        XCTAssertEqual(records[0].band, "40m")
    }

    func testParseMultipleRecordsWithMixedCaseEOR() throws {
        let input = "<CALL:5>W1AW <MODE:3>CW <EOR><call:5>K1ABC <mode:3>SSB <eor>"

        let records = try ADIFParser.parse(input)
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records[0].call, "W1AW")
        XCTAssertEqual(records[1].call, "K1ABC")
        XCTAssertEqual(records[1].mode, "SSB")
    }

    func testParseFieldsHandlesTypeSpecifier() {
        let record = "<CALL:5:S>DL5MN <RST_RCVD:3:N>-10"
        let fields = ADIFParser.parseFields(record)

        XCTAssertEqual(fields["CALL"], "DL5MN")
        XCTAssertEqual(fields["RST_RCVD"], "-10")
    }

    func testParseThrowsMissingCall() {
        let input = "<MODE:3>FT8 <EOR>"
        XCTAssertThrowsError(try ADIFParser.parse(input)) { error in
            XCTAssertEqual(error as? ADIFParser.ParseError, .missingRequiredField("CALL"))
        }
    }

    func testParseThrowsEmptyInput() {
        XCTAssertThrowsError(try ADIFParser.parse("  \n  ")) { error in
            XCTAssertEqual(error as? ADIFParser.ParseError, .emptyInput)
        }
    }
}
