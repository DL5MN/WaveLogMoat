import Foundation
import ServiceManagement

public enum LaunchAtLoginService {
  public static var isEnabled: Bool {
    SMAppService.mainApp.status == .enabled
  }

  public static func enable() throws {
    try SMAppService.mainApp.register()
  }

  public static func disable() throws {
    try SMAppService.mainApp.unregister()
  }

  public static func toggle() throws {
    if isEnabled {
      try disable()
    } else {
      try enable()
    }
  }
}
