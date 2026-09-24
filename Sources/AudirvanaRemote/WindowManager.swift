import AppKit
import SwiftUI

/// Owns the detached remote window's lifecycle. Built with AppKit directly rather than
/// SwiftUI's `openWindow`, which does not reliably fire from inside a MenuBarExtra popover.
final class WindowManager {
    static let shared = WindowManager()

    private var window: NSWindow?
    let layoutState = DetachedWindowLayoutState()

    private static let contentWidth: CGFloat = 272

    func showDetachedWindow(controller: AudirvanaController) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        layoutState.apply(height: DetachedWindowLayoutState.fullHeight)

        let hosting = NSHostingController(
            rootView: RemoteView(
                controller: controller,
                showsDetachButton: false,
                layoutState: layoutState,
                isResizeDriven: true
            )
        )
        // Auto-tracking would otherwise snap the window back to fit its content on every
        // frame, fighting any attempt to drag it smaller. We resize it explicitly instead.
        hosting.sizingOptions = []

        let newWindow = NSWindow(contentViewController: hosting)
        newWindow.title = "Audirvana Remote"
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        newWindow.isReleasedWhenClosed = false
        newWindow.level = .floating
        newWindow.collectionBehavior.insert(.fullScreenAuxiliary)
        // Lock width so only vertical dragging is possible. The max height allows extra
        // room beyond the "full" detent for the Album Tracks disclosure's expanded list,
        // which is resized into explicitly (see resizeForExpandedTracks) rather than being
        // one of the drag-snapped detents.
        newWindow.contentMinSize = NSSize(width: Self.contentWidth, height: DetachedWindowLayoutState.miniHeight)
        newWindow.contentMaxSize = NSSize(width: Self.contentWidth, height: DetachedWindowLayoutState.tracksExpandedHeight)
        newWindow.setContentSize(NSSize(width: Self.contentWidth, height: DetachedWindowLayoutState.fullHeight))
        newWindow.center()
        newWindow.delegate = WindowObserver.shared

        window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeDetachedWindow() {
        window?.close()
    }

    func resizeDetachedWindow(toMinified minified: Bool) {
        let target = minified ? DetachedWindowLayoutState.miniHeight : DetachedWindowLayoutState.fullHeight
        setContentHeight(target)
        layoutState.apply(height: target)
    }

    /// Grows/shrinks the window to fit the Album Tracks disclosure's expanded list, independent
    /// of the drag-snapped detents (only meaningful while at the "full" detent).
    func resizeForExpandedTracks(_ expanded: Bool) {
        let target = expanded ? DetachedWindowLayoutState.tracksExpandedHeight : DetachedWindowLayoutState.fullHeight
        setContentHeight(target)
    }

    fileprivate func windowDidClose() {
        window = nil
    }

    /// Snaps a live-drag's proposed height to the nearest discrete section detent.
    fileprivate func snappedContentHeight(forProposed proposed: CGFloat) -> CGFloat {
        DetachedWindowLayoutState.detents.min(by: { abs($0 - proposed) < abs($1 - proposed) })
            ?? DetachedWindowLayoutState.fullHeight
    }

    fileprivate func chromeHeight(for window: NSWindow) -> CGFloat {
        window.frame.height - window.contentLayoutRect.height
    }

    fileprivate func didSettle(atContentHeight height: CGFloat) {
        layoutState.apply(height: height)
    }

    private func setContentHeight(_ target: CGFloat) {
        guard let window else { return }
        let currentFrame = window.frame
        let chrome = chromeHeight(for: window)
        let newHeight = target + chrome
        let top = currentFrame.maxY
        let newFrame = NSRect(
            x: currentFrame.minX,
            y: top - newHeight,
            width: currentFrame.width,
            height: newHeight
        )
        window.setFrame(newFrame, display: true, animate: true)
    }
}

private final class WindowObserver: NSObject, NSWindowDelegate {
    static let shared = WindowObserver()

    func windowWillClose(_ notification: Notification) {
        WindowManager.shared.windowDidClose()
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let chrome = WindowManager.shared.chromeHeight(for: sender)
        let proposedContentHeight = frameSize.height - chrome
        let snapped = WindowManager.shared.snappedContentHeight(forProposed: proposedContentHeight)
        return NSSize(width: frameSize.width, height: snapped + chrome)
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        WindowManager.shared.didSettle(atContentHeight: window.contentLayoutRect.height)
    }
}
