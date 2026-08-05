import Foundation
import AVFoundation
import Speech
import SwiftUI

@MainActor
public final class JarvisVoiceWakeService: ObservableObject {
    public static let shared = JarvisVoiceWakeService()
    
    @Published public var isVoiceWakeEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isVoiceWakeEnabled, forKey: "jarvis_voice_wake")
            if isVoiceWakeEnabled {
                startListening()
            } else {
                stopListening()
            }
        }
    }
    @Published public private(set) var isListening: Bool = false
    @Published public private(set) var recognizedText: String = ""
    @Published public private(set) var permissionGranted: Bool = false
    
    private let audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private init() {
        self.isVoiceWakeEnabled = UserDefaults.standard.object(forKey: "jarvis_voice_wake") as? Bool ?? false
        requestPermissions()
    }
    
    public func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                self.permissionGranted = (status == .authorized)
                if self.permissionGranted && self.isVoiceWakeEnabled {
                    self.startListening()
                }
            }
        }
    }
    
    public func startListening() {
        guard permissionGranted, !isListening else { return }
        
        // Reset previous tasks
        stopListening()
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            print("Failed to start audio engine: \(error)")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcript = result.bestTranscription.formattedString.lowercased()
                Task { @MainActor in
                    self.recognizedText = transcript
                    
                    // Check for "jarvis" or "hey jarvis" wake word
                    if transcript.contains("jarvis") || transcript.contains("hey jarvis") {
                        // Extract command after wake word
                        let components = transcript.components(separatedBy: "jarvis")
                        if let lastComponent = components.last, !lastComponent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let command = lastComponent.trimmingCharacters(in: .whitespacesAndNewlines)
                            OpenAIJarvisEngine.shared.sendMessage(command)
                            self.restartListening()
                        }
                    }
                }
            }
            
            if error != nil {
                Task { @MainActor in
                    self.restartListening()
                }
            }
        }
    }
    
    public func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }
    
    private func restartListening() {
        stopListening()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.isVoiceWakeEnabled {
                self.startListening()
            }
        }
    }
}
