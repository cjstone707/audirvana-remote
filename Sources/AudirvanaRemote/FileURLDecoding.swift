import Foundation

/// Audirvana returns "playing track url" percent-encoded oddly (file://%2FVolumes%2F...);
/// this decodes it to a normal local file URL. Shared by QualityReader and AlbumTrackReader.
enum FileURLDecoding {
    static func decode(_ raw: String) -> URL? {
        guard raw.hasPrefix("file://") else { return nil }
        let afterScheme = String(raw.dropFirst("file://".count))
        guard let decoded = afterScheme.removingPercentEncoding else { return nil }
        let path = decoded.hasPrefix("/") ? decoded : "/" + decoded
        return URL(fileURLWithPath: path)
    }
}
