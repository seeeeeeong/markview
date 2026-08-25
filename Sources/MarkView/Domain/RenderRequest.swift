import Foundation

enum DocumentKind: String, Encodable {
    case markdown
    case mermaid

    init(fileExtension: String) {
        switch fileExtension.lowercased() {
        case "mmd", "mermaid": self = .mermaid
        default: self = .markdown
        }
    }
}

struct RenderRequest: Encodable {
    let version = 5
    let source: String
    let baseUrl: String
    let documentType: DocumentKind
    let theme: String
    let profile: String
    let fontFamily: String
    let fontSize: Int
    let maxContentWidth: Int?

    func encodedJSON() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
