import Foundation
import Observation

@MainActor
@Observable
public final class UDPService {
  public private(set) var isTextListening = false
  public private(set) var isBinaryListening = false
  public private(set) var lastError: String?

  private var textListener: TextUDPListener?
  private var binaryListener: BinaryUDPListener?

  public var onQSOReceived: ((QSO) -> Void)?
  public var onHeartbeat: ((String, String) -> Void)?
  public var onStatusUpdate: ((WSJTXStatus) -> Void)?
  public var onWSJTXClose: ((String) -> Void)?
  public var onError: ((Error) -> Void)?

  public init() {}

  public func startTextListener(port: UInt16, address: String) {
    stopTextListener()

    let listener = TextUDPListener(port: port, host: address)
    listener.onQSOReceived = { [weak self] qso in
      Task { @MainActor in
        self?.onQSOReceived?(qso)
      }
    }
    listener.onError = { [weak self] error in
      Task { @MainActor in
        self?.handleError(error)
      }
    }

    textListener = listener
    listener.start()
    isTextListening = listener.isListening
  }

  public func startBinaryListener(port: UInt16, address: String) {
    stopBinaryListener()

    let listener = BinaryUDPListener(port: port, host: address)
    listener.onHeartbeat = { [weak self] clientId, _, version, _ in
      Task { @MainActor in
        self?.onHeartbeat?(clientId, version)
      }
    }
    listener.onStatusUpdate = { [weak self] _, status in
      Task { @MainActor in
        self?.onStatusUpdate?(status)
      }
    }
    listener.onQSOLogged = { [weak self] _, qso in
      let normalized = QSONormalizer.normalize(qso)
      Task { @MainActor in
        self?.onQSOReceived?(normalized)
      }
    }
    listener.onLoggedADIF = { [weak self] _, adifText in
      Task { @MainActor in
        self?.handleLoggedADIF(adifText)
      }
    }
    listener.onClose = { [weak self] clientId in
      Task { @MainActor in
        self?.onWSJTXClose?(clientId)
      }
    }
    listener.onError = { [weak self] error in
      Task { @MainActor in
        self?.handleError(error)
      }
    }

    binaryListener = listener
    listener.start()
    isBinaryListening = listener.isListening
  }

  public func stopTextListener() {
    textListener?.stop()
    textListener = nil
    isTextListening = false
  }

  public func stopBinaryListener() {
    binaryListener?.stop()
    binaryListener = nil
    isBinaryListening = false
  }

  public func stopAll() {
    stopTextListener()
    stopBinaryListener()
  }

  private func handleLoggedADIF(_ adifText: String) {
    do {
      let qsos = try ADIFParser.parse(adifText)
      for qso in qsos {
        onQSOReceived?(QSONormalizer.normalize(qso))
      }
    } catch {
      handleError(error)
    }
  }

  private func handleError(_ error: Error) {
    lastError = error.localizedDescription
    onError?(error)
  }
}
