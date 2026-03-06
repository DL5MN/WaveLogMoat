import Foundation
import Network

public final class TextUDPListener: @unchecked Sendable {
    public let port: UInt16
    public let host: String

    public var onQSOReceived: (@Sendable (QSO) -> Void)?
    public var onError: (@Sendable (Error) -> Void)?

    public var isListening: Bool {
        listener != nil
    }

    private let queue: DispatchQueue
    private var listener: NWListener?

    public init(port: UInt16, host: String = "127.0.0.1") {
        self.port = port
        self.host = host
        self.queue = DispatchQueue(label: "com.dl5mn.WaveLogMoat.text-udp-listener", qos: .utility)
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
            Log.udp.info("Text UDP listener started on port \(self.port)")
        } catch {
            onError?(error)
        }
    }

    public func stop() {
        listener?.stateUpdateHandler = nil
        listener?.newConnectionHandler = nil
        listener?.cancel()
        listener = nil
        Log.udp.info("Text UDP listener stopped on port \(self.port)")
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { state in
            if case .failed(let error) = state {
                Log.udp.error("Text UDP connection failed: \(error.localizedDescription)")
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
            let lowercased = payload.lowercased()
            if lowercased.contains("xml") || lowercased.contains("<contactinfo") {
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
