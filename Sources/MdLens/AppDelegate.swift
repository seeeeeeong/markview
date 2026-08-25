import AppKit
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controllers: [ViewerWindowController] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        // Launched bare (no file): offer the open panel.
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
        if let existing = controllers.first(where: {
            $0.window?.representedURL?.standardizedFileURL == standardized
        }) {
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

    // MARK: - Menu

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

    @objc func setThemeSystem(_ sender: Any?) { setTheme(.system) }
    @objc func setThemeLight(_ sender: Any?) { setTheme(.light) }
    @objc func setThemeDark(_ sender: Any?) { setTheme(.dark) }

    private func setTheme(_ theme: ThemePreference) {
        Settings.theme = theme
        controllers.forEach { $0.render() }
    }

    @objc func setProfileCompact(_ sender: Any?) { setProfile("compact") }
    @objc func setProfileSpacious(_ sender: Any?) { setProfile("spacious") }

    private func setProfile(_ profile: String) {
        Settings.profile = profile
        controllers.forEach { $0.render() }
    }

    private func buildMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "About MdLens", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide MdLens", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit MdLens", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu
        fileMenu.addItem(withTitle: "Open…", action: #selector(showOpenPanel(_:)), keyEquivalent: "o")
        fileMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu

        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        let themeMenu = NSMenu(title: "Theme")
        themeItem.submenu = themeMenu
        themeMenu.addItem(makeCheckedItem("System", #selector(setThemeSystem(_:)), checked: Settings.theme == .system))
        themeMenu.addItem(makeCheckedItem("Light", #selector(setThemeLight(_:)), checked: Settings.theme == .light))
        themeMenu.addItem(makeCheckedItem("Dark", #selector(setThemeDark(_:)), checked: Settings.theme == .dark))
        themeMenu.delegate = self
        viewMenu.addItem(themeItem)

        let profileItem = NSMenuItem(title: "Profile", action: nil, keyEquivalent: "")
        let profileMenu = NSMenu(title: "Profile")
        profileItem.submenu = profileMenu
        profileMenu.addItem(makeCheckedItem("Compact", #selector(setProfileCompact(_:)), checked: Settings.profile == "compact"))
        profileMenu.addItem(makeCheckedItem("Spacious", #selector(setProfileSpacious(_:)), checked: Settings.profile == "spacious"))
        profileMenu.delegate = self
        viewMenu.addItem(profileItem)

        viewMenu.addItem(.separator())
        viewMenu.addItem(withTitle: "Reload", action: #selector(ViewerWindowController.reloadDocument(_:)), keyEquivalent: "r")
        viewMenu.addItem(withTitle: "Bigger Text", action: #selector(ViewerWindowController.increaseFontSize(_:)), keyEquivalent: "+")
        viewMenu.addItem(withTitle: "Smaller Text", action: #selector(ViewerWindowController.decreaseFontSize(_:)), keyEquivalent: "-")
        viewMenu.addItem(withTitle: "Actual Text Size", action: #selector(ViewerWindowController.resetFontSize(_:)), keyEquivalent: "0")

        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
    }

    private func makeCheckedItem(_ title: String, _ action: Selector, checked: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.state = checked ? .on : .off
        return item
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        for item in menu.items {
            switch item.action {
            case #selector(setThemeSystem(_:)): item.state = Settings.theme == .system ? .on : .off
            case #selector(setThemeLight(_:)): item.state = Settings.theme == .light ? .on : .off
            case #selector(setThemeDark(_:)): item.state = Settings.theme == .dark ? .on : .off
            case #selector(setProfileCompact(_:)): item.state = Settings.profile == "compact" ? .on : .off
            case #selector(setProfileSpacious(_:)): item.state = Settings.profile == "spacious" ? .on : .off
            default: break
            }
        }
    }
}
