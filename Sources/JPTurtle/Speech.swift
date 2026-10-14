#if os(iOS)
import AVFoundation
import Foundation

/// Sprachausgabe über die Systemstimme (AVSpeechSynthesizer, ja-JP).
/// Läuft komplett offline, braucht keine Berechtigung und keine Entitlements.
/// Gesprochen wird bewusst etwas langsamer als normal, weil die App für
/// Anfänger gedacht ist.
@MainActor
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechService()

    private let synth = AVSpeechSynthesizer()

    /// `false`, wenn auf dem Gerät keine japanische Stimme installiert ist.
    var hasJapaneseVoice: Bool {
        AVSpeechSynthesisVoice.speechVoices().contains { $0.language == "ja-JP" }
    }

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(_ text: String, slow: Bool = true) {
        guard !text.isEmpty else { return }
        configureSession()
        synth.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = bestJapaneseVoice()
        utterance.rate = slow ? 0.42 : AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.05
        synth.speak(utterance)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }

    /// Nimmt die beste installierte Stimme (Premium > Erweitert > Standard).
    private func bestJapaneseVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "ja-JP" }
        return voices.max { $0.quality.rawValue < $1.quality.rawValue }
            ?? AVSpeechSynthesisVoice(language: "ja-JP")
    }

    /// .playback sorgt dafür, dass auch bei stummgeschaltetem iPhone gesprochen wird.
    /// Andere Audio-Wiedergabe wird nur kurz leiser.
    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
#endif
