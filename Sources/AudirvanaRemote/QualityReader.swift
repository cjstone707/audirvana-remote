import AVFoundation
import Foundation

/// Derives audio quality (sample rate / bit depth / codec) from the track's file URL,
/// since Audirvana's AppleScript dictionary doesn't expose quality info directly.
enum QualityReader {
    static func describe(playingTrackURLString raw: String) -> String? {
        guard let fileURL = FileURLDecoding.decode(raw) else { return nil }
        guard let audioFile = try? AVAudioFile(forReading: fileURL) else { return nil }

        let format = audioFile.fileFormat
        let sampleRateKHz = format.sampleRate / 1000.0
        let bitDepth = format.settings[AVLinearPCMBitDepthKey] as? Int
        let codec = fileURL.pathExtension.uppercased()

        var parts: [String] = []
        if let bitDepth { parts.append("\(bitDepth)-bit") }
        parts.append(trimmedRate(sampleRateKHz) + " kHz")
        if !codec.isEmpty { parts.append(codec) }
        return parts.joined(separator: " / ")
    }

    private static func trimmedRate(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
