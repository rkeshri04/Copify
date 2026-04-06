import ServiceManagement

/// Manages the app's login item for launching at system startup.
enum LoginItemManager {
    /// Whether the app is set to launch at login.
    static var isEnabled: Bool {
        guard #available(macOS 13.0, *) else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    /// Toggles the login item on or off.
    static func toggle() {
        guard #available(macOS 13.0, *) else { return }

        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Login item toggle failed: \(error.localizedDescription)")
        }
    }
}
