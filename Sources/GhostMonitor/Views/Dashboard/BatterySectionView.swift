import SwiftUI

public struct BatterySectionView: View {
    let battery: BatterySnapshot
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Battery & Power Subsystem", systemImage: battery.isCharging ? "battery.100.bolt" : "battery.100")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("Condition: \(battery.condition)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(battery.condition == "Normal" ? .green : .orange)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 10) {
                cell(title: "Power Source", value: battery.powerSource)
                cell(title: "State", value: battery.isCharging ? "Charging" : "Discharging")
                if let maxHealth = battery.maxCapacityPercentage {
                    cell(title: "Maximum Capacity", value: String(format: "%.1f%%", maxHealth))
                }
                if let cycle = battery.cycleCount {
                    cell(title: "Cycle Count", value: "\(cycle)")
                }
                if let design = battery.designCapacity {
                    cell(title: "Design Capacity", value: "\(design) mAh")
                }
                if let watts = battery.powerDrawWatts {
                    cell(title: "Power Draw", value: String(format: "%.2f W", watts))
                }
                if let temp = battery.temperatureCelsius {
                    cell(title: "Battery Temp", value: String(format: "%.1f °C", temp))
                }
                if let remaining = battery.timeRemainingSeconds {
                    cell(title: "Time Remaining", value: TimeFormatter.formatShortDuration(remaining))
                }
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
    
    private func cell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(6)
    }
}
