import AppKit
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controllers: [ViewerWindowController] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenuBuilder.build(for: self)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        showOpenPanel(nil)
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach(openDocument(at:))
    }

    func openDocument(at url: URL) {
        let standardized = url.standardizedFileURL
        if let existing = controllers.first(where: { $0.fileURL == standardized }) {
            existing.window?.makeKeyAndOrderFront(nil)
            return
        }
        let controller = ViewerWindowController(fileURL: standardized)
        controllers.append(controller)
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: controller.window,
            queue: .main
        ) { [weak self, weak controller] _ in
            self?.controllers.removeAll { $0 === controller }
        }
        controller.showWindow(nil)
    }

    @objc func showOpenPanel(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        if let markdown = UTType(filenameExtension: "md") {
            panel.allowedContentTypes = [markdown, .plainText]
        }
        panel.begin { [weak self] response in
            guard response == .OK else { return }
            panel.urls.forEach { self?.openDocument(at: $0) }
        }
    }

    @objc func setThemeSystem(_ sender: Any?) { applyTheme(.system) }
    @objc func setThemeLight(_ sender: Any?) { applyTheme(.light) }
    @objc func setThemeDark(_ sender: Any?) { applyTheme(.dark) }
    @objc func setProfileCompact(_ sender: Any?) { applyProfile(.compact) }
    @objc func setProfileSpacious(_ sender: Any?) { applyProfile(.spacious) }

    private func applyTheme(_ theme: Theme) {
        AppearanceStore.theme = theme
        rerenderAll()
    }

    private func applyProfile(_ profile: Profile) {
        AppearanceStore.profile = profile
        rerenderAll()
    }

    private func rerenderAll() {
        controllers.forEach { $0.render() }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        for item in menu.items {
            switch item.action {
            case #selector(setThemeSystem(_:)): item.state = state(AppearanceStore.theme == .system)
            case #selector(setThemeLight(_:)): item.state = state(AppearanceStore.theme == .light)
            case #selector(setThemeDark(_:)): item.state = state(AppearanceStore.theme == .dark)
            case #selector(setProfileCompact(_:)): item.state = state(AppearanceStore.profile == .compact)
            case #selector(setProfileSpacious(_:)): item.state = state(AppearanceStore.profile == .spacious)
            default: break
            }
        }
    }

    private func state(_ isOn: Bool) -> NSControl.StateValue {
        isOn ? .on : .off
    }
}
