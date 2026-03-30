import Foundation

public struct PersistedQSOLog: Codable, Sendable {
  public var recentQSOs: [QSO]
  public var totalQSOsLogged: Int
  public var totalQSOsFailed: Int

  public init(recentQSOs: [QSO] = [], totalQSOsLogged: Int = 0, totalQSOsFailed: Int = 0) {
    self.recentQSOs = recentQSOs
    self.totalQSOsLogged = totalQSOsLogged
    self.totalQSOsFailed = totalQSOsFailed
  }
}

public enum QSOLogStore {
  private static let fileName = "qso-log.json"

  private static var fileURL: URL? {
    guard
      let appSupport = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
      )
      .first
    else { return nil }
    let dir = appSupport.appendingPathComponent("WaveLogMate")
    return dir.appendingPathComponent(fileName)
  }

  public static func load() -> PersistedQSOLog {
    guard let url = fileURL,
      let data = try? Data(contentsOf: url),
      let log = try? JSONDecoder().decode(PersistedQSOLog.self, from: data)
    else {
      return PersistedQSOLog()
    }
    return log
  }

  public static func save(_ log: PersistedQSOLog) {
    guard let url = fileURL else { return }

    let dir = url.deletingLastPathComponent()
    do {
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      let data = try JSONEncoder().encode(log)
      try data.write(to: url, options: .atomic)
    } catch {
      Log.app.error("Failed to save QSO log: \(error.localizedDescription, privacy: .public)")
    }
  }

  public static func clear() {
    guard let url = fileURL else { return }
    try? FileManager.default.removeItem(at: url)
  }
}
