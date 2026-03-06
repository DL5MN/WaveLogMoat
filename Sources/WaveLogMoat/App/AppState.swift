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
    
    private var heartbeatTimer: Timer?
    
    public init() {
        self.udpService = UDPService()
        self.apiClient = WavelogAPIClient(
            allowSelfSignedCerts: true,
            timeout: 5.0
        )
        loadConfig()
        setupCallbacks()
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
            let adifString = ADIFGenerator.generate(newQSO)
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
    
    public func startListening() {
        if config.enableTextUDP {
            udpService.startTextListener(port: config.textUDPPort, address: config.listenAddress)
        } else {
            udpService.stopTextListener()
        }
        
        if config.enableBinaryUDP {
            udpService.startBinaryListener(port: config.binaryUDPPort, address: config.listenAddress)
        } else {
            udpService.stopBinaryListener()
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
    }
    
    public var apiKey: String {
        get { (try? KeychainHelper.load(key: "wavelog_api_key")) ?? "" }
        set { try? KeychainHelper.save(key: "wavelog_api_key", value: newValue) }
    }
}

