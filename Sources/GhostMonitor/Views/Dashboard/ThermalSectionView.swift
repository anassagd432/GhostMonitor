import SwiftUI

public struct ThermalSectionView: View {
    let thermal: ThermalSnapshot
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Thermal Subsystem & Cooling", systemImage: "thermometer.medium")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if thermal.isFanless {
                    HStack(spacing: 4) {
                        Image(systemName: "fan.fill")
                            .font(.system(size: 10))
                        Text("Fanless Hardware")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ProcessInfo Thermal State")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    StatusBadge(level: thermal.statusLevel, label: thermal.thermalStateLabel)
                }
                
                Divider()
                    .frame(height: 36)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Thermal Throttling")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(thermal.isThrottling ? "Throttling Active" : "Normal Operating Range")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(thermal.isThrottling ? .red : .green)
                }
                
                Spacer()
                
                if thermal.isFanless {
                    Text("This Mac operates with 100% silent passive cooling. Zero mechanical fan speeds.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 240)
                }
            }
            .padding(10)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(8)
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
}
