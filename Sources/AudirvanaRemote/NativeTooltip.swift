import AppKit
import SwiftUI

/// Sets a real AppKit tooltip (NSView.toolTip) rather than SwiftUI's `.help()`, which doesn't
/// reliably display inside a MenuBarExtra popover.
private struct TooltipView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.toolTip = text
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.toolTip = text
    }
}

extension View {
    func nativeTooltip(_ text: String) -> some View {
        background(TooltipView(text: text))
    }
}
