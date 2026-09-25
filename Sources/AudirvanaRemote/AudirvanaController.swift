import AppKit
import Foundation

/// Wraps the Audirvana Origin AppleScript dictionary (Audirvana.sdef) via Apple Events.
final class AudirvanaController: ObservableObject {
    static let bundleID = "com.audirvana.Audirvana-Origin"

    @Published var playerState: String = "Unknown"
    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var quality: String = ""
    @Published var position: Double = 0
    @Published var duration: Double = 0
    @Published var artwork: NSImage?
    @Published var isRunning: Bool = false
    @Published var albumTracks: [AlbumTrack] = []
    @Published var currentTrackPath: String = ""

    private var timer: Timer?
    private var currentTrackFolder: String?

    /// Hides Audirvana's own windows/Dock presence, so it can be driven purely from this remote.
    func hideAudirvana() {
        Self.hideAudirvana()
    }

    static func hideAudirvana() {
        NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.bundleID)
            .first?
            .hide()
    }

    /// Brings Audirvana's own window to the front, e.g. for library browsing this remote doesn't cover.
    func activateAudirvana() {
        guard let app = NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.bundleID)
            .first else { return }
        app.unhide()
        app.activate(options: [.activateAllWindows])
    }

    func startPolling(interval: TimeInterval = 1.0) {
        refresh()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Transport commands

    func playPause() { run(command: "playpause") }
    func stop() { run(command: "stop") }
    func nextTrack() { run(command: "next track") }
    func previousTrack() { run(command: "previous track") }
    func backTrack() { run(command: "back track") }

    /// Jumps directly to a track, bypassing AppleScript source (see AppleEventSender for why).
    func playTrack(url: URL) {
        AppleEventSender.send(
            toBundleID: Self.bundleID,
            eventClass: "AudP",
            eventID: "sPlT",
            params: [
                ("TkTp", NSAppleEventDescriptor(enumCode: AppleEventSender.fourCharCode("kTFl"))),
                ("TURL", NSAppleEventDescriptor(string: url.absoluteString))
            ]
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refresh()
        }
    }

    func seek(to seconds: Double) {
        execute(source: "tell application id \"\(Self.bundleID)\" to set player position to \(seconds)")
        position = seconds
    }

    private func run(command: String) {
        execute(source: "tell application id \"\(Self.bundleID)\" to \(command)")
        // Give the app a beat to update its state, then refresh immediately.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refresh()
        }
    }

    // MARK: - State refresh

    func refresh() {
        let wasRunning = isRunning
        isRunning = NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.bundleID)
            .isEmpty == false

        if isRunning != wasRunning {
            MenuBarController.shared.setVisible(isRunning)
            if !isRunning {
                WindowManager.shared.closeDetachedWindow()
            }
        }

        guard isRunning else {
            playerState = "Not Running"
            title = ""
            artist = ""
            album = ""
            quality = ""
            position = 0
            duration = 0
            artwork = nil
            albumTracks = []
            currentTrackPath = ""
            currentTrackFolder = nil
            return
        }

        playerState = string(forProperty: "player state") ?? "Unknown"
        title = string(forProperty: "playing track title") ?? ""
        artist = string(forProperty: "playing track artist") ?? ""
        album = string(forProperty: "playing track album") ?? ""
        position = double(forProperty: "player position")
        duration = double(forProperty: "playing track duration")
        artwork = fetchArtwork()

        if let trackURL = string(forProperty: "playing track url") {
            quality = QualityReader.describe(playingTrackURLString: trackURL) ?? ""
            currentTrackPath = FileURLDecoding.decode(trackURL)?.path ?? ""
            updateAlbumTracks(forTrackURLString: trackURL)
        } else {
            quality = ""
            currentTrackPath = ""
            albumTracks = []
            currentTrackFolder = nil
        }
    }

    private func updateAlbumTracks(forTrackURLString raw: String) {
        guard let fileURL = FileURLDecoding.decode(raw) else {
            albumTracks = []
            currentTrackFolder = nil
            return
        }
        let folder = fileURL.deletingLastPathComponent().path
        guard folder != currentTrackFolder else { return }
        currentTrackFolder = folder
        albumTracks = AlbumTrackReader.tracks(inSameFolderAs: raw, artistHint: artist)
    }

    private func string(forProperty property: String) -> String? {
        let script = "tell application id \"\(Self.bundleID)\" to get \(property) as text"
        guard let descriptor = execute(source: script) else { return nil }
        return descriptor.stringValue
    }

    private func double(forProperty property: String) -> Double {
        let script = "tell application id \"\(Self.bundleID)\" to get \(property)"
        guard let descriptor = execute(source: script) else { return 0 }
        return descriptor.doubleValue
    }

    private func fetchArtwork() -> NSImage? {
        let script = "tell application id \"\(Self.bundleID)\" to get playing track airfoillogo"
        guard let descriptor = execute(source: script) else { return nil }
        let data = descriptor.data
        guard !data.isEmpty else { return nil }
        return NSImage(data: data)
    }

    @discardableResult
    private func execute(source: String) -> NSAppleEventDescriptor? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            NSLog("AudirvanaController AppleScript error: \(errorInfo)")
            return nil
        }
        return result
    }
}
