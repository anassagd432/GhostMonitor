import SwiftUI

public struct HUDView: View {
    @ObservedObject var coordinator = MonitoringCoordinator.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.cyan)
                    .frame(width: 20)
                Text("CPU:")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f%%", coordinator.cpu?.totalUsagePercentage ?? 0))
                    .font(.system(.caption, design: .monospaced).bold())
            }
            
            HStack {
                Image(systemName: "memorychip")
                    .foregroundColor(.purple)
                    .frame(width: 20)
                Text("RAM:")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f GB", Double(coordinator.memory?.usedBytes ?? 0) / 1_000_000_000))
                    .font(.system(.caption, design: .monospaced).bold())
            }
            
            if let bat = coordinator.battery {
                HStack {
                    Image(systemName: bat.isCharging ? "bolt.fill" : "battery.100")
                        .foregroundColor(bat.isCharging ? .green : .orange)
                        .frame(width: 20)
                    Text("BAT:")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(bat.percentage)%")
                        .font(.system(.caption, design: .monospaced).bold())
                }
            }
        }
        .padding(16)
        .frame(width: 250, height: 120)
    }
}
