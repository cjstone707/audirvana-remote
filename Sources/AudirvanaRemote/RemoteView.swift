import AppKit
import SwiftUI

struct RemoteView: View {
    @ObservedObject var controller: AudirvanaController
    var showsDetachButton: Bool = true
    /// Present only for the detached window; drives section collapsing as it's resized.
    @ObservedObject var layoutState: DetachedWindowLayoutState = DetachedWindowLayoutState()
    var isResizeDriven: Bool = false

    @State private var isScrubbing = false
    @State private var scrubPosition: Double = 0
    @State private var showAlbumTracks = false
    @State private var localIsMinified = false

    private var isMinified: Bool {
        isResizeDriven ? layoutState.isMinified : localIsMinified
    }

    private func setMinified(_ value: Bool) {
        if isResizeDriven {
            WindowManager.shared.resizeDetachedWindow(toMinified: value)
        } else {
            localIsMinified = value
        }
    }

    private var showAlbumTracksSection: Bool { !isResizeDriven || layoutState.showAlbumTracksSection }
    private var showPlayerSection: Bool { !isResizeDriven || layoutState.showPlayerSection }
    private var showTextSection: Bool { !isResizeDriven || layoutState.showTextSection }

    var body: some View {
        VStack(spacing: 0) {
            if isMinified {
                minifiedView
                    .padding(10)
            } else {
                toolbar
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                fullView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .frame(width: 240)
            }
        }
        .frame(
            maxWidth: isResizeDriven ? .infinity : nil,
            maxHeight: isResizeDriven ? .infinity : nil,
            alignment: .top
        )
        .background(backdrop)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var toolbar: some View {
        HStack(spacing: 10) {
            Spacer()
            if showsDetachButton {
                Button {
                    WindowManager.shared.showDetachedWindow(controller: controller)
                    MenuBarController.shared.hidePopover()
                } label: {
                    Image(systemName: "macwindow")
                }
                .nativeTooltip("Detach Window")
            }
            Button {
                controller.activateAudirvana()
                WindowManager.shared.closeDetachedWindow()
                MenuBarController.shared.hidePopover()
            } label: {
                Image(systemName: "arrow.up.forward.app")
            }
            .nativeTooltip("Show Audirvana")
            Button {
                setMinified(true)
            } label: {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
            }
            .nativeTooltip("Minify")
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .nativeTooltip("Quit")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.75))
    }

    @ViewBuilder
    private var backdrop: some View {
        ZStack {
            Color.black
            if let artwork = controller.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 36)
                    .saturation(1.4)
            } else {
                LinearGradient(
                    colors: [Color(red: 0.16, green: 0.16, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            Color.black.opacity(0.45)
        }
    }

    @ViewBuilder
    private var minifiedView: some View {
        HStack(spacing: 10) {
            artworkView
                .frame(width: 44, height: 44)
                .cornerRadius(5)
                .shadow(radius: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(controller.title.isEmpty ? "Nothing Playing" : controller.title)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(controller.artist)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                Text(controller.album)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
            .frame(width: 120, alignment: .leading)
            .nativeTooltip("\(controller.title)\n\(controller.artist)\n\(controller.album)")

            Button(action: controller.previousTrack) {
                Image(systemName: "backward.fill")
            }
            Button(action: controller.playPause) {
                Image(systemName: controller.playerState == "Playing" ? "pause.fill" : "play.fill")
            }
            Button(action: controller.nextTrack) {
                Image(systemName: "forward.fill")
            }
            Button {
                setMinified(false)
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var fullView: some View {
        VStack(spacing: 12) {
            artworkView
                .frame(width: 180, height: 180)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.5), radius: 10, y: 4)

            if showTextSection {
                VStack(spacing: 2) {
                    Text(controller.title.isEmpty ? "Nothing Playing" : controller.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(controller.artist)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                    Text(controller.album)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                    if !controller.quality.isEmpty {
                        Text(controller.quality)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: 220)
            }

            if showPlayerSection {
                progressView

                HStack(spacing: 28) {
                    Button(action: controller.previousTrack) {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                    }
                    Button(action: controller.playPause) {
                        Image(systemName: controller.playerState == "Playing" ? "pause.fill" : "play.fill")
                            .font(.title)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.white.opacity(0.15)))
                    }
                    Button(action: controller.nextTrack) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)

                Text(controller.isRunning ? controller.playerState : "Audirvana not running")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }

            if showAlbumTracksSection && !controller.albumTracks.isEmpty {
                albumTracksDrawer
            }
        }
    }

    @ViewBuilder
    private var progressView: some View {
        let duration = max(controller.duration, 1)
        let displayedPosition = isScrubbing ? scrubPosition : controller.position

        VStack(spacing: 2) {
            Slider(
                value: Binding(
                    get: { displayedPosition },
                    set: { scrubPosition = $0 }
                ),
                in: 0...duration,
                onEditingChanged: { editing in
                    if editing {
                        scrubPosition = controller.position
                        isScrubbing = true
                    } else {
                        controller.seek(to: scrubPosition)
                        isScrubbing = false
                    }
                }
            )
            .tint(.white)
            HStack {
                Text(Self.formatted(displayedPosition))
                Spacer()
                Text(Self.formatted(controller.duration))
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: 220)
    }

    @ViewBuilder
    private var albumTracksDrawer: some View {
        DisclosureGroup(
            "Album Tracks",
            isExpanded: Binding(
                get: { showAlbumTracks },
                set: { newValue in
                    showAlbumTracks = newValue
                    if isResizeDriven {
                        WindowManager.shared.resizeForExpandedTracks(newValue)
                    }
                }
            )
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(controller.albumTracks) { track in
                        let isCurrent = track.url.path == controller.currentTrackPath
                        Button {
                            controller.playTrack(url: track.url)
                        } label: {
                            HStack {
                                Text(track.trackNumber.map { String(format: "%02d", $0) } ?? "")
                                    .monospacedDigit()
                                    .foregroundStyle(.white.opacity(0.5))
                                    .frame(width: 20, alignment: .trailing)
                                Text(track.displayTitle)
                                    .lineLimit(1)
                                Spacer()
                                if isCurrent {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.caption2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isCurrent ? Color.accentColor : Color.white.opacity(0.85))
                    }
                }
            }
            .frame(maxHeight: 160)
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.85))
        .frame(maxWidth: 220)
    }

    private static func formatted(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    @ViewBuilder
    private var artworkView: some View {
        if let artwork = controller.artwork {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                Color.white.opacity(0.08)
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}
