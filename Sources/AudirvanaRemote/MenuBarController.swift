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

        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true
        pop.contentViewController = NSHostingController(
            rootView: RemoteView(controller: controller, showsDetachButton: true)
        )
        popover = pop

        // Start hidden unless Audirvana already happens to be running at launch — the
        // remote is resident (see AppDelegate's login-item registration) but should only
        // be visibly "on" while there's an Audirvana Origin to control.
        setVisible(controller.isRunning)
    }

    /// Shows/hides the menu bar item to track Audirvana Origin's own running state — this is
    /// what makes the remote appear to "start and stop with" Audirvana, without actually
    /// launching or killing this (lightweight, always-resident) process. Actually adds/removes
    /// the NSStatusItem rather than toggling `isVisible` on a standing one: a status item
    /// created invisible (as this one is, at launch, most of the time) does not reliably
    /// reserve a menu bar slot it can later become visible in — recreating it on each
    /// transition is what AppKit's own status-item APIs expect for on/off use.
    func setVisible(_ visible: Bool) {
        guard visible != (statusItem != nil) else { return }
        if visible {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            item.button?.image = NSImage(systemSymbolName: "hifispeaker.fill", accessibilityDescription: "Audirvana Remote")
            item.button?.target = self
            item.button?.action = #selector(toggle(_:))
            statusItem = item
        } else {
            hidePopover()
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
            }
            statusItem = nil
        }
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
