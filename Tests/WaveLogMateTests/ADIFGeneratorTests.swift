import Testing
import WaveLogMate

@Suite struct ADIFGeneratorTests {
  @Test func generateSingleRecordIncludesHeaderAndEOR() {
    var qso = QSO()
    qso.call = "DL5MN"
    qso.mode = "FT8"
    qso.frequency = "14.074000"

    let output = ADIFGenerator.generate([qso])

    #expect(output.contains("<ADIF_VER:5>3.1.6"))
    #expect(output.contains("<PROGRAMID:"))
    #expect(output.contains("<CALL:5>DL5MN"))
    #expect(output.contains("<EOR>"))
  }

  @Test func generateWithoutHeader() {
    var qso = QSO()
    qso.call = "K1JT"

    let output = ADIFGenerator.generate([qso], includeHeader: false)

    #expect(!output.contains("<EOH>"))
    #expect(output.contains("<CALL:4>K1JT"))
  }

  @Test func generateMultipleRecords() {
    var first = QSO()
    first.call = "W1AW"
    var second = QSO()
    second.call = "DL5MN"

    let output = ADIFGenerator.generate([first, second], includeHeader: false)

    #expect(output.components(separatedBy: "<EOR>").count - 1 == 2)
    #expect(output.contains("<CALL:4>W1AW"))
    #expect(output.contains("<CALL:5>DL5MN"))
  }

  @Test func formatFieldUsesUTF8Length() {
    let field = ADIFGenerator.formatField("COMMENT", value: "CQ TEST")
    #expect(field == "<COMMENT:7>CQ TEST")
  }

  @Test func formatFieldMultiByteUTF8() {
    let field = ADIFGenerator.formatField("COMMENT", value: "73 de DL5MN ü")
    #expect(field == "<COMMENT:14>73 de DL5MN ü")
  }

  @Test func roundTripMultiByteComment() throws {
    var input = QSO()
    input.call = "DL5MN"
    input.comment = "Grüße aus München"

    let adif = ADIFGenerator.generate([input], includeHeader: false)
    let parsed = try ADIFParser.parse(adif)

    #expect(parsed.count == 1)
    #expect(parsed[0].comment == "Grüße aus München")
  }

  @Test func generateEmptyFieldsAreOmitted() {
    var qso = QSO()
    qso.call = "W1AW"

    let output = ADIFGenerator.generate([qso], includeHeader: false)

    #expect(!output.contains("<MODE:"))
    #expect(!output.contains("<FREQ:"))
    #expect(output.contains("<CALL:4>W1AW"))
  }

  @Test func roundTripGeneratorParser() throws {
    var input = QSO()
    input.call = "JA1ABC"
    input.mode = "FT4"
    input.frequency = "7.047500"
    input.qsoDate = "20250105"
    input.timeOn = "181530"

    let adif = ADIFGenerator.generate([input], includeHeader: true)
    let parsed = try ADIFParser.parse(adif)

    #expect(parsed.count == 1)
    #expect(parsed[0].call == "JA1ABC")
    #expect(parsed[0].mode == "FT4")
    #expect(parsed[0].frequency == "7.047500")
    #expect(parsed[0].qsoDate == "20250105")
  }
}
