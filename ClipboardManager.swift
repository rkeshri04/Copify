import Cocoa
import AppKit

/// Monitors the system clipboard for changes and maintains history.
final class ClipboardManager {
    private let maxHistory = 20
    private let maxPinned = 8
    private let pollInterval: TimeInterval = 0.25

    private(set) var history: [String] = []
    private(set) var pinned: [String] = []
    var onChange: (() -> Void)?

    private var lastCount: Int = 0
    private var lastText: String = ""
    private var timer: Timer?
    private let storage = PinStorage()

    init() {
        pinned = storage.load()
        lastCount = NSPasteboard.general.changeCount
    }

    deinit {
        stopMonitoring()
    }

    /// Starts polling the clipboard for changes.
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    /// Stops polling the clipboard.
    func stopMonitoring() {
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
