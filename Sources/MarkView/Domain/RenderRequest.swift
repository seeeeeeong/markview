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
    let accentHeadings: Bool
    let accentBold: Bool
    let accentInlineCode: Bool
    let accentHeadingsColor: String
    let accentBoldColor: String
    let accentInlineCodeColor: String

    static func current(source: String, fileURL: URL) -> RenderRequest {
        let headings = AppearanceStore.accent(for: .headings)
        let bold = AppearanceStore.accent(for: .bold)
        let inlineCode = AppearanceStore.accent(for: .inlineCode)
        let width = AppearanceStore.contentWidth
        return RenderRequest(
            source: source,
            baseUrl: fileURL.deletingLastPathComponent().absoluteString,
            documentType: DocumentKind(fileExtension: fileURL.pathExtension),
            theme: AppearanceStore.theme.wireValue,
            profile: AppearanceStore.profile.rawValue,
            fontFamily: AppearanceStore.fontFamily,
            fontSize: AppearanceStore.fontSize,
            maxContentWidth: width == AppearanceStore.fullWidth ? nil : width,
            accentHeadings: headings != nil,
            accentBold: bold != nil,
            accentInlineCode: inlineCode != nil,
            accentHeadingsColor: (headings ?? .orange).rawValue,
            accentBoldColor: (bold ?? .gold).rawValue,
            accentInlineCodeColor: (inlineCode ?? .green).rawValue
        )
    }

    func encodedJSON() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
