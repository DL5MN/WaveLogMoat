import Foundation
import Observation
import SwiftUI

@Observable
public final class AppState {
    public var wsjtxConnectionStatus: ConnectionStatus = .disconnected
    public var wavelogConnectionStatus: ConnectionStatus = .disconnected

    public var wsjtxStatus: WSJTXStatus = WSJTXStatus()
    public var wsjtxClientId: String = ""
    public var wsjtxVersion: String = ""
    public var wavelogVersion: String = ""

    public var recentQSOs: [QSO] = []
    public private(set) var totalQSOsLogged: Int = 0
    public private(set) var totalQSOsFailed: Int = 0

    public var stationProfiles: [StationProfile] = []

    public var config: WavelogConfig = WavelogConfig() {
        didSet {
            saveConfig()
        }
    }

    public let udpService: UDPService
    public var apiClient: WavelogAPIClient

    public var lastError: String?
    public var showingError: Bool = false

    public var apiKey: String = "" {
        didSet {
            guard apiKey != oldValue else { return }
            do {
                try KeychainHelper.save(key: "wavelog_api_key", value: apiKey)
            } catch {
                Log.api.error("Failed to save API key to Keychain: \(error.localizedDescription)")
            }
        }
    }

    private var heartbeatTimer: Timer?
    private var wavelogCheckTimer: Timer?

    public init() {
        self.udpService = UDPService()
        self.apiClient = WavelogAPIClient(
            allowSelfSignedCerts: true,
            timeout: 5.0
        )
        self.apiKey = (try? KeychainHelper.load(key: "wavelog_api_key")) ?? ""
        loadConfig()
        setupCallbacks()
        startListening()
        applyDockVisibility()
        checkConnectionsOnStartup()
    }

    private func setupCallbacks() {
        udpService.onQSOReceived = { [weak self] qso in
            Task { @MainActor in
                await self?.handleQSOReceived(qso)
            }
        }

        udpService.onHeartbeat = { [weak self] clientId, version in
            Task { @MainActor in
                self?.wsjtxClientId = clientId
                self?.wsjtxVersion = version
                self?.wsjtxConnectionStatus = .connected
                self?.resetHeartbeatTimer()
            }
        }

        udpService.onStatusUpdate = { [weak self] status in
            Task { @MainActor in
                self?.wsjtxStatus = status
            }
        }

        udpService.onWSJTXClose = { [weak self] _ in
            Task { @MainActor in
                self?.wsjtxConnectionStatus = .disconnected
                self?.heartbeatTimer?.invalidate()
            }
        }

        udpService.onError = { [weak self] error in
            Task { @MainActor in
                self?.lastError = error.localizedDescription
                self?.showingError = true
            }
        }
    }

    private func resetHeartbeatTimer() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.wsjtxConnectionStatus = .disconnected
            }
        }
    }

    private func handleQSOReceived(_ qso: QSO) async {
        var newQSO = qso

        do {
            let adifString = ADIFGenerator.generate([newQSO])
            _ = try await apiClient.logQSO(
                adifString: adifString,
                apiKey: apiKey,
                stationProfileID: config.stationProfileID,
                baseURL: config.wavelogURL
            )

            newQSO.loggedSuccessfully = true
            newQSO.loggedAt = Date()
            totalQSOsLogged += 1

            if config.showNotifications {
                NotificationService.sendQSOLoggedNotification(call: newQSO.call, band: newQSO.band, mode: newQSO.mode)
            }
        } catch {
            newQSO.loggedSuccessfully = false
            newQSO.logError = error.localizedDescription
            if let apiError = error as? WavelogAPIClient.APIError {
                newQSO.logErrorRaw = apiError.rawBody
            }
            newQSO.loggedAt = Date()
            totalQSOsFailed += 1

            if config.showNotifications {
                NotificationService.sendQSOFailedNotification(call: newQSO.call, error: error.localizedDescription)
            }
        }

        recentQSOs.insert(newQSO, at: 0)
        if recentQSOs.count > 50 {
            recentQSOs.removeLast()
        }
    }

    private func checkConnectionsOnStartup() {
        if !apiKey.isEmpty && !config.wavelogURL.isEmpty {
            Task { @MainActor in
                await fetchStationProfiles()
                await checkWavelogVersion()
            }
        }

        startWavelogCheckTimer()
    }

    private func checkWavelogVersion() async {
        guard !apiKey.isEmpty, !config.wavelogURL.isEmpty else { return }
        do {
            let version = try await apiClient.fetchVersion(
                apiKey: apiKey,
                baseURL: config.wavelogURL
            )
            wavelogVersion = version
            if wavelogConnectionStatus != .connected {
                wavelogConnectionStatus = .connected
            }
        } catch {
            wavelogConnectionStatus = .error
        }
    }

    private func startWavelogCheckTimer() {
        wavelogCheckTimer?.invalidate()
        wavelogCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkWavelogVersion()
            }
        }
    }

    public func applyDockVisibility() {
        let policy: NSApplication.ActivationPolicy = config.showInDock ? .regular : .accessory
        NSApplication.shared.setActivationPolicy(policy)
    }

    public func startListening() {
        udpService.stopAll()

        switch config.udpProtocol {
        case .text:
            udpService.startTextListener(port: config.textUDPPort, address: config.listenAddress)
        case .binary:
            udpService.startBinaryListener(port: config.binaryUDPPort, address: config.listenAddress)
        }
    }

    public func stopListening() {
        udpService.stopAll()
        wsjtxConnectionStatus = .disconnected
        heartbeatTimer?.invalidate()
    }

    public func testWavelogConnection() async -> Bool {
        wavelogConnectionStatus = .connecting
        do {
            let success = try await apiClient.testConnection(
                apiKey: apiKey,
                stationProfileID: config.stationProfileID,
                baseURL: config.wavelogURL
            )
            wavelogConnectionStatus = success ? .connected : .error
            return success
        } catch {
            wavelogConnectionStatus = .error
            lastError = error.localizedDescription
            showingError = true
            return false
        }
    }

    public func fetchStationProfiles() async {
        do {
            stationProfiles = try await apiClient.fetchStationProfiles(
                apiKey: apiKey,
                baseURL: config.wavelogURL
            )
            wavelogConnectionStatus = .connected
        } catch {
            wavelogConnectionStatus = .error
            lastError = error.localizedDescription
            showingError = true
        }
    }

    public func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "wavelog_config"),
           let decoded = try? JSONDecoder().decode(WavelogConfig.self, from: data) {
            config = decoded
        }

        apiClient = WavelogAPIClient(
            allowSelfSignedCerts: config.allowSelfSignedCerts,
            timeout: TimeInterval(config.httpTimeout) / 1000.0
        )
    }

    public func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: "wavelog_config")
        }

        apiClient = WavelogAPIClient(
            allowSelfSignedCerts: config.allowSelfSignedCerts,
            timeout: TimeInterval(config.httpTimeout) / 1000.0
        )

        startListening()
        applyDockVisibility()
    }

}
