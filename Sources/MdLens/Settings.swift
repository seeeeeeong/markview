import AppKit

enum ThemePreference: String {
    case system, light, dark

    /// Resolved renderer theme ("light" / "dark") for the current system appearance.
    var resolved: String {
        switch self {
        case .light: return "light"
        case .dark: return "dark"
        case .system:
            let appearance = NSApp.effectiveAppearance
            let match = appearance.bestMatch(from: [.darkAqua, .aqua])
            return match == .darkAqua ? "dark" : "light"
        }
    }
}

enum Settings {
    private static let themeKey = "themePreference"
    private static let profileKey = "renderProfile"

    static var theme: ThemePreference {
        get {
            ThemePreference(rawValue: UserDefaults.standard.string(forKey: themeKey) ?? "") ?? .system
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: themeKey) }
    }

    static var profile: String {
        get {
            let value = UserDefaults.standard.string(forKey: profileKey)
            return value == "spacious" ? "spacious" : "compact"
        }
        set { UserDefaults.standard.set(newValue, forKey: profileKey) }
    }
}
