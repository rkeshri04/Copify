import Cocoa

// Application entry point
// NSApplication.shared provides access to the singleton app instance
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
