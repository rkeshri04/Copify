import Cocoa

/// Application delegate that initializes the app as a menu bar accessory.
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuController: MenuController?
    private var clipboardManager: ClipboardManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupApp()
        }
    }

    private func setupApp() {
        clipboardManager = ClipboardManager()

        guard let clipboardManager else { return }

        menuController = MenuController(clipboardManager: clipboardManager)
        clipboardManager.onChange = { [weak self] in
            self?.menuController?.rebuild()
        }
        clipboardManager.startMonitoring()
    }
}
