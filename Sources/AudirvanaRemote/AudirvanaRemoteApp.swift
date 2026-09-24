import SwiftUI

@main
struct AudirvanaRemoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No SwiftUI-managed windows — the menu bar item and its panel are owned by
        // MenuBarController (AppKit), set up from AppDelegate. A Scene is still required;
        // AppDelegate defensively closes anything this one might auto-open at launch.
        Settings {
            EmptyView()
        }
    }
}
