import Foundation
import WebKit

final class RendererSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "markview"
    static let indexURL = URL(string: "markview://renderer/index.html")!

    static func documentBase(for directory: URL) -> String {
        let encoded = directory.standardizedFileURL.path
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        return "markview://doc\(encoded)/"
    }

    private static let mimeTypes: [String: String] = [
        "html": "text/html",
        "js": "text/javascript",
        "css": "text/css",
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "gif": "image/gif",
        "svg": "image/svg+xml",
        "webp": "image/webp",
        "ico": "image/x-icon",
        "pdf": "application/pdf",
    ]

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url, let fileURL = resolve(url) else {
            urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
            return
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let mimeType = Self.mimeTypes[fileURL.pathExtension.lowercased()] ?? "application/octet-stream"
        let response = URLResponse(
            url: url,
            mimeType: mimeType,
            expectedContentLength: data.count,
            textEncodingName: mimeType.hasPrefix("text/") ? "utf-8" : nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private func resolve(_ url: URL) -> URL? {
        switch url.host {
        case "renderer":
            guard let directory = RendererAssets.directory else { return nil }
            let name = url.lastPathComponent
            guard !name.isEmpty, !name.contains("..") else { return nil }
            return directory.appendingPathComponent(name)
        case "doc":
            return URL(fileURLWithPath: url.path).standardizedFileURL
        default:
            return nil
        }
    }
}
