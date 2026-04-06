import Foundation

/// Persists pinned clipboard items using UserDefaults.
final class PinStorage {
    private let key = "com.copify.pinned"

    /// Loads pinned items from storage.
    func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    /// Saves pinned items to storage.
    func save(_ items: [String]) {
        UserDefaults.standard.set(items, forKey: key)
    }
}
