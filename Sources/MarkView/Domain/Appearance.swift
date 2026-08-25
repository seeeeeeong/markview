import AppKit

enum Theme: String, CaseIterable {
    case system
    case light
    case dark

    var wireValue: String {
        switch self {
        case .light: return "light"
        case .dark: return "dark"
        case .system:
            let match = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
            return match == .darkAqua ? "dark" : "light"
        }
    }
}

enum Profile: String, CaseIterable {
    case compact
    case spacious
}

enum Skin: String, CaseIterable {
    case github
    case latex
    case tufte

    var displayName: String {
        switch self {
        case .github: return "GitHub"
        case .latex: return "LaTeX"
        case .tufte: return "Tufte"
        }
    }
}

enum AccentColor: String, CaseIterable {
    case orange, gold, green, teal, blue, purple, pink, red

    var displayName: String { rawValue.capitalized }
}

enum AccentTarget: String, CaseIterable {
    case headings
    case bold
    case inlineCode

    var displayName: String {
        switch self {
        case .headings: return "Headings"
        case .bold: return "Bold"
        case .inlineCode: return "Inline Code"
        }
    }
}

enum AppearanceStore {
    static let fontSizeRange = 12...24
    static let defaultFontSize = 15
    static let contentWidthChoices = [768, 896, 1024, 1152, 1280, 1408, 1536]
    static let fullWidth = -1
    static let defaultContentWidth = 1152

    private static let defaults = UserDefaults.standard

    static var theme: Theme {
        get { Theme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .system }
        set { defaults.set(newValue.rawValue, forKey: "theme") }
    }

    static var profile: Profile {
        get { Profile(rawValue: defaults.string(forKey: "profile") ?? "") ?? .compact }
        set { defaults.set(newValue.rawValue, forKey: "profile") }
    }

    static var skin: Skin {
        get { Skin(rawValue: defaults.string(forKey: "skin") ?? "") ?? .github }
        set { defaults.set(newValue.rawValue, forKey: "skin") }
    }

    static var fontSize: Int {
        get {
            let stored = defaults.object(forKey: "fontSize") as? Int ?? defaultFontSize
            return stored.clamped(to: fontSizeRange)
        }
        set { defaults.set(newValue.clamped(to: fontSizeRange), forKey: "fontSize") }
    }

    static var contentWidth: Int {
        get {
            let stored = defaults.object(forKey: "contentWidth") as? Int ?? defaultContentWidth
            if stored == fullWidth { return fullWidth }
            return contentWidthChoices.contains(stored) ? stored : defaultContentWidth
        }
        set { defaults.set(newValue, forKey: "contentWidth") }
    }

    static func accent(for target: AccentTarget) -> AccentColor? {
        AccentColor(rawValue: defaults.string(forKey: accentKey(target)) ?? "")
    }

    static func setAccent(_ color: AccentColor?, for target: AccentTarget) {
        defaults.set(color?.rawValue ?? "off", forKey: accentKey(target))
    }

    private static func accentKey(_ target: AccentTarget) -> String {
        "accent.\(target.rawValue)"
    }
}

extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(range.upperBound, Swift.max(range.lowerBound, self))
    }
}
