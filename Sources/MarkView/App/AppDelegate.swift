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

    @objc func selectAppearanceOption(_ sender: NSMenuItem) {
        guard let identifier = sender.menu?.identifier else { return }
        switch identifier {
        case MenuID.theme:
            AppearanceStore.theme = Theme(rawValue: sender.representedObject as? String ?? "") ?? .system
        case MenuID.skin:
            AppearanceStore.skin = Skin(rawValue: sender.representedObject as? String ?? "") ?? .github
        case MenuID.profile:
            AppearanceStore.profile = Profile(rawValue: sender.representedObject as? String ?? "") ?? .compact
        case MenuID.width:
            AppearanceStore.contentWidth = sender.representedObject as? Int ?? AppearanceStore.defaultContentWidth
        default:
            guard let target = accentTarget(for: identifier) else { return }
            AppearanceStore.setAccent(
                AccentColor(rawValue: sender.representedObject as? String ?? ""),
                for: target
            )
        }
        controllers.forEach { $0.render() }
    }

    private func accentTarget(for identifier: NSUserInterfaceItemIdentifier) -> AccentTarget? {
        AccentTarget.allCases.first { MenuID.accent($0) == identifier }
    }

    private func currentValue(for identifier: NSUserInterfaceItemIdentifier) -> Any? {
        switch identifier {
        case MenuID.theme: return AppearanceStore.theme.rawValue
        case MenuID.skin: return AppearanceStore.skin.rawValue
        case MenuID.profile: return AppearanceStore.profile.rawValue
        case MenuID.width: return AppearanceStore.contentWidth
        default:
            guard let target = accentTarget(for: identifier) else { return nil }
            return AppearanceStore.accent(for: target)?.rawValue ?? "off"
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let identifier = menu.identifier, let current = currentValue(for: identifier) else { return }
        for item in menu.items {
            let matches: Bool
            if let value = item.representedObject as? String, let selected = current as? String {
                matches = value == selected
            } else if let value = item.representedObject as? Int, let selected = current as? Int {
                matches = value == selected
            } else {
                matches = false
            }
            item.state = matches ? .on : .off
        }
    }
}
