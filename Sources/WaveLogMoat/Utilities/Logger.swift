import os.log

public enum Log {
    public static let udp = Logger(subsystem: "com.dl5mn.WaveLogMoat", category: "UDP")
    public static let api = Logger(subsystem: "com.dl5mn.WaveLogMoat", category: "API")
    public static let parser = Logger(subsystem: "com.dl5mn.WaveLogMoat", category: "Parser")
    public static let app = Logger(subsystem: "com.dl5mn.WaveLogMoat", category: "App")
}
