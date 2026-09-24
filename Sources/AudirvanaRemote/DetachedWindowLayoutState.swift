import Foundation

/// Drives progressive section collapsing as the detached window is resized: it jumps between
/// fixed-size steps (Album Tracks, then Player, then Text, then the compact Minify layout)
/// rather than resizing continuously.
final class DetachedWindowLayoutState: ObservableObject {
    @Published var showAlbumTracksSection = true
    @Published var showPlayerSection = true
    @Published var showTextSection = true
    @Published var isMinified = false

    static let fullHeight: CGFloat = 480
    static let noTracksHeight: CGFloat = 445
    static let noPlayerHeight: CGFloat = 308
    static let noTextHeight: CGFloat = 228
    static let miniHeight: CGFloat = 72
    /// Extra room needed at the "full" detent when the Album Tracks disclosure is expanded,
    /// so its scrollable list isn't clipped. Not one of the drag-snapped detents.
    static let tracksExpandedHeight: CGFloat = fullHeight + 170

    /// The five discrete heights the detached window is allowed to snap to, largest first.
    static let detents: [CGFloat] = [fullHeight, noTracksHeight, noPlayerHeight, noTextHeight, miniHeight]

    /// Sets section visibility to match one of the discrete `detents` heights.
    func apply(height: CGFloat) {
        isMinified = height < Self.noTextHeight
        showAlbumTracksSection = height >= Self.fullHeight
        showPlayerSection = height >= Self.noTracksHeight
        showTextSection = height >= Self.noPlayerHeight
    }
}
