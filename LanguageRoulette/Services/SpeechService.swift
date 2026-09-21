import AVFoundation
import Foundation

struct GermanVoiceOption: Identifiable, Hashable {
    let identifier: String
    let name: String
    let language: String
    let quality: AVSpeechSynthesisVoiceQuality

    var id: String { identifier }

    var qualityKey: String {
        switch quality {
        case .premium: return "voiceQualityPremium"
        case .enhanced: return "voiceQualityEnhanced"
        default: return "voiceQualityStandard"
        }
    }

    var regionKey: String {
        switch language {
        case "de-AT": return "voiceRegionAT"
        case "de-CH": return "voiceRegionCH"
        default: return "voiceRegionDE"
        }
    }
}

@MainActor
final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    private var didConfigureSession = false

    @discardableResult
    func speakGerman(_ prompt: String) -> Bool {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
        synthesizer.stopSpeaking(at: .immediate)
        guard let voice = resolveVoice() else { return false }
        configureAudioSessionIfNeeded()
        let utterance = AVSpeechUtterance(string: prompt)
        utterance.voice = voice
        utterance.rate = naturalRate(for: voice)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.12
        synthesizer.speak(utterance)
        return true
    }

    func cancel() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func availableGermanVoices() -> [GermanVoiceOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter(isListableGermanVoice)
            .map { voice in
                GermanVoiceOption(
                    identifier: voice.identifier,
                    name: displayName(for: voice),
                    language: voice.language,
                    quality: voice.quality
                )
            }
            .sorted { lhs, rhs in
                let left = voiceSortScore(lhs)
                let right = voiceSortScore(rhs)
                if left != right { return left > right }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private func configureAudioSessionIfNeeded() {
        guard !didConfigureSession else {
            try? AVAudioSession.sharedInstance().setActive(true, options: [])
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: [])
            didConfigureSession = true
        } catch {
            didConfigureSession = false
        }
    }

    private func resolveVoice() -> AVSpeechSynthesisVoice? {
        let installed = AVSpeechSynthesisVoice.speechVoices().filter(isListableGermanVoice)
        return installed.max(by: { voiceScore($0) < voiceScore($1) })
    }

    private func isListableGermanVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
        guard voice.language.hasPrefix("de") else { return false }
        if voice.voiceTraits.contains(.isPersonalVoice) { return false }
        let words = voice.name.lowercased().split { !$0.isLetter }
        return words.first == "anna"
    }

    private func displayName(for voice: AVSpeechSynthesisVoice) -> String {
        let name = voice.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? voice.identifier : name
    }

    private func voiceSortScore(_ option: GermanVoiceOption) -> Int {
        var score = 0
        switch option.language {
        case "de-DE": score += 120
        case "de-AT": score += 40
        case "de-CH": score += 20
        default: score += 10
        }
        switch option.quality {
        case .premium: score += 400
        case .enhanced: score += 250
        default: score += 0
        }
        let haystack = "\(option.identifier) \(option.name)".lowercased()
        if haystack.contains("siri") { score += 80 }
        if haystack.contains("compact") { score -= 90 }
        return score
    }

    private func voiceScore(_ voice: AVSpeechSynthesisVoice) -> Int {
        voiceSortScore(
            GermanVoiceOption(
                identifier: voice.identifier,
                name: voice.name,
                language: voice.language,
                quality: voice.quality
            )
        )
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
