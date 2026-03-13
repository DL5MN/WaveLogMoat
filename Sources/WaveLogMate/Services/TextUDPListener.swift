import Foundation
import Network

public final class TextUDPListener: @unchecked Sendable {
  public let port: UInt16
  public let host: String

  public var onQSOReceived: (@Sendable (QSO) -> Void)?
  public var onError: (@Sendable (Error) -> Void)?
  public var onListeningStateChange: (@Sendable (Bool) -> Void)?

  public var isListening: Bool {
    listener != nil
  }

  private let queue: DispatchQueue
  private var listener: NWListener?

  public init(port: UInt16, host: String = "127.0.0.1") {
    self.port = port
    self.host = host
    self.queue = DispatchQueue(label: "de.dl5mn.WaveLogMate.text-udp-listener", qos: .utility)
  }

  public func start() {
    guard listener == nil else {
      return
    }

    guard let nwPort = NWEndpoint.Port(rawValue: port) else {
      onError?(UDPListenerError.invalidPort(port))
      return
    }

    do {
      let listener = try UDPListenerFactory.makeListener(host: host, port: nwPort)

      listener.stateUpdateHandler = { [weak self] state in
        switch state {
        case .ready:
          self?.onListeningStateChange?(true)
        case .failed(let error):
          self?.onListeningStateChange?(false)
          self?.onError?(error)
          self?.stop()
        case .cancelled:
          self?.onListeningStateChange?(false)
        default:
          break
        }
      }

      listener.newConnectionHandler = { [weak self] connection in
        self?.handleConnection(connection)
      }

      self.listener = listener
      listener.start(queue: queue)
      Log.udp.info("Text UDP listener started on port \(self.port)")
    } catch {
      onError?(error)
    }
  }

  public func stop() {
    let hadListener = listener != nil
    listener?.stateUpdateHandler = nil
    listener?.newConnectionHandler = nil
    listener?.cancel()
    listener = nil
    if hadListener {
      onListeningStateChange?(false)
    }
    Log.udp.info("Text UDP listener stopped on port \(self.port)")
  }

  private func handleConnection(_ connection: NWConnection) {
    connection.stateUpdateHandler = { state in
      if case .failed(let error) = state {
        Log.udp.error("Text UDP connection failed: \(error.localizedDescription, privacy: .public)")
      }
    }

    connection.start(queue: queue)
    connection.receiveMessage { [weak self] data, _, _, error in
      if let error {
        self?.onError?(error)
        connection.cancel()
        return
      }

      guard let self, let data, !data.isEmpty else {
        connection.cancel()
        return
      }

      self.processDatagram(data)
      connection.cancel()
    }
  }

  private func processDatagram(_ data: Data) {
    guard let payload = String(data: data, encoding: .utf8) else {
      onError?(UDPListenerError.invalidUTF8)
      return
    }

    do {
      if Self.isXMLContactInfoPayload(payload) {
        let qso = try XMLContactParser.parse(payload)
        onQSOReceived?(QSONormalizer.normalize(qso))
      } else {
        let qsos = try ADIFParser.parse(payload)
        for qso in qsos {
          onQSOReceived?(QSONormalizer.normalize(qso))
        }
      }
    } catch {
      onError?(error)
    }
  }

  static func isXMLContactInfoPayload(_ payload: String) -> Bool {
    let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }

    let pattern = #"^(?:<\?xml\b[^>]*>\s*)?<contactinfo\b"#
    return trimmed.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
  }
}

public enum UDPListenerError: Error, LocalizedError {
  case invalidPort(UInt16)
  case invalidUTF8

  public var errorDescription: String? {
    switch self {
    case .invalidPort(let port):
      return "Invalid UDP port: \(port)"
    case .invalidUTF8:
      return "Incoming UDP payload is not valid UTF-8"
    }
  }
}
