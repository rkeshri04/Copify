import Cocoa
import AppKit

/// Monitors the system clipboard for changes and maintains history.
final class ClipboardManager {
    private let maxHistory = 20
    private let maxPinned = 8
    /// Fallback poll interval – used only as a safety net in case the
    /// distributed notification is not delivered (e.g. sandboxing edge-cases).
    private let fallbackPollInterval: TimeInterval = 1.0

    private(set) var history: [String] = []
    private(set) var pinned: [String] = []
    var onChange: (() -> Void)?

    private var lastCount: Int = 0
    private var lastText: String = ""
    private var timer: Timer?
    private var notificationObserver: Any?
    private let storage = PinStorage()

    init() {
        pinned = storage.load()
        lastCount = NSPasteboard.general.changeCount
    }

    deinit {
        stopMonitoring()
    }

    /// Starts clipboard monitoring.
    ///
    /// Uses `DistributedNotificationCenter` to react the instant the clipboard
    /// changes, with a slow fallback timer for robustness.
    func startMonitoring() {
        // React immediately via system notification.
        notificationObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.pasteboard.changed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.poll()
        }

        // Safety-net timer in case the notification is missed.
        timer = Timer.scheduledTimer(withTimeInterval: fallbackPollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    /// Stops clipboard monitoring.
    func stopMonitoring() {
        if let observer = notificationObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
            notificationObserver = nil
        }
        timer?.invalidate()
        timer = nil
    }

    /// Copies text to the clipboard and updates history.
    func copyToClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)

        lastText = text
        lastCount = pb.changeCount

        if !pinned.contains(text) {
            history.removeAll { $0 == text }
            history.insert(text, at: 0)
        }

        onChange?()
    }

    /// Pins a text item from history.
    func pin(_ text: String) {
        guard !pinned.contains(text), pinned.count < maxPinned else { return }

        history.removeAll { $0 == text }
        pinned.insert(text, at: 0)
        storage.save(pinned)
        onChange?()
    }

    /// Unpins a text item, moving it back to history.
    func unpin(_ text: String) {
        guard pinned.contains(text) else { return }

        pinned.removeAll { $0 == text }
        storage.save(pinned)
        history.insert(text, at: 0)
        onChange?()
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastCount else { return }
        lastCount = pb.changeCount

        guard let text = pb.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }

        guard text != lastText else { return }
        lastText = text

        guard !pinned.contains(text) else { return }

        history.removeAll { $0 == text }
        history.insert(text, at: 0)

        if history.count > maxHistory {
            history.removeLast()
        }

        onChange?()
    }
}
