import SwiftUI

public struct RogueSentinelView: View {
    @StateObject private var sentinel = RogueSentinelService.shared
    
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
                        
                        Image(systemName: "shield.pattern.checkered")
                            .font(.system(size: 38))
                            .foregroundColor(GhostTheme.magenta)
                    }
                    
                    Text("AI Threat Sentinel")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Continuous on-device AI process behavioral monitoring. Detects ransomware, zero-day key access, and rogue background miners.")
                        .font(.system(size: 13))
                        .foregroundColor(GhostTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                // Active Sentinel Status Card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI BEHAVIORAL SENTINEL STATUS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        Text(sentinel.isSentinelActive ? "ACTIVE • Monitoring \(sentinel.scannedProcessCount) System Processes" : "Disabled")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(sentinel.isSentinelActive ? GhostTheme.mint : Color.red)
                    }
                    Spacer()
                    
                    Toggle("", isOn: $sentinel.isSentinelActive)
                        .toggleStyle(CyberToggleStyle())
                        .frame(width: 44)
                }
                .padding(20)
                .cyberCardStyle(glowing: sentinel.isSentinelActive)
                
                // Threat Alerts Feed
                VStack(alignment: .leading, spacing: 14) {
                    Text("DETECTED BEHAVIORAL THREAT ALERTS (\(sentinel.activeThreats.count))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    VStack(spacing: 12) {
                        ForEach(sentinel.activeThreats) { alert in
                            HStack(spacing: 14) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(alert.isQuarantined ? GhostTheme.mint : GhostTheme.magenta)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(alert.processName)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("PID: \(alert.pid)")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(GhostTheme.textSecondary)
                                        Spacer()
                                        Text("Risk Score: \(alert.riskScore)/100")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(alert.riskScore > 80 ? Color.red : Color.orange)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.white.opacity(0.08))
                                            .cornerRadius(4)
                                    }
                                    
                                    Text(alert.threatType)
                                        .font(.system(size: 11))
                                        .foregroundColor(GhostTheme.textSecondary)
                                }
                                
                                Button(action: { sentinel.quarantineProcess(id: alert.id) }) {
                                    Text(alert.isQuarantined ? "QUARANTINED" : "QUARANTINE")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(alert.isQuarantined ? .black : .white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(alert.isQuarantined ? GhostTheme.mint : GhostTheme.magenta)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                .disabled(alert.isQuarantined)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(20)
                .cyberCardStyle()
            }
            .padding(24)
        }
        .background(GhostTheme.bgDark)
    }
}
