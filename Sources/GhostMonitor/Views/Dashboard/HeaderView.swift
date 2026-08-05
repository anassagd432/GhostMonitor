import SwiftUI

public struct HeaderView: View {
    @ObservedObject var coordinator: MonitoringCoordinator
    @ObservedObject var settings = SettingsService.shared
    
    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon / App Title
            HStack(spacing: 10) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ghost Monitor")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if let hw = coordinator.hardware {
                        Text("\(hw.friendlyModelName) • \(hw.chipName)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Hardware Metadata Badges
            if let hw = coordinator.hardware {
                HStack(spacing: 12) {
                    Label(hw.macosVersion, systemImage: "applelogo")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Label(TimeFormatter.formatUptime(hw.uptimeSeconds), systemImage: "clock.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .help("System Uptime")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Refresh Interval Selector
            HStack(spacing: 6) {
                Text("Refresh:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("\(Int(settings.refreshIntervalSeconds))s")
                    .frame(width: 65)
            }
            
            // System Status Badge
            StatusBadge(level: coordinator.overallStatus, label: coordinator.overallStatus.rawValue)
            
            // Live Pulse Indicator
            HStack(spacing: 5) {
                Circle()
                    .fill(coordinator.isMonitoringActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(coordinator.isMonitoringActive ? "Live" : "Paused")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
}
