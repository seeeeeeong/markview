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

enum AppearanceStore {
    static let fontSizeRange = 12...24
    static let defaultFontSize = 15
    static let defaultContentWidth = 1152

    private static let themeKey = "theme"
    private static let profileKey = "profile"
    private static let fontSizeKey = "fontSize"

    static var theme: Theme {
        get { Theme(rawValue: UserDefaults.standard.string(forKey: themeKey) ?? "") ?? .system }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: themeKey) }
    }

    static var profile: Profile {
        get { Profile(rawValue: UserDefaults.standard.string(forKey: profileKey) ?? "") ?? .compact }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: profileKey) }
    }

    static var fontSize: Int {
        get {
            let stored = UserDefaults.standard.object(forKey: fontSizeKey) as? Int ?? defaultFontSize
            return stored.clamped(to: fontSizeRange)
        }
        set { UserDefaults.standard.set(newValue.clamped(to: fontSizeRange), forKey: fontSizeKey) }
    }
}

extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(range.upperBound, Swift.max(range.lowerBound, self))
    }
}
