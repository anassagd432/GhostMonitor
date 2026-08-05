import SwiftUI

public struct AIProvidersView: View {
    @StateObject private var ai = MultiProviderAIEngine.shared
    
    @State private var testPrompt: String = "Hello JARVIS, test AI engine latency."
    @State private var testOutput: String = ""
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GhostTheme.cyan.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .shadow(color: GhostTheme.cyan, radius: 12)
                        
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 38))
                            .foregroundColor(GhostTheme.cyan)
                    }
                    
                    Text("Multi-Engine AI Model & Provider Vault")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Seamlessly switch between OpenAI (GPT-4o/Codex), Anthropic Claude 3.5, Google Gemini 2.0, DeepSeek V3/R1, Groq LPU, and Ollama Local (Llama 3.3).")
                        .font(.system(size: 13))
                        .foregroundColor(GhostTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                // Active Model Selector Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("ACTIVE ENGINE & PROVIDER SELECTOR")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Provider").font(.system(size: 10, design: .monospaced)).foregroundColor(GhostTheme.textSecondary)
                            Picker("", selection: $ai.selectedProvider) {
                                ForEach(AIProvider.allCases) { prov in
                                    Text(prov.rawValue).tag(prov)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Model").font(.system(size: 10, design: .monospaced)).foregroundColor(GhostTheme.textSecondary)
                            Picker("", selection: $ai.selectedModelId) {
                                ForEach(ai.availableModels.filter { $0.provider == ai.selectedProvider }) { mod in
                                    Text(mod.name).tag(mod.id)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .padding(20)
                .cyberCardStyle(glowing: true)
                
                // Provider Credentials Vault Cards
                VStack(alignment: .leading, spacing: 16) {
                    Text("API KEYS & PRO/PLUS OAUTH CREDENTIALS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    // 1. OpenAI
                    providerCard(title: "OpenAI (GPT-4o / Codex / o3-mini)", icon: "sparkles") {
                        VStack(spacing: 8) {
                            SecureField("API Key (sk-proj-...)", text: $ai.openAIApiKey).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.4)).cornerRadius(6).foregroundColor(.white)
                            SecureField("Pro / Plus OAuth Token", text: $ai.openAIOAuthToken).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.4)).cornerRadius(6).foregroundColor(.white)
                        }
                    }
                    
                    // 2. Anthropic Claude
                    providerCard(title: "Anthropic (Claude 3.5 Sonnet / Haiku)", icon: "brain") {
                        VStack(spacing: 8) {
                            SecureField("Claude API Key (sk-ant-...)", text: $ai.anthropicApiKey).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.4)).cornerRadius(6).foregroundColor(.white)
                            SecureField("Claude Pro OAuth Token", text: $ai.anthropicOAuthToken).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.4)).cornerRadius(6).foregroundColor(.white)
                        }
                    }
                    
                    // 3. Google Gemini
                    providerCard(title: "Google Gemini (2.0 Flash / 1.5 Pro)", icon: "g.circle.fill") {
                        SecureField("Gemini API Key (AIzaSy...)", text: $ai.geminiApiKey).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.4)).cornerRadius(6).foregroundColor(.white)
                    }
                    
                    // 4. DeepSeek
                    providerCard(title: "DeepSeek (V3 / R1 Reasoning)", icon: "bolt.horizontal.fill") {
                        SecureField("DeepSeek API Key (sk-...)", text: $ai.deepseekApiKey).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.4)).cornerRadius(6).foregroundColor(.white)
                    }
                    
                    // 5. Groq LPU
                    providerCard(title: "Groq LPU (Sub-100ms Llama 3.3)", icon: "bolt.fill") {
                        SecureField("Groq API Key (gsk_...)", text: $ai.groqApiKey).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.4)).cornerRadius(6).foregroundColor(.white)
                    }
                    
                    // 6. Ollama Local LLM
                    providerCard(title: "Ollama (100% Offline Local Llama / DeepSeek-R1)", icon: "house.fill") {
                        VStack(spacing: 8) {
                            TextField("Ollama Endpoint (http://localhost:11434)", text: $ai.ollamaEndpoint).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.4)).cornerRadius(6).foregroundColor(.white)
                            TextField("Local Model Tag (e.g. llama3.3, deepseek-r1)", text: $ai.ollamaModelName).textFieldStyle(.plain).padding(8).background(Color.black.opacity(0.4)).cornerRadius(6).foregroundColor(.white)
                        }
                    }
                }
                
                // Test AI Dispatcher Box
                VStack(alignment: .leading, spacing: 12) {
                    Text("LIVE TEST AI DISPATCHER")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    HStack {
                        TextField("Test prompt...", text: $testPrompt)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            Task {
                                testOutput = await ai.sendQuery(prompt: testPrompt)
                            }
                        }) {
                            HStack {
                                if ai.isProcessing {
                                    ProgressView().controlSize(.small)
                                }
                                Text("Execute Query")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(GhostTheme.cyan)
                            .foregroundColor(.black)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !testOutput.isEmpty {
                        Text(testOutput)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(GhostTheme.mint)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                    }
                }
                .padding(20)
                .cyberCardStyle()
            }
            .padding(24)
        }
        .background(GhostTheme.bgDark)
    }
    
    private func providerCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(GhostTheme.cyan)
                Text(title).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(.white)
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(GhostTheme.cyan.opacity(0.2), lineWidth: 1))
    }
}
