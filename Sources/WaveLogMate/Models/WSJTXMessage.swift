public enum WSJTXMessageType: UInt32, Sendable {
  case heartbeat = 0
  case status = 1
  case decode = 2
  case clear = 3
  case reply = 4
  case qsoLogged = 5
  case close = 6
  case replay = 7
  case haltTx = 8
  case freeText = 9
  case wsprDecode = 10
  case location = 11
  case loggedADIF = 12
  case highlightCallsign = 13
  case switchConfiguration = 14
  case configure = 15
}

public struct WSJTXHeader: Sendable, Equatable {
  public static let magic: UInt32 = 0xadbc_cbda
  public let schema: UInt32
  public let messageType: WSJTXMessageType
  public let clientId: String

  public init(schema: UInt32, messageType: WSJTXMessageType, clientId: String) {
    self.schema = schema
    self.messageType = messageType
    self.clientId = clientId
  }
}
