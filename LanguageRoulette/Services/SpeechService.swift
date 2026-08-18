import AVFoundation
import Foundation

@MainActor
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    private var didConfigureSession = false
    private var cachedVoice: AVSpeechSynthesisVoice?

    func speakGerman(_ prompt: String) {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        configureAudioSessionIfNeeded()

        let voice = preferredGermanVoice()
        let utterance = AVSpeechUtterance(string: prompt)
        utterance.voice = voice
        utterance.rate = naturalRate(for: voice)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.12
        synthesizer.speak(utterance)
    }

    func cancel() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func configureAudioSessionIfNeeded() {
        guard !didConfigureSession else {
            try? AVAudioSession.sharedInstance().setActive(true, options: [])
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            // `.playback` makes speech audible even when the Ring/Silent switch is on mute.
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: [])
            didConfigureSession = true
        } catch {
            // Still attempt speech; device may play through the current route.
            didConfigureSession = false
        }
    }

    /// Picks the most natural installed Apple German voice.
    /// Premium/Siri voices (Helena, Anna, Martin) beat the compact `de-DE` voice,
    /// which is what `AVSpeechSynthesisVoice(language:)` returns and sounds robotic.
    private func preferredGermanVoice() -> AVSpeechSynthesisVoice? {
        if let cachedVoice {
            return cachedVoice
        }

        let installed = AVSpeechSynthesisVoice.speechVoices().filter(isUsableGermanVoice)
        let voice = installed.max(by: { voiceScore($0) < voiceScore($1) })
        cachedVoice = voice
        return voice
    }

    private func isUsableGermanVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
        guard voice.language.hasPrefix("de") else { return false }
        if voice.voiceTraits.contains(.isNoveltyVoice) { return false }
        if voice.voiceTraits.contains(.isPersonalVoice) { return false }
        return true
    }

    private func voiceScore(_ voice: AVSpeechSynthesisVoice) -> Int {
        var score = 0

        switch voice.language {
        case "de-DE": score += 120
        case "de-AT": score += 40
        case "de-CH": score += 20
        default: score += 10
        }

        switch voice.quality {
        case .premium: score += 400
        case .enhanced: score += 250
        default: score += 0
        }

        let haystack = "\(voice.identifier) \(voice.name)".lowercased()
        if haystack.contains("siri") { score += 80 }
        if haystack.contains("premium") { score += 50 }
        if haystack.contains("neural") { score += 40 }
        if haystack.contains("compact") { score -= 90 }

        // Native Apple German voices, nicest first.
        let favorites = ["helena", "anna", "martin"]
        if let index = favorites.firstIndex(where: { haystack.contains($0) }) {
            score += 40 - index * 8
        }

        return score
    }

    private func naturalRate(for voice: AVSpeechSynthesisVoice?) -> Float {
        let base = AVSpeechUtteranceDefaultSpeechRate
        switch voice?.quality {
        case .premium:
            return base * 0.94
        case .enhanced:
            return base * 0.9
        default:
            return base * 0.82
        }
    }
}
