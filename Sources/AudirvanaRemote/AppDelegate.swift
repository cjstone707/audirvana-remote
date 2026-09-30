import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = AudirvanaController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registerAsLoginItemIfNeeded()
        controller.hideAudirvana()
        // Defensive: close any window the placeholder Settings scene might auto-open —
        // BEFORE creating the status item, not after. NSStatusItem is itself backed by a
        // scene/window in this AppKit version (visible in Console as
        // "com.apple.appkit.status-items:<uuid>" / NSMenuBarNavigationSceneExtension), so
        // running this sweep after setup() was closing the status item's own window right
        // after creating it: the icon kept rendering (a compositor artifact) but its window
        // was dead, so it silently swallowed every click — no crash, no log, nothing.
        // Deferring the whole launch sequence into this async block still lets the
        // placeholder Settings window (if any) finish opening first, so it's still there
        // to be swept, while guaranteeing the status item is created afterward, not before.
        DispatchQueue.main.async { [self] in
            NSApp.windows.forEach { $0.close() }
            // Set up the menu bar item (and its initial visibility, matched to whether
            // Audirvana is running yet) before polling starts, so the very first refresh()
            // has something to show/hide rather than racing the item's creation.
            MenuBarController.shared.setup(controller: controller)
            controller.startPolling()
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
