import Foundation

enum RendererAssets {
    static let runtimeNames: Set<String> = ["highlight", "katex", "mermaid"]

    static var directory: URL? {
        candidateDirectories().first {
            FileManager.default.fileExists(atPath: $0.appendingPathComponent("index.html").path)
        }
    }

    static var indexURL: URL? {
        directory?.appendingPathComponent("index.html")
    }

    static func runtimeScript(named name: String) -> String? {
        guard runtimeNames.contains(name), let directory else { return nil }
        return try? String(
            contentsOf: directory.appendingPathComponent("runtime-\(name).js"),
            encoding: .utf8
        )
    }

    private static func candidateDirectories() -> [URL] {
        var candidates: [URL] = []
        if let bundled = Bundle.main.resourceURL {
            candidates.append(bundled.appendingPathComponent("renderer", isDirectory: true))
        }
        let packageRoot = URL(fileURLWithPath: CommandLine.arguments[0])
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        candidates.append(packageRoot.appendingPathComponent("resources/renderer", isDirectory: true))
        return candidates
    }
}
