import SwiftUI

public struct AdvancedBatteryView: View {
    @StateObject private var battery = AdvancedBatteryService.shared
    @ObservedObject private var settings = SettingsService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Header
                VStack(spacing: 10) {
                    Image(systemName: battery.chargeLimitEnabled ? "battery.75percent.bolt" : "battery.100.bolt")
                        .font(.system(size: 60))
                        .foregroundStyle(battery.chargeLimitEnabled ? .green : .secondary)
                        .animation(.easeInOut, value: battery.chargeLimitEnabled)
                    
                    Text("Advanced Battery")
                        .font(.title.bold())
                    
                    Text("Protect your MacBook's long-term battery health.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                
                // MARK: - Main Toggle Card
                VStack(spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Optimized Battery Charging")
                                .font(.headline)
                            Text("Uses Apple's built-in pmset to stop charging at ~80% when your Mac is plugged in for extended periods. This is the same feature as macOS System Settings → Battery Health.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { battery.chargeLimitEnabled },
                            set: { val in Task { await battery.toggleChargeLimit(val) } }
                        ))
                        .toggleStyle(.switch)
                        .tint(.green)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(14)
                    
                    // Status message
                    if !battery.statusMessage.isEmpty {
                        HStack(spacing: 8) {
                            Text(battery.statusMessage)
                                .font(.subheadline)
                                .foregroundColor(battery.statusMessage.hasPrefix("❌") ? .red : .secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeInOut, value: battery.statusMessage)
                    }
                }
                .padding(.horizontal, 30)
                
                // MARK: - How It Works
                VStack(alignment: .leading, spacing: 12) {
                    Label("How It Works", systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundColor(.cyan)
                    
                    infoRow(icon: "🔌", text: "When enabled, your Mac won't charge past ~80% if it's been plugged in for a long time.")
                    infoRow(icon: "🔋", text: "If you need a full charge for travel, simply disable it temporarily.")
                    infoRow(icon: "🛡️", text: "Requires your Mac password once to run the system command.")
                    infoRow(icon: "⚡️", text: "Command used: sudo pmset -a optimizebattery 1")
                }
                .padding(16)
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(14)
                .padding(.horizontal, 30)
                
                Spacer(minLength: 20)
            }
        }
    }
    
    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
