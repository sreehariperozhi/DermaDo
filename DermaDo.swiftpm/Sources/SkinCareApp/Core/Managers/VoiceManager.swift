import AVFoundation
import Combine
import SwiftUI

/// Manages lightweight text-to-speech for DermaDo 2.0 voice guidance.
@MainActor
public final class VoiceManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    
    private let synthesizer = AVSpeechSynthesizer()
    
    /// User preference to enable or disable the voice assistant globally.
    @AppStorage("isVoiceEnabled") public var isVoiceEnabled: Bool = true {
        didSet {
            if !isVoiceEnabled { stop() }
        }
    }
    
    /// Publishes true when the synthesizer is actively speaking.
    @Published public var isSpeaking: Bool = false
    
    public override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    /// Speaks the given text if voice is enabled.
    public func speak(_ text: String) {
        guard isVoiceEnabled else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        // Use a high-quality, friendly English voice if available
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4 // Slower, more premium pace
        utterance.pitchMultiplier = 0.85 // Calmer, slightly deeper tone
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        synthesizer.speak(utterance)
    }
    
    /// Immediately halts any ongoing speech.
    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
