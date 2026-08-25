import Foundation

enum DebugLog {
    private static let path = ProcessInfo.processInfo.environment["MARKVIEW_DEBUG_LOG"]

    static func write(_ message: String) {
        guard let path else { return }
        let line = "\(Date()) \(message)\n"
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        } else {
            try? line.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
}
