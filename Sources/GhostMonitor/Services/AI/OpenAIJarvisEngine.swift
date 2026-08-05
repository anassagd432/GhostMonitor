import Foundation
import SwiftUI
import Combine

public struct JarvisChatMessage: Identifiable, Sendable {
    public let id = UUID()
    public let sender: String // "User" or "JARVIS"
    public let text: String
    public let date: Date
    public var isSystemAction: Bool
    
    public init(sender: String, text: String, date: Date = Date(), isSystemAction: Bool = false) {
        self.sender = sender
        self.text = text
        self.date = date
        self.isSystemAction = isSystemAction
    }
}

@MainActor
public final class OpenAIJarvisEngine: ObservableObject {
    public static let shared = OpenAIJarvisEngine()
    
    @Published public var openAIApiKey: String = "" {
        didSet { UserDefaults.standard.set(openAIApiKey, forKey: "openai_api_key") }
    }
    @Published public var selectedModel: String = "gpt-4o-mini" {
        didSet { UserDefaults.standard.set(selectedModel, forKey: "openai_model") }
    }
    @Published public private(set) var messages: [JarvisChatMessage] = [
        JarvisChatMessage(sender: "JARVIS", text: "Greetings. I am JARVIS, your executive system AI. Enter your OpenAI API Key or send a command to manage your Mac.")
    ]
    @Published public private(set) var isProcessing: Bool = false
    
    private init() {
        self.openAIApiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        self.selectedModel = UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-4o-mini"
    }
    
    public func sendMessage(_ prompt: String) {
        let userMsg = JarvisChatMessage(sender: "User", text: prompt)
        messages.append(userMsg)
        
        // Local System Action Matching (Offline fallback / instant trigger)
        let lower = prompt.lowercased()
        if lower.contains("panic") || lower.contains("lock") {
            GhostPanicService.shared.triggerPanicMode()
            let sysMsg = JarvisChatMessage(sender: "JARVIS", text: "⚡ Emergency Panic Mode engaged: Screen locked, audio muted, and privacy drivers locked.", isSystemAction: true)
            messages.append(sysMsg)
            return
        } else if lower.contains("tuneup") || lower.contains("clean system") || lower.contains("maintenance") {
            SystemMaintenanceService.shared.runFullTuneup()
            let sysMsg = JarvisChatMessage(sender: "JARVIS", text: "🛠️ Executing macOS System Deep Tuneup: Flushing DNS, rebuilding LaunchServices, and purging RAM.", isSystemAction: true)
            messages.append(sysMsg)
            return
        } else if lower.contains("sleep") || lower.contains("caffeine") || lower.contains("insomnia") {
            InsomniaService.shared.toggleInsomnia()
            let state = InsomniaService.shared.isAwake ? "ENABLED" : "DISABLED"
            let sysMsg = JarvisChatMessage(sender: "JARVIS", text: "☕ Anti-Sleep Insomnia Mode is now \(state).", isSystemAction: true)
            messages.append(sysMsg)
            return
        } else if lower.contains("mic") || lower.contains("microphone") || lower.contains("privacy") {
            Task {
                await PrivacyKillswitchService.shared.toggleMicBlock()
            }
            let state = PrivacyKillswitchService.shared.isMicBlocked ? "BLOCKED" : "UNBLOCKED"
            let sysMsg = JarvisChatMessage(sender: "JARVIS", text: "🎙️ Hardware Microphone Driver is now \(state).", isSystemAction: true)
            messages.append(sysMsg)
            return
        }
        
        // If API key is not set, use built-in offline smart response
        guard !openAIApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let offlineResp = JarvisChatMessage(
                sender: "JARVIS",
                text: "I processed your request: '\(prompt)'. (Tip: Enter your OpenAI API Key above for full real-time GPT-4o intelligence!)"
            )
            messages.append(offlineResp)
            return
        }
        
        // OpenAI API Request
        isProcessing = true
        let apiKey = openAIApiKey
        let model = selectedModel
        
        Task.detached(priority: .userInitiated) {
            let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
            var req = URLRequest(url: endpoint)
            req.httpMethod = "POST"
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let systemMessage: [String: Any] = [
                "role": "system",
                "content": "You are JARVIS, an advanced AI Executive Assistant inside Ghost Monitor for macOS. Be concise, brilliant, polite, and helpful."
            ]
            let userMessage: [String: Any] = [
                "role": "user",
                "content": prompt
            ]
            
            let body: [String: Any] = [
                "model": model,
                "messages": [systemMessage, userMessage],
                "max_tokens": 300,
                "temperature": 0.7
            ]
            
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let msg = first["message"] as? [String: Any],
                   let content = msg["content"] as? String {
                    await MainActor.run {
                        self.messages.append(JarvisChatMessage(sender: "JARVIS", text: content.trimmingCharacters(in: .whitespacesAndNewlines)))
                        self.isProcessing = false
                    }
                } else {
                    await MainActor.run {
                        self.messages.append(JarvisChatMessage(sender: "JARVIS", text: "Unable to connect to OpenAI API. Please check your API key."))
                        self.isProcessing = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.messages.append(JarvisChatMessage(sender: "JARVIS", text: "Error: \(error.localizedDescription)"))
                    self.isProcessing = false
                }
            }
        }
    }
}
