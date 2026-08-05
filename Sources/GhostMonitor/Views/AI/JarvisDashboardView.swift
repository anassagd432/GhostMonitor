import SwiftUI

public struct JarvisDashboardView: View {
    @StateObject private var jarvis = OpenAIJarvisEngine.shared
    @StateObject private var voiceWake = JarvisVoiceWakeService.shared
    @State private var inputPrompt: String = ""
    @State private var showApiKeyConfig: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Hero Banner
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    // Pulsing Arc Reactor Symbol
                    ZStack {
                        Circle()
                            .fill(voiceWake.isListening ? GhostTheme.mint.opacity(0.15) : GhostTheme.cyan.opacity(0.15))
                            .frame(width: 54, height: 54)
                            .shadow(color: voiceWake.isListening ? GhostTheme.mint : GhostTheme.cyan, radius: 12)
                        
                        Circle()
                            .stroke(voiceWake.isListening ? GhostTheme.mint : GhostTheme.cyan, lineWidth: 2)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 22))
                            .foregroundColor(voiceWake.isListening ? GhostTheme.mint : GhostTheme.cyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Circle().fill(voiceWake.isListening ? GhostTheme.mint : GhostTheme.cyan).frame(width: 8, height: 8)
                            Text("JARVIS OPENAI AI AGENT • \(voiceWake.isListening ? "VOICE WAKE ACTIVE" : "READY")")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(voiceWake.isListening ? GhostTheme.mint : GhostTheme.cyan)
                        }
                        
                        Text(voiceWake.isListening ? "Say \"Hey Jarvis [command]\"" : "Real-Time Executive System Assistant")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Hands-Free Voice Wake Toggle
                    Toggle("Hands-Free 'Hey Jarvis'", isOn: $voiceWake.isVoiceWakeEnabled)
                        .toggleStyle(CyberToggleStyle())
                        .frame(width: 170)
                    
                    // API Key Config Button
                    Button(action: { showApiKeyConfig.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                            Text(jarvis.openAIApiKey.isEmpty ? "Set OpenAI Key" : "Key Configured")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(jarvis.openAIApiKey.isEmpty ? GhostTheme.magenta : Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                // API Key Settings Bar (Collapsible)
                if showApiKeyConfig || jarvis.openAIApiKey.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ENTER YOUR OPENAI API KEY (GPT-4o / GPT-4o-mini)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        
                        HStack(spacing: 10) {
                            SecureField("sk-proj-...", text: $jarvis.openAIApiKey)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(6)
                                .foregroundColor(.white)
                            
                            Picker("", selection: $jarvis.selectedModel) {
                                Text("gpt-4o-mini").tag("gpt-4o-mini")
                                Text("gpt-4o").tag("gpt-4o")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 130)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                }
                
                // Quick Action Chips Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        quickChip(icon: "bolt.fill", title: "Trigger Panic Lock", action: "Trigger Emergency Panic Lock")
                        quickChip(icon: "wrench.and.screwdriver.fill", title: "Run System Tuneup", action: "Run Full System Tuneup")
                        quickChip(icon: "cup.and.saucer.fill", title: "Toggle Anti-Sleep", action: "Toggle Anti-Sleep Insomnia Mode")
                        quickChip(icon: "mic.slash.fill", title: "Toggle Mic Block", action: "Toggle Mic Block Driver")
                    }
                }
            }
            .padding(20)
            .background(Color.black.opacity(0.3))
            
            Divider().background(Color.white.opacity(0.1))
            
            // Chat Conversation History
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(jarvis.messages) { msg in
                            HStack(alignment: .top, spacing: 10) {
                                if msg.sender == "JARVIS" {
                                    Image(systemName: "cpu.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(GhostTheme.cyan)
                                        .padding(8)
                                        .background(GhostTheme.cyan.opacity(0.12))
                                        .clipShape(Circle())
                                } else {
                                    Spacer()
                                }
                                
                                VStack(alignment: msg.sender == "JARVIS" ? .leading : .trailing, spacing: 4) {
                                    Text(msg.sender.uppercased())
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(msg.sender == "JARVIS" ? GhostTheme.cyan : GhostTheme.purple)
                                    
                                    Text(msg.text)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(msg.sender == "JARVIS" ? Color.white.opacity(0.06) : GhostTheme.purple.opacity(0.3))
                                        .cornerRadius(12)
                                }
                                .frame(maxWidth: 420, alignment: msg.sender == "JARVIS" ? .leading : .trailing)
                                
                                if msg.sender != "JARVIS" {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(GhostTheme.purple)
                                } else {
                                    Spacer()
                                }
                            }
                            .id(msg.id)
                        }
                        
                        if jarvis.isProcessing {
                            HStack(spacing: 8) {
                                ProgressView().controlSize(.small)
                                Text("JARVIS is thinking...")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(GhostTheme.textSecondary)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                        }
                    }
                    .padding(20)
                }
                .onChange(of: jarvis.messages.count) { _ in
                    if let last = jarvis.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Bottom Prompt Input Bar
            HStack(spacing: 10) {
                TextField("Ask JARVIS or give a system command...", text: $inputPrompt)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .onSubmit {
                        submitPrompt()
                    }
                
                Button(action: { submitPrompt() }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(12)
                        .background(GhostTheme.cyan)
                        .cornerRadius(10)
                        .shadow(color: GhostTheme.cyan.opacity(0.5), radius: 6)
                }
                .buttonStyle(.plain)
                .disabled(inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(16)
            .background(Color.black.opacity(0.4))
        }
        .background(GhostTheme.bgDark)
    }
    
    private func submitPrompt() {
        let trimmed = inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        inputPrompt = ""
        jarvis.sendMessage(trimmed)
    }
    
    private func quickChip(icon: String, title: String, action: String) -> some View {
        Button(action: { jarvis.sendMessage(action) }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06))
            .foregroundColor(GhostTheme.cyan)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(GhostTheme.cyan.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
