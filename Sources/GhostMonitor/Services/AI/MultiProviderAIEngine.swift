import Foundation
import SwiftUI

public enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case openAI = "OpenAI (GPT-4o / Codex)"
    case anthropic = "Anthropic (Claude 3.5 Sonnet)"
    case googleGemini = "Google Gemini (2.0 Flash)"
    case deepseek = "DeepSeek (V3 / R1)"
    case groq = "Groq LPU (Llama 3.3)"
    case ollamaLocal = "Ollama (Local Llama / DeepSeek-R1)"
    
    public var id: String { rawValue }
}

public struct AIModelOption: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let provider: AIProvider
    public let isLocal: Bool
    
    public init(id: String, name: String, provider: AIProvider, isLocal: Bool = false) {
        self.id = id
        self.name = name
        self.provider = provider
        self.isLocal = isLocal
    }
}

@MainActor
public final class MultiProviderAIEngine: ObservableObject {
    public static let shared = MultiProviderAIEngine()
    
    @Published public var selectedProvider: AIProvider = .openAI {
        didSet { UserDefaults.standard.set(selectedProvider.rawValue, forKey: "ai_selected_provider") }
    }
    
    @Published public var selectedModelId: String = "gpt-4o" {
        didSet { UserDefaults.standard.set(selectedModelId, forKey: "ai_selected_model_id") }
    }
    
    // API Keys & OAuth Tokens
    @Published public var openAIApiKey: String = "" {
        didSet { UserDefaults.standard.set(openAIApiKey, forKey: "ai_key_openai") }
    }
    @Published public var openAIOAuthToken: String = "" {
        didSet { UserDefaults.standard.set(openAIOAuthToken, forKey: "ai_oauth_openai") }
    }
    
    @Published public var anthropicApiKey: String = "" {
        didSet { UserDefaults.standard.set(anthropicApiKey, forKey: "ai_key_anthropic") }
    }
    @Published public var anthropicOAuthToken: String = "" {
        didSet { UserDefaults.standard.set(anthropicOAuthToken, forKey: "ai_oauth_anthropic") }
    }
    
    @Published public var geminiApiKey: String = "" {
        didSet { UserDefaults.standard.set(geminiApiKey, forKey: "ai_key_gemini") }
    }
    
    @Published public var deepseekApiKey: String = "" {
        didSet { UserDefaults.standard.set(deepseekApiKey, forKey: "ai_key_deepseek") }
    }
    
    @Published public var groqApiKey: String = "" {
        didSet { UserDefaults.standard.set(groqApiKey, forKey: "ai_key_groq") }
    }
    
    @Published public var ollamaEndpoint: String = "http://localhost:11434" {
        didSet { UserDefaults.standard.set(ollamaEndpoint, forKey: "ai_ollama_endpoint") }
    }
    @Published public var ollamaModelName: String = "llama3.3" {
        didSet { UserDefaults.standard.set(ollamaModelName, forKey: "ai_ollama_model") }
    }
    
    @Published public private(set) var availableModels: [AIModelOption] = []
    @Published public private(set) var isProcessing: Bool = false
    @Published public private(set) var lastResponseText: String = ""
    
    private init() {
        loadSavedConfig()
        populateAvailableModels()
    }
    
    private func loadSavedConfig() {
        if let raw = UserDefaults.standard.string(forKey: "ai_selected_provider"), let prov = AIProvider(rawValue: raw) {
            self.selectedProvider = prov
        }
        self.selectedModelId = UserDefaults.standard.string(forKey: "ai_selected_model_id") ?? "gpt-4o"
        self.openAIApiKey = UserDefaults.standard.string(forKey: "ai_key_openai") ?? ""
        self.openAIOAuthToken = UserDefaults.standard.string(forKey: "ai_oauth_openai") ?? ""
        self.anthropicApiKey = UserDefaults.standard.string(forKey: "ai_key_anthropic") ?? ""
        self.anthropicOAuthToken = UserDefaults.standard.string(forKey: "ai_oauth_anthropic") ?? ""
        self.geminiApiKey = UserDefaults.standard.string(forKey: "ai_key_gemini") ?? ""
        self.deepseekApiKey = UserDefaults.standard.string(forKey: "ai_key_deepseek") ?? ""
        self.groqApiKey = UserDefaults.standard.string(forKey: "ai_key_groq") ?? ""
        self.ollamaEndpoint = UserDefaults.standard.string(forKey: "ai_ollama_endpoint") ?? "http://localhost:11434"
        self.ollamaModelName = UserDefaults.standard.string(forKey: "ai_ollama_model") ?? "llama3.3"
    }
    
