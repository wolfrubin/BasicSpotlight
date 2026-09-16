import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyManager: HotKeyManager?
    private let searchWindowController = SearchWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotKeyManager = HotKeyManager { [weak self] in
            self?.searchWindowController.toggle()
        }
    }
}
