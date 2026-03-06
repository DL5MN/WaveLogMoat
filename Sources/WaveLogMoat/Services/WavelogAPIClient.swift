import Foundation

public final class WavelogAPIClient: @unchecked Sendable {
    public struct APIError: Error, LocalizedError, Sendable {
        public let message: String
        public let statusCode: Int?

        public init(message: String, statusCode: Int? = nil) {
            self.message = message
            self.statusCode = statusCode
        }

        public var errorDescription: String? {
            if let statusCode {
                return "\(message) (HTTP \(statusCode))"
            }
            return message
        }
    }

    public struct QSOResponse: Codable, Sendable, Equatable {
        public let status: String
        public let messages: [String]?

        public init(status: String, messages: [String]? = nil) {
            self.status = status
            self.messages = messages
        }
    }

    public struct VersionResponse: Codable, Sendable {
        public let status: String
        public let version: String
    }

    private struct QSORequestPayload: Codable, Sendable {
        let key: String
        let stationProfileID: String
        let type: String
        let string: String

        enum CodingKeys: String, CodingKey {
            case key
            case stationProfileID = "station_profile_id"
            case type
            case string
        }
    }

    private struct KeyPayload: Codable, Sendable {
        let key: String
    }

    private let urlSession: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    public init(allowSelfSignedCerts: Bool = true, timeout: TimeInterval = 5.0) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.waitsForConnectivity = false

        let delegate = SelfSignedCertificateDelegate(allowSelfSignedCerts: allowSelfSignedCerts)
        self.urlSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
    }

    public func logQSO(
        adifString: String,
        apiKey: String,
        stationProfileID: String,
        baseURL: String
    ) async throws -> QSOResponse {
        let payload = Self.buildQSOPayload(
            adifString: adifString,
            apiKey: apiKey,
            stationProfileID: stationProfileID
        )
        let request = try buildRequest(baseURL: baseURL, endpointPath: "qso", body: payload)
        let response: QSOResponse = try await perform(request, decodeAs: QSOResponse.self)

        guard response.status.lowercased() == "created" || response.status.lowercased() == "ok" else {
            let message = response.messages?.joined(separator: ", ") ?? "Wavelog rejected QSO"
            throw APIError(message: message)
        }

        return response
    }

    public func testConnection(
        apiKey: String,
        stationProfileID: String,
        baseURL: String
    ) async throws -> Bool {
        let testADIF = "<CALL:4>TEST <MODE:3>FT8 <FREQ:9>14.074000 <QSO_DATE:8>20240101 <TIME_ON:6>000000 <RST_SENT:3>-10 <RST_RCVD:3>-10 <EOR>"
        let payload = Self.buildQSOPayload(
            adifString: testADIF,
            apiKey: apiKey,
            stationProfileID: stationProfileID
        )
        let request = try buildRequest(baseURL: baseURL, endpointPath: "qso/true", body: payload)
        let response: QSOResponse = try await perform(request, decodeAs: QSOResponse.self)
        return response.status.lowercased() == "created" || response.status.lowercased() == "ok"
    }

    public func fetchStationProfiles(
        apiKey: String,
        baseURL: String
    ) async throws -> [StationProfile] {
        let request = try buildRequest(baseURL: baseURL, endpointPath: "station_info/\(apiKey)", body: Data())
        return try await perform(request, decodeAs: [StationProfile].self)
    }

    public func fetchVersion(
        apiKey: String,
        baseURL: String
    ) async throws -> String {
        let payload = Self.buildVersionPayload(apiKey: apiKey)
        let request = try buildRequest(baseURL: baseURL, endpointPath: "version", body: payload)
        let response: VersionResponse = try await perform(request, decodeAs: VersionResponse.self)
        return response.version
    }

    public static func buildQSOPayload(
        adifString: String,
        apiKey: String,
        stationProfileID: String
    ) -> Data {
        let payload = QSORequestPayload(
            key: apiKey,
            stationProfileID: stationProfileID,
            type: "adif",
            string: adifString
        )
        let encoder = JSONEncoder()
        return (try? encoder.encode(payload)) ?? Data()
    }

    public static func buildVersionPayload(apiKey: String) -> Data {
        let payload = KeyPayload(key: apiKey)
        let encoder = JSONEncoder()
        return (try? encoder.encode(payload)) ?? Data()
    }

    private func buildRequest(baseURL: String, endpointPath: String, body: Data) throws -> URLRequest {
        guard let endpoint = endpointURL(baseURL: baseURL, endpointPath: endpointPath) else {
            throw APIError(message: "Invalid Wavelog base URL: \(baseURL)")
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("WaveLogMoat/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = body
        return request
    }

    private func endpointURL(baseURL: String, endpointPath: String) -> URL? {
        guard var url = URL(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }

        let trimmed = endpointPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        url.appendPathComponent("api")
        url.appendPathComponent(trimmed)
        return url
    }

    private func perform<T: Decodable>(_ request: URLRequest, decodeAs type: T.Type) async throws -> T {
        Log.api.debug("Sending API request to \(request.url?.absoluteString ?? "unknown")")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            Log.api.error("Network request failed for \(request.url?.absoluteString ?? "unknown"): \(error.localizedDescription)")
            throw APIError(message: "Network request failed: \(error.localizedDescription)")
        }

        guard let http = response as? HTTPURLResponse else {
            Log.api.error("Received non-HTTP response for \(request.url?.absoluteString ?? "unknown")")
            throw APIError(message: "Invalid HTTP response")
        }

        Log.api.debug("API response status \(http.statusCode) from \(request.url?.absoluteString ?? "unknown")")

        guard (200...299).contains(http.statusCode) else {
            let message = Self.extractErrorMessage(from: data)
            Log.api.error("API request failed with status \(http.statusCode): \(message)")
            throw APIError(message: message, statusCode: http.statusCode)
        }

        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            Log.api.error("Failed to decode API response from \(request.url?.absoluteString ?? "unknown"): \(error.localizedDescription)")
            throw APIError(message: "Failed to decode response: \(error.localizedDescription)")
        }
    }

    private static func extractErrorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let reason = json["reason"] as? String {
            return reason
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
}

private final class SelfSignedCertificateDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let allowSelfSignedCerts: Bool

    init(allowSelfSignedCerts: Bool) {
        self.allowSelfSignedCerts = allowSelfSignedCerts
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard allowSelfSignedCerts,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}
