import AppKit

enum MainMenuBuilder {
    static func build(for delegate: AppDelegate) -> NSMenu {
        let mainMenu = NSMenu()
        mainMenu.addItem(appMenuItem())
        mainMenu.addItem(fileMenuItem(delegate))
        mainMenu.addItem(editMenuItem())
        mainMenu.addItem(viewMenuItem(delegate))
        mainMenu.addItem(windowMenuItem())
        return mainMenu
    }

    private static func appMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu()
        menu.addItem(
            withTitle: "About MarkView",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        menu.addItem(.separator())
        menu.addItem(withTitle: "Hide MarkView", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        menu.addItem(withTitle: "Quit MarkView", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = menu
        return item
    }

    private static func fileMenuItem(_ delegate: AppDelegate) -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "File")
        menu.addItem(withTitle: "Open…", action: #selector(AppDelegate.showOpenPanel(_:)), keyEquivalent: "o")
        menu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        item.submenu = menu
        return item
    }

    private static func editMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Edit")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        item.submenu = menu
        return item
    }

    private static func viewMenuItem(_ delegate: AppDelegate) -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "View")

        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        let themeMenu = NSMenu(title: "Theme")
        themeMenu.addItem(withTitle: "System", action: #selector(AppDelegate.setThemeSystem(_:)), keyEquivalent: "")
        themeMenu.addItem(withTitle: "Light", action: #selector(AppDelegate.setThemeLight(_:)), keyEquivalent: "")
        themeMenu.addItem(withTitle: "Dark", action: #selector(AppDelegate.setThemeDark(_:)), keyEquivalent: "")
        themeMenu.delegate = delegate
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)

        let profileItem = NSMenuItem(title: "Profile", action: nil, keyEquivalent: "")
        let profileMenu = NSMenu(title: "Profile")
        profileMenu.addItem(withTitle: "Compact", action: #selector(AppDelegate.setProfileCompact(_:)), keyEquivalent: "")
        profileMenu.addItem(withTitle: "Spacious", action: #selector(AppDelegate.setProfileSpacious(_:)), keyEquivalent: "")
        profileMenu.delegate = delegate
        profileItem.submenu = profileMenu
        menu.addItem(profileItem)

        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Reload",
            action: #selector(ViewerWindowController.reloadDocument(_:)),
            keyEquivalent: "r"
        )
        menu.addItem(
            withTitle: "Bigger Text",
            action: #selector(ViewerWindowController.increaseFontSize(_:)),
            keyEquivalent: "+"
        )
        menu.addItem(
            withTitle: "Smaller Text",
            action: #selector(ViewerWindowController.decreaseFontSize(_:)),
            keyEquivalent: "-"
        )
        menu.addItem(
            withTitle: "Actual Text Size",
            action: #selector(ViewerWindowController.resetFontSize(_:)),
            keyEquivalent: "0"
        )
        item.submenu = menu
        return item
    }

    private static func windowMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Window")
        menu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        NSApp.windowsMenu = menu
        item.submenu = menu
        return item
    }
}
