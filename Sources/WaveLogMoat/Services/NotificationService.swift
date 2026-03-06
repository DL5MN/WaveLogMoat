import Foundation
import UserNotifications

public enum NotificationService {
    public static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            Log.app.error("Notification authorization request failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    public static func sendQSOLoggedNotification(call: String, band: String, mode: String) {
        let content = UNMutableNotificationContent()
        content.title = "QSO Logged"
        content.body = "\(call) on \(band) (\(mode))"
        content.sound = .default
        enqueue(content)
    }

    public static func sendQSOFailedNotification(call: String, error: String) {
        let content = UNMutableNotificationContent()
        content.title = "QSO Log Failed"
        content.body = "\(call): \(error)"
        content.sound = .default
        enqueue(content)
    }

    public static func sendConnectionNotification(service: String, connected: Bool) {
        let content = UNMutableNotificationContent()
        content.title = connected ? "Connected" : "Disconnected"
        content.body = "\(service) \(connected ? "connected" : "disconnected")"
        content.sound = .default
        enqueue(content)
    }

    private static func enqueue(_ content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Log.app.error("Failed to send notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
