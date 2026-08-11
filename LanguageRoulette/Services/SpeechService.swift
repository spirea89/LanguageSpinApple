import AVFoundation
import Foundation

@MainActor
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()

    func speakGerman(_ prompt: String) {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: prompt)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = 0.94 * AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    func cancel() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
