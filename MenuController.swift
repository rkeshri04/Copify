import Cocoa

/// Manages the menu bar status item and its dropdown menu.
final class MenuController: NSObject, NSSearchFieldDelegate {
    private enum Constants {
        static let width: CGFloat = 245
        static let searchHeight: CGFloat = 22
        static let rowHeight: CGFloat = 24
        static let maxLen = 38
    }

    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let searchField = NSSearchField()
    private weak var cm: ClipboardManager?

    init(clipboardManager: ClipboardManager) {
        self.cm = clipboardManager
        super.init()
        setupStatusItem()
        setupMenu()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem.button else { return }

        if let icon = NSImage(named: "MenuBarIcon") {
            icon.isTemplate = false
            icon.size = NSSize(width: 18, height: 18)
            button.image = icon
            button.imageScaling = .scaleProportionallyDown
        } else if let icon = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Copify") {
            icon.isTemplate = true
            button.image = icon
        } else {
            button.title = "📋"
        }

        statusItem.menu = menu
    }

    private func setupMenu() {
        menu.minimumWidth = Constants.width

        searchField.placeholderString = "Search clipboard…"
        searchField.delegate = self
        searchField.frame = NSRect(x: 8, y: 4, width: Constants.width - 16, height: Constants.searchHeight)

        let wrapper = NSView(frame: NSRect(x: 0, y: 0, width: Constants.width, height: 30))
        wrapper.addSubview(searchField)

        let searchItem = NSMenuItem()
        searchItem.view = wrapper
        menu.addItem(searchItem)
        menu.addItem(.separator())

        rebuild()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuWillOpen),
            name: NSMenu.didBeginTrackingNotification,
            object: menu
        )
    }

    /// Rebuilds the menu with current clipboard data and search filter.
    func rebuild() {
        while menu.items.count > 2 {
            menu.removeItem(at: 2)
        }

        let query = searchField.stringValue.lowercased()
        guard let cm else { return }

        let pinned = filter(cm.pinned, query: query)
        let history = filter(cm.history, query: query)

        if !pinned.isEmpty {
            menu.addItem(sectionHeader("Pinned"))
            for text in pinned {
                menu.addItem(makeItem("★ " + text, action: #selector(onCopy(_:)), rep: text))
            }
            menu.addItem(.separator())
        }

        if !history.isEmpty {
            menu.addItem(sectionHeader("Recent"))
            for text in history {
                menu.addItem(makeItem(text, action: #selector(onCopy(_:)), rep: text))
            }
        } else if pinned.isEmpty {
            let empty = NSMenuItem(
                title: query.isEmpty ? "Clipboard empty" : "No matches",
                action: nil,
                keyEquivalent: ""
            )
            empty.isEnabled = false
            menu.addItem(empty)
        }

        menu.addItem(.separator())
        addPinMenu(from: cm)
        addUnpinMenu(from: cm)
        menu.addItem(.separator())
        addLoginItem()
        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit Copify",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quit)
    }

    func controlTextDidChange(_ obj: Notification) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            rebuild()
        }
        menu.update()
    }

    @objc private func menuWillOpen() {
        DispatchQueue.main.async {
            self.searchField.window?.makeFirstResponder(self.searchField)
        }
    }

    @objc private func onCopy(_ sender: MenuRowView) {
        guard let text = sender.representedObject as? String else { return }
        cm?.copyToClipboard(text)
        menu.cancelTracking()
    }

    @objc private func onPin(_ sender: MenuRowView) {
        guard let text = sender.representedObject as? String else { return }
        cm?.pin(text)
    }

    @objc private func onUnpin(_ sender: MenuRowView) {
        guard let text = sender.representedObject as? String else { return }
        cm?.unpin(text)
    }

    @objc private func onToggleLogin() {
        LoginItemManager.toggle()
        rebuild()
    }

    private func filter(_ items: [String], query: String) -> [String] {
        guard !query.isEmpty else { return items }
        return items.filter { $0.lowercased().contains(query) }
    }

    private func makeItem(_ label: String, action: Selector, rep: String) -> NSMenuItem {
        let item = NSMenuItem()
        let view = MenuRowView(text: truncate(label), width: Constants.width)
        view.action = action
        view.target = self
        view.representedObject = rep
        item.view = view
        return item
    }

    private func truncate(_ text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
        return cleaned.count <= Constants.maxLen ? cleaned : String(cleaned.prefix(Constants.maxLen - 3)) + "..."
    }

    private func sectionHeader(_ title: String) -> NSMenuItem {
        if #available(macOS 14.0, *) {
            return NSMenuItem.sectionHeader(title: title)
        }
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func addPinMenu(from cm: ClipboardManager) {
        let submenu = NSMenu()
        submenu.minimumWidth = Constants.width

        if cm.pinned.count >= cm.maxPinned {
            submenu.addItem(disabled("Pin limit reached (\(cm.maxPinned))"))
        } else if !cm.history.isEmpty {
            cm.history.forEach { text in
                submenu.addItem(makeItem(text, action: #selector(onPin(_:)), rep: text))
            }
        } else {
            submenu.addItem(disabled("No recent items to pin"))
        }

        menu.addItem(withTitle: "Pin Recent Item", submenu: submenu)
    }

    private func addUnpinMenu(from cm: ClipboardManager) {
        let submenu = NSMenu()
        submenu.minimumWidth = Constants.width

        if !cm.pinned.isEmpty {
            cm.pinned.forEach { text in
                submenu.addItem(makeItem("★ " + text, action: #selector(onUnpin(_:)), rep: text))
            }
        } else {
            submenu.addItem(disabled("No pinned items"))
        }

        menu.addItem(withTitle: "Unpin Starred Item", submenu: submenu)
    }

    private func addLoginItem() {
        let title = LoginItemManager.isEnabled ? "✓ Launch at Login" : "Launch at Login"
        let item = NSMenuItem(title: title, action: #selector(onToggleLogin), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }
}

/// Custom view for menu items with hover highlighting.
final class MenuRowView: NSView {
    private let label = NSTextField()

    var action: Selector?
    weak var target: AnyObject?
    var representedObject: Any?

    init(text: String, width: CGFloat) {
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: Constants.rowHeight))

        wantsLayer = true
        layer?.cornerRadius = 4

        label.stringValue = text
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.font = NSFont.systemFont(ofSize: 13)
        label.frame = NSRect(x: 10, y: 3, width: width - 20, height: 18)
        addSubview(label)

        let tracking = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(tracking)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    override func mouseDown(with event: NSEvent) {
        guard let action, let target else { return }
        NSApp.sendAction(action, to: target, from: self)
    }
}

extension NSMenu {
    @discardableResult
    func addItem(withTitle title: String, submenu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        addItem(item)
        return item
    }
}
