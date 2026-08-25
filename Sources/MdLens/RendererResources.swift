import Foundation

/// Locates the bundled renderer artifacts (index.html + runtime-*.js).
/// Works both inside a .app bundle (Contents/Resources/renderer) and when
/// running via `swift run` from the package checkout (resources/renderer).
enum RendererResources {
    static let runtimeNames: Set<String> = ["highlight", "katex", "mermaid"]

    static var rendererDirectory: URL? {
        var candidates: [URL] = []
        if let bundled = Bundle.main.resourceURL {
            candidates.append(bundled.appendingPathComponent("renderer", isDirectory: true))
        }
        let executableDir = URL(fileURLWithPath: CommandLine.arguments[0])
            .deletingLastPathComponent()
        // swift run: .build/<triple>/debug/MdLens → package root/resources/renderer
        candidates.append(
            executableDir
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("resources/renderer", isDirectory: true)
        )
        return candidates.first {
            FileManager.default.fileExists(
                atPath: $0.appendingPathComponent("index.html").path
            )
        }
    }

    static var indexURL: URL? {
        rendererDirectory?.appendingPathComponent("index.html")
    }

    static func runtimeScript(named name: String) -> String? {
        guard runtimeNames.contains(name), let dir = rendererDirectory else { return nil }
        return try? String(
            contentsOf: dir.appendingPathComponent("runtime-\(name).js"),
            encoding: .utf8
        )
    }
}
