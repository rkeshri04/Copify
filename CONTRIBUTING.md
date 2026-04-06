# Contributing to Copify

Thanks for your interest in contributing! Copify is a simple, lightweight macOS menu bar app, and contributions are welcome—whether you're fixing a bug, adding a feature, or improving the code.

## Getting Started

Copify is a pure Swift app using native AppKit APIs. No external dependencies, no Electron—just standard macOS frameworks.

### Setup

1. **Clone the repo:**
   ```bash
   git clone https://github.com/rkeshri04/copify.git
   ```

2. **Open in Xcode:**
   Open `Copify.xcodeproj` in Xcode.

3. **Run:**
   Select your Mac as the destination and press `Cmd + R`.

## Project Structure

| File | Purpose |
|------|---------|
| `main.swift` + `AppDelegate.swift` | App entry point, runs as menu bar accessory |
| `ClipboardManager.swift` | Watches `NSPasteboard` for clipboard changes |
| `MenuController.swift` | Builds and renders the dropdown menu |
| `PinStorage.swift` | Persists pinned items to `UserDefaults` |
| `LoginItemManager.swift` | Handles "Launch at Login" functionality |

## How to Contribute

### Reporting Bugs
Open an [issue](https://github.com/rkeshri04/copify/issues) with details: macOS version, steps to reproduce, what you copied.

### Suggesting Features
Before writing code, open an issue to discuss your idea. We want to keep Copify simple and fast.

### Submitting Pull Requests

1. Fork the repo and create a branch from `main`
2. Keep PRs focused—fix bug OR add feature, not both
3. Test locally before submitting
4. Open a pull request

## Code Style

- Keep Swift code clean and native
- Comment tricky AppKit behavior
- Don't over-engineer—a simple solution beats a complex one
