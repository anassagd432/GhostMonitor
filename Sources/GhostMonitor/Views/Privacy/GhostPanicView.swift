import SwiftUI

public struct GhostPanicView: View {
    @StateObject private var panic = GhostPanicService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GhostTheme.magenta.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .shadow(color: GhostTheme.magenta, radius: 12)
                        
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 40))
                            .foregroundColor(GhostTheme.magenta)
                    }
                    
                    Text("Ghost Panic Button")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Instantly lock your screen, mute sound, block mic/cam, and wipe clipboard with a single hotkey.")
                        .font(.system(size: 13))
                        .foregroundColor(GhostTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                // Hotkey Card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GLOBAL PANIC HOTKEY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        Text("⌘ + ⇧ + L  (Cmd + Shift + L)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    
                    Toggle("Active", isOn: $panic.isEnabled)
                        .toggleStyle(CyberToggleStyle())
                        .frame(width: 100)
                }
                .padding(20)
                .cyberCardStyle(glowing: panic.isEnabled)
                
                // Panic Actions Configuration Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("AUTOMATED PANIC ACTIONS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    VStack(spacing: 12) {
                        actionRow(title: "Lock Display & Screen", subtitle: "Triggers immediate display sleep & screen lock", icon: "lock.fill", isOn: $panic.lockScreenOnPanic)
                        actionRow(title: "Mute System Audio", subtitle: "Instantly sets system volume to 0 and mutes output", icon: "speaker.slash.fill", isOn: $panic.muteAudioOnPanic)
                        actionRow(title: "Clear Clipboard History", subtitle: "Wipes sensitive copied text & passwords from clipboard", icon: "doc.on.clipboard", isOn: $panic.clearClipboardOnPanic)
                        actionRow(title: "Block Microphone & Camera", subtitle: "Engages hardware killswitches immediately", icon: "mic.slash.fill", isOn: $panic.blockMicCamOnPanic)
                        actionRow(title: "Hide Other Applications", subtitle: "Minimizes and hides background windows", icon: "eye.slash.fill", isOn: $panic.hideAppsOnPanic)
                    }
                }
                .padding(20)
                .cyberCardStyle()
                
                // Trigger Test Button
                Button(action: {
                    panic.triggerPanicMode()
                }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("TRIGGER PANIC MODE NOW")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(GhostTheme.magenta)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: GhostTheme.magenta.opacity(0.6), radius: 10)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                
                if let last = panic.lastPanicTriggered {
                    Text("Last triggered: \(last.formatted(date: .omitted, time: .standard))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(GhostTheme.textSecondary)
                }
            }
            .padding(24)
        }
        .background(GhostTheme.bgDark)
    }
    
    private func actionRow(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isOn.wrappedValue ? GhostTheme.cyan : GhostTheme.textSecondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(GhostTheme.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(CyberToggleStyle())
                .frame(width: 44)
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}