    public func populateAvailableModels() {
        availableModels = [
            // OpenAI
            AIModelOption(id: "gpt-4o", name: "GPT-4o (Omni High Reasoning)", provider: .openAI),
            AIModelOption(id: "gpt-4o-mini", name: "GPT-4o Mini (Fast)", provider: .openAI),
            AIModelOption(id: "o3-mini", name: "OpenAI o3-mini (Reasoning)", provider: .openAI),
            AIModelOption(id: "codex-gpt-4", name: "OpenAI Codex Engine", provider: .openAI),
            
            // Anthropic
            AIModelOption(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet (v2)", provider: .anthropic),
            AIModelOption(id: "claude-3-5-haiku-20241022", name: "Claude 3.5 Haiku", provider: .anthropic),
            
            // Google Gemini
            AIModelOption(id: "gemini-2.0-flash", name: "Gemini 2.0 Flash (Next-Gen)", provider: .googleGemini),
            AIModelOption(id: "gemini-1.5-pro", name: "Gemini 1.5 Pro", provider: .googleGemini),
            
            // DeepSeek
            AIModelOption(id: "deepseek-chat", name: "DeepSeek-V3", provider: .deepseek),
            AIModelOption(id: "deepseek-reasoner", name: "DeepSeek-R1 (Reasoning)", provider: .deepseek),
            
            // Groq LPU
            AIModelOption(id: "llama-3.3-70b-versatile", name: "Groq Llama 3.3 70B (Sub-100ms)", provider: .groq),
            
            // Ollama Local
            AIModelOption(id: "llama3.3", name: "Ollama Local (Llama 3.3 / DeepSeek-R1)", provider: .ollamaLocal, isLocal: true)
        ]
    }
    
    public func sendQuery(prompt: String) async -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        switch selectedProvider {
        case .openAI:
            return await queryOpenAI(prompt: prompt)
        case .anthropic:
            return await queryAnthropic(prompt: prompt)
        case .googleGemini:
            return await queryGemini(prompt: prompt)
        case .deepseek:
            return await queryDeepSeek(prompt: prompt)
        case .groq:
            return await queryGroq(prompt: prompt)
        case .ollamaLocal:
            return await queryOllamaLocal(prompt: prompt)
        }
    }
    
    // MARK: - Provider Implementations
    private func queryOpenAI(prompt: String) async -> String {
        let key = openAIApiKey.isEmpty ? openAIOAuthToken : openAIApiKey
        guard !key.isEmpty else { return "Error: No OpenAI API Key or Pro OAuth Token configured." }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return "Error: Invalid URL" }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": selectedModelId,
            "messages": [
                ["role": "system", "content": "You are Ghost AI / JARVIS, executive macOS system manager."],
                ["role": "user", "content": prompt]
            ]
        ]
        
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let msg = first["message"] as? [String: Any],
               let content = msg["content"] as? String {
                return content
            }
        } catch {
            return "OpenAI API Error: \(error.localizedDescription)"
        }
        return "OpenAI API returned unexpected payload."
    }
    
    private func queryAnthropic(prompt: String) async -> String {
        let key = anthropicApiKey.isEmpty ? anthropicOAuthToken : anthropicApiKey
        guard !key.isEmpty else { return "Error: No Anthropic Claude API Key or Pro OAuth Token configured." }
        
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return "Error: Invalid URL" }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": selectedModelId,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let contentArr = json["content"] as? [[String: Any]],
               let first = contentArr.first,
               let text = first["text"] as? String {
                return text
            }
        } catch {
            return "Anthropic API Error: \(error.localizedDescription)"
        }
        return "Anthropic API returned unexpected payload."
    }
    
    private func queryGemini(prompt: String) async -> String {
        guard !geminiApiKey.isEmpty else { return "Error: No Google Gemini API Key configured." }
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(selectedModelId):generateContent?key=\(geminiApiKey)") else { return "Error: Invalid URL" }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let first = candidates.first,
               let contentObj = first["content"] as? [String: Any],
               let parts = contentObj["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                return text
            }
        } catch {
            return "Google Gemini API Error: \(error.localizedDescription)"
        }
        return "Gemini API returned unexpected payload."
    }
    
    private func queryDeepSeek(prompt: String) async -> String {
        guard !deepseekApiKey.isEmpty else { return "Error: No DeepSeek API Key configured." }
        
        guard let url = URL(string: "https://api.deepseek.com/chat/completions") else { return "Error: Invalid URL" }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(deepseekApiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": selectedModelId,
            "messages": [
                ["role": "system", "content": "You are DeepSeek AI agent for Ghost Monitor."],
                ["role": "user", "content": prompt]
            ]
        ]
        
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let msg = first["message"] as? [String: Any],
               let content = msg["content"] as? String {
                return content
            }
        } catch {
            return "DeepSeek API Error: \(error.localizedDescription)"
        }
        return "DeepSeek API returned unexpected payload."
    }
    
    private func queryGroq(prompt: String) async -> String {
        guard !groqApiKey.isEmpty else { return "Error: No Groq LPU API Key configured." }
        
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else { return "Error: Invalid URL" }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(groqApiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": selectedModelId,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let msg = first["message"] as? [String: Any],
               let content = msg["content"] as? String {
                return content
            }
        } catch {
            return "Groq API Error: \(error.localizedDescription)"
        }
        return "Groq API returned unexpected payload."
    }
    
    private func queryOllamaLocal(prompt: String) async -> String {
        let endpoint = ollamaEndpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(endpoint)/api/generate") else { return "Error: Invalid Ollama URL" }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": ollamaModelName,
            "prompt": prompt,
            "stream": false
        ]
        
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let resp = json["response"] as? String {
                return resp
            }
        } catch {
            return "Ollama Local Connection Error: Make sure Ollama is running at \(ollamaEndpoint). Error: \(error.localizedDescription)"
        }
        return "Ollama returned unexpected payload."
    }
}
