import AppKit

enum MenuID {
    static let theme = NSUserInterfaceItemIdentifier("theme")
    static let skin = NSUserInterfaceItemIdentifier("skin")
    static let profile = NSUserInterfaceItemIdentifier("profile")
    static let width = NSUserInterfaceItemIdentifier("width")

    static func accent(_ target: AccentTarget) -> NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier("accent.\(target.rawValue)")
    }
}

enum MainMenuBuilder {
    static func build(for delegate: AppDelegate) -> NSMenu {
        let mainMenu = NSMenu()
        mainMenu.addItem(appMenuItem())
        mainMenu.addItem(fileMenuItem())
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

    private static func fileMenuItem() -> NSMenuItem {
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

        menu.addItem(optionSubmenu(
            title: "Theme",
            identifier: MenuID.theme,
            options: Theme.allCases.map { ($0.rawValue.capitalized, $0.rawValue) },
            delegate: delegate
        ))
        menu.addItem(optionSubmenu(
            title: "Style",
            identifier: MenuID.skin,
            options: Skin.allCases.map { ($0.displayName, $0.rawValue) },
            delegate: delegate
        ))
        menu.addItem(optionSubmenu(
            title: "Profile",
            identifier: MenuID.profile,
            options: Profile.allCases.map { ($0.rawValue.capitalized, $0.rawValue) },
            delegate: delegate
        ))
        menu.addItem(widthSubmenu(delegate))
        menu.addItem(accentSubmenu(delegate))

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

    private static func widthSubmenu(_ delegate: AppDelegate) -> NSMenuItem {
        var options = AppearanceStore.contentWidthChoices.map { ("\($0) px", $0) }
        options.append(("Full Width", AppearanceStore.fullWidth))
        return optionSubmenu(
            title: "Content Width",
            identifier: MenuID.width,
            options: options,
            delegate: delegate
        )
    }

    private static func accentSubmenu(_ delegate: AppDelegate) -> NSMenuItem {
        let item = NSMenuItem(title: "Accent Colors", action: nil, keyEquivalent: "")
        let menu = NSMenu(title: "Accent Colors")
        for target in AccentTarget.allCases {
            var options = [("Off", "off")]
            options += AccentColor.allCases.map { ($0.displayName, $0.rawValue) }
            menu.addItem(optionSubmenu(
                title: target.displayName,
                identifier: MenuID.accent(target),
                options: options,
                delegate: delegate
            ))
        }
        item.submenu = menu
        return item
    }

    private static func optionSubmenu<Value>(
        title: String,
        identifier: NSUserInterfaceItemIdentifier,
        options: [(label: String, value: Value)],
        delegate: AppDelegate
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        menu.identifier = identifier
        menu.delegate = delegate
        for option in options {
            let optionItem = NSMenuItem(
                title: option.label,
                action: #selector(AppDelegate.selectAppearanceOption(_:)),
                keyEquivalent: ""
            )
            optionItem.representedObject = option.value
            menu.addItem(optionItem)
        }
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
