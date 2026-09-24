import AppKit
import SwiftUI

/// Owns the menu bar status item and its popover. Uses NSPopover (with `.transient` behavior)
/// rather than a hand-rolled NSPanel + event monitor, which produced a runaway show/hide
/// feedback loop when the panel was dismissed while the status item's own click tracking was
/// still active. NSPopover's built-in outside-click handling is the standard, well-tested
/// mechanism for exactly this status-item-anchored use case.
final class MenuBarController: NSObject {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var controller: AudirvanaController?

    func setup(controller: AudirvanaController) {
        self.controller = controller

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "hifispeaker.fill", accessibilityDescription: "Audirvana Remote")
        item.button?.target = self
        item.button?.action = #selector(toggle(_:))
        statusItem = item

        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true
        pop.contentViewController = NSHostingController(
            rootView: RemoteView(controller: controller, showsDetachButton: true)
        )
        popover = pop
    }

    func hidePopover() {
        popover?.performClose(nil)
    }

    @objc private func toggle(_ sender: AnyObject?) {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
