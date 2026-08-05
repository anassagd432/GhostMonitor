import SwiftUI

public struct JarvisDashboardView: View {
    @StateObject private var jarvis = JarvisService.shared
    @State private var targetContact: String = ""
    @State private var targetNumber: String = ""
    @State private var callPrompt: String = ""
    @State private var isShowingNewCallModal: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top Arc Reactor / Voice Visualizer Header
                VStack(spacing: 16) {
                    ZStack {
                        // Outer Pulsing Glow
                        Circle()
                            .fill(GhostTheme.cyan.opacity(0.12))
                            .frame(width: 100, height: 100)
                            .shadow(color: GhostTheme.cyan, radius: 20)
                        
                        Circle()
                            .stroke(GhostTheme.gaugeGradient, lineWidth: 3)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 36))
                            .foregroundColor(GhostTheme.cyan)
                            .shadow(color: GhostTheme.cyan, radius: 10)
                    }
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Circle().fill(jarvis.isListening ? GhostTheme.mint : Color.red).frame(width: 8, height: 8)
                            Text("JARVIS VOICE OS • \(jarvis.isListening ? "ONLINE" : "STANDBY")")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(jarvis.isListening ? GhostTheme.mint : Color.red)
                        }
                        
                        Text("Listening for \"\(jarvis.wakeWord)\"")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(GhostTheme.textSecondary)
                    }
                    
                    Button(action: { jarvis.toggleListening() }) {
                        HStack(spacing: 6) {
                            Image(systemName: jarvis.isListening ? "mic.fill" : "mic.slash.fill")
                            Text(jarvis.isListening ? "Mute Voice Activation" : "Enable Voice Activation")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(jarvis.isListening ? Color.white.opacity(0.08) : GhostTheme.cyan)
                        .foregroundColor(jarvis.isListening ? .white : .black)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 16)
                
                // Executive API & Phone Config Card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "phone.badge.plus")
                                .foregroundColor(GhostTheme.cyan)
                            Text("VAPI / RETELL AI AGENT PIPELINE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(GhostTheme.cyan)
                        }
                        Text("Phone Line: \(jarvis.phoneNumber)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    
                    Button(action: { isShowingNewCallModal.toggle() }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Dispatch AI Call")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(GhostTheme.cyberGradient)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
                .cyberCardStyle(glowing: true)
                
                // AI Voice Phone Call Logs
                VStack(alignment: .leading, spacing: 14) {
                    Text("AI VOICE CALL DELEGATION LOGS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    VStack(spacing: 10) {
                        ForEach(jarvis.callLogs) { log in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "phone.bubble.left.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(log.status == "Completed" ? GhostTheme.mint : GhostTheme.purple)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(log.contactName)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(log.phoneNumber)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(GhostTheme.textSecondary)
                                        Spacer()
                                        Text(log.duration)
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.white.opacity(0.08))
                                            .cornerRadius(4)
                                    }
                                    
                                    Text(log.transcriptSummary)
                                        .font(.system(size: 11))
                                        .foregroundColor(GhostTheme.textSecondary)
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(20)
                .cyberCardStyle()
                
                // AI Email Dispatcher Tasks
                VStack(alignment: .leading, spacing: 14) {
                    Text("PENDING EMAIL DISPATCHES")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    VStack(spacing: 10) {
                        ForEach(jarvis.pendingEmailTasks) { task in
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(GhostTheme.cyan)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.subject)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("To: \(task.recipient) • \(task.summary)")
                                        .font(.system(size: 10))
                                        .foregroundColor(GhostTheme.textSecondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button(action: { jarvis.dispatchEmail(id: task.id) }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "paperplane.fill")
                                        Text("Send")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(GhostTheme.cyan)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(20)
                .cyberCardStyle()
                
                // API Keys Config Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("BUSINESS INTEGRATION API KEYS (VAPI.AI & RETELL AI)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.textSecondary)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Vapi.ai API Key")
                                .font(.system(size: 10))
                                .foregroundColor(GhostTheme.textSecondary)
                            SecureField("vapi_key_...", text: $jarvis.vapiApiKey)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(6)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Retell AI API Key")
                                .font(.system(size: 10))
                                .foregroundColor(GhostTheme.textSecondary)
                            SecureField("retell_key_...", text: $jarvis.retellApiKey)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(20)
                .cyberCardStyle()
            }
            .padding(24)
        }
        .background(GhostTheme.bgDark)
        .sheet(isPresented: $isShowingNewCallModal) {
            VStack(spacing: 16) {
                Text("Dispatch AI Voice Call")
                    .font(.headline)
                
                TextField("Contact Name (e.g. John Doe)", text: $targetContact)
                    .textFieldStyle(.roundedBorder)
                TextField("Phone Number (e.g. +1 415 555 0199)", text: $targetNumber)
                    .textFieldStyle(.roundedBorder)
                TextField("Call Instructions / Prompt for AI", text: $callPrompt)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    Button("Cancel") { isShowingNewCallModal = false }
                    Spacer()
                    Button("Start AI Call") {
                        jarvis.triggerCall(to: targetContact, number: targetNumber, prompt: callPrompt)
                        isShowingNewCallModal = false
                        targetContact = ""
                        targetNumber = ""
                        callPrompt = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(width: 380)
        }
    }
}
