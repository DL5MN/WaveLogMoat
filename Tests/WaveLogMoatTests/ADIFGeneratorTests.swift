import XCTest
import WaveLogMoat

final class ADIFGeneratorTests: XCTestCase {
    func testGenerateSingleRecordIncludesHeaderAndEOR() {
        var qso = QSO()
        qso.call = "DL5MN"
        qso.mode = "FT8"
        qso.frequency = "14.074000"

        let output = ADIFGenerator.generate(qso)

        XCTAssertTrue(output.contains("<ADIF_VER:5>3.1.6"))
        XCTAssertTrue(output.contains("<PROGRAMID:"))
        XCTAssertTrue(output.contains("<CALL:5>DL5MN"))
        XCTAssertTrue(output.contains("<EOR>"))
    }

    func testGenerateWithoutHeader() {
        var qso = QSO()
        qso.call = "K1JT"

        let output = ADIFGenerator.generate(qso, includeHeader: false)

        XCTAssertFalse(output.contains("<EOH>"))
        XCTAssertTrue(output.contains("<CALL:4>K1JT"))
    }

    func testGenerateMultipleRecords() {
        var first = QSO()
        first.call = "W1AW"
        var second = QSO()
        second.call = "DL5MN"

        let output = ADIFGenerator.generate([first, second], includeHeader: false)

        XCTAssertEqual(output.components(separatedBy: "<EOR>").count - 1, 2)
        XCTAssertTrue(output.contains("<CALL:4>W1AW"))
        XCTAssertTrue(output.contains("<CALL:5>DL5MN"))
    }

    func testFormatFieldUsesUTF8Length() {
        let field = ADIFGenerator.formatField("COMMENT", value: "CQ TEST")
        XCTAssertEqual(field, "<COMMENT:7>CQ TEST")
    }

    func testRoundTripGeneratorParser() throws {
        var input = QSO()
        input.call = "JA1ABC"
        input.mode = "FT4"
        input.frequency = "7.047500"
        input.qsoDate = "20250105"
        input.timeOn = "181530"

        let adif = ADIFGenerator.generate(input, includeHeader: true)
        let parsed = try ADIFParser.parse(adif)

        XCTAssertEqual(parsed.count, 1)
        XCTAssertEqual(parsed[0].call, "JA1ABC")
        XCTAssertEqual(parsed[0].mode, "FT4")
        XCTAssertEqual(parsed[0].frequency, "7.047500")
        XCTAssertEqual(parsed[0].qsoDate, "20250105")
    }
}
