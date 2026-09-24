import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = AudirvanaController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller.hideAudirvana()
        controller.startPolling()
        MenuBarController.shared.setup(controller: controller)
        // Defensive: close any window the placeholder Settings scene might auto-open.
        DispatchQueue.main.async {
            NSApp.windows.forEach { $0.close() }
        }
    }
}
