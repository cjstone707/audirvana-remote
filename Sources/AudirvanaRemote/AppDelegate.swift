import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = AudirvanaController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registerAsLoginItemIfNeeded()
        controller.hideAudirvana()
        // Set up the menu bar item (and its initial visibility, matched to whether
        // Audirvana is running yet) before polling starts, so the very first refresh()
        // has something to show/hide rather than racing the item's creation.
        MenuBarController.shared.setup(controller: controller)
        controller.startPolling()
        // Defensive: close any window the placeholder Settings scene might auto-open.
        DispatchQueue.main.async {
            NSApp.windows.forEach { $0.close() }
        }
    }

    /// Runs at every login so the remote is resident and ready the moment Audirvana
    /// launches — it stays invisible (see MenuBarController/AudirvanaController) until then.
    private func registerAsLoginItemIfNeeded() {
        guard SMAppService.mainApp.status != .enabled else { return }
        do {
            try SMAppService.mainApp.register()
        } catch {
            NSLog("AudirvanaRemote: failed to register as login item: \(error)")
        }
    }
}
