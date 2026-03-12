import Testing
@testable import WaveLogMoat

@Suite struct TextUDPListenerTests {
  @Test func detectsContactInfoXMLPayloads() {
    #expect(TextUDPListener.isXMLContactInfoPayload("<contactinfo><call>W1AW</call></contactinfo>"))
    #expect(
      TextUDPListener.isXMLContactInfoPayload(
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <contactinfo><call>W1AW</call></contactinfo>
        """
      ))
  }

  @Test func ignoresADIFPayloadsContainingXMLAsText() {
    let adif = "<CALL:4>W1AW <COMMENT:17>xml status note <EOR>"
    #expect(TextUDPListener.isXMLContactInfoPayload(adif) == false)
  }
}
