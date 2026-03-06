import Foundation
import Network

public final class BinaryUDPListener: @unchecked Sendable {
    public let port: UInt16
    public let host: String

    public var onHeartbeat: (@Sendable (String, UInt32, String, String) -> Void)?
    public var onStatusUpdate: (@Sendable (String, WSJTXStatus) -> Void)?
    public var onQSOLogged: (@Sendable (String, QSO) -> Void)?
    public var onLoggedADIF: (@Sendable (String, String) -> Void)?
    public var onClose: (@Sendable (String) -> Void)?
    public var onError: (@Sendable (Error) -> Void)?

    public var isListening: Bool {
        listener != nil
    }

    private let queue: DispatchQueue
    private let reader: QDataStreamReader
    private var listener: NWListener?

    public init(port: UInt16, host: String = "127.0.0.1", reader: QDataStreamReader = QDataStreamReader()) {
        self.port = port
        self.host = host
        self.reader = reader
        self.queue = DispatchQueue(label: "com.dl5mn.WaveLogMoat.binary-udp-listener", qos: .utility)
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
            let listener = try NWListener(using: .udp, on: nwPort)

            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .failed(let error):
                    self?.onError?(error)
                    self?.stop()
                default:
                    break
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            self.listener = listener
            listener.start(queue: queue)
            Log.udp.info("Binary UDP listener started on port \(self.port)")
        } catch {
            onError?(error)
        }
    }

    public func stop() {
        listener?.stateUpdateHandler = nil
        listener?.newConnectionHandler = nil
        listener?.cancel()
        listener = nil
        Log.udp.info("Binary UDP listener stopped on port \(self.port)")
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { state in
            if case .failed(let error) = state {
                Log.udp.error("Binary UDP connection failed: \(error.localizedDescription)")
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

            do {
                let message = try self.reader.parseMessage(data)
                self.dispatch(message)
            } catch {
                self.onError?(error)
            }

            connection.cancel()
        }
    }

    private func dispatch(_ message: WSJTXParsedMessage) {
        switch message {
        case .heartbeat(let clientId, let maxSchema, let version, let revision):
            onHeartbeat?(clientId, maxSchema, version, revision)
        case .status(let clientId, let status):
            onStatusUpdate?(clientId, status)
        case .qsoLogged(let clientId, let qso):
            onQSOLogged?(clientId, qso)
        case .loggedADIF(let clientId, let adifText):
            onLoggedADIF?(clientId, adifText)
        case .close(let clientId):
            onClose?(clientId)
        case .unknown(let typeValue, let clientId):
            Log.udp.debug("Ignoring unknown WSJT-X message type \(typeValue) from \(clientId)")
        }
    }
}
