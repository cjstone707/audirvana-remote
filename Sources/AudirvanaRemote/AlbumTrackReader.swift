import Foundation

struct AlbumTrack: Identifiable, Equatable {
    var id: String { url.path }
    let url: URL
    let trackNumber: Int?
    let displayTitle: String
}

/// Audirvana's AppleScript dictionary doesn't expose the current album's track list, so this
/// derives it by listing sibling audio files in the currently playing track's folder —
/// matching how locally-stored albums are typically organized one-folder-per-album.
enum AlbumTrackReader {
    static let supportedExtensions: Set<String> = [
        "flac", "wav", "aiff", "aif", "m4a", "alac", "mp3", "dsf", "dff", "ape"
    ]

    static func tracks(inSameFolderAs playingTrackURLString: String, artistHint: String) -> [AlbumTrack] {
        guard let currentURL = FileURLDecoding.decode(playingTrackURLString) else { return [] }
        let folder = currentURL.deletingLastPathComponent()

        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        ) else { return [] }

        let audioFiles = entries.filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
        let sorted = audioFiles.sorted {
            $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
        }

        return sorted.enumerated().map { index, url in
            let (number, rawTitle) = parseNameComponents(for: url)
            let title = strippingArtistPrefix(rawTitle, artist: artistHint)
            return AlbumTrack(url: url, trackNumber: number ?? index + 1, displayTitle: title)
        }
    }

    private static func parseNameComponents(for url: URL) -> (number: Int?, title: String) {
        var name = url.deletingPathExtension().lastPathComponent
        guard let range = name.range(of: #"^\d{1,3}[\s.\-]+"#, options: .regularExpression) else {
            return (nil, name)
        }
        let number = Int(name[range].trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: ".-"))))
        name.removeSubrange(range)
        return (number, name)
    }

    private static func strippingArtistPrefix(_ title: String, artist: String) -> String {
        guard !artist.isEmpty else { return title }
        for separator in [" - ", " – ", ": "] {
            let prefix = artist + separator
            if title.lowercased().hasPrefix(prefix.lowercased()) {
                return String(title.dropFirst(prefix.count))
            }
        }
        return title
    }
}
