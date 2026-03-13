import os.log

public enum Log {
  public static let udp = Logger(subsystem: "de.dl5mn.WaveLogMate", category: "UDP")
  public static let api = Logger(subsystem: "de.dl5mn.WaveLogMate", category: "API")
  public static let parser = Logger(subsystem: "de.dl5mn.WaveLogMate", category: "Parser")
  public static let app = Logger(subsystem: "de.dl5mn.WaveLogMate", category: "App")
}
