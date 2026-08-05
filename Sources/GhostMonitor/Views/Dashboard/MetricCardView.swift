import SwiftUI

public struct MetricCardView: View {
    @ObservedObject var coordinator: MonitoringCoordinator
    
    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 14)], spacing: 14) {
            
            // 1. CPU Card
            if let cpu = coordinator.cpu {
                let status = SettingsService.shared.thresholds.evaluateCPU(cpu.totalUsagePercentage)
                GaugeCard(
                    title: "CPU Usage",
                    systemImage: "cpu",
                    valueString: String(format: "%.0f%%", cpu.totalUsagePercentage),
                    statusLevel: status,
                    subtitle: "Load: \(String(format: "%.2f", cpu.loadAvg1m))",
                    tooltipText: "Calculated from aggregate processor tick deltas."
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("P-Cores: \(String(format: "%.0f%%", cpu.pCoreUsagePercentage))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("E-Cores: \(String(format: "%.0f%%", cpu.eCoreUsagePercentage))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        SparklineChart(
                            points: coordinator.cpuHistory.values().suffix(30),
                            color: status == .critical ? .red : (status == .warning ? .orange : .blue),
                            height: 35
                        )
                    }
                }
            }
            
            // 2. Unified Memory Card
            if let mem = coordinator.memory {
                let status = SettingsService.shared.thresholds.evaluateMemory(mem.usedPercentage)
                GaugeCard(
                    title: "Unified Memory",
                    systemImage: "memorychip",
                    valueString: String(format: "%.0f%%", mem.usedPercentage),
                    statusLevel: status,
                    subtitle: "\(ByteFormatter.formatBytes(mem.usedBytes)) / \(ByteFormatter.formatBytes(mem.totalBytes))",
                    tooltipText: "Total memory used excluding reclaimable file caches."
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Wired: \(ByteFormatter.formatBytes(mem.wiredBytes))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Swap: \(ByteFormatter.formatBytes(mem.swapUsedBytes))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        SparklineChart(
                            points: coordinator.memoryHistory.values().suffix(30),
                            color: .purple,
                            height: 35
                        )
                    }
                }
            }
            
            // 3. Storage Card
            if let storage = coordinator.storage {
                let status = SettingsService.shared.thresholds.evaluateStorage(storage.primaryUsagePercentage)
                GaugeCard(
                    title: "Storage",
                    systemImage: "internaldrive",
                    valueString: String(format: "%.0f%%", storage.primaryUsagePercentage),
                    statusLevel: status,
                    subtitle: "\(ByteFormatter.formatBytes(storage.totalUsedBytes)) / \(ByteFormatter.formatBytes(storage.totalCapacityBytes))",
                    tooltipText: "Primary internal APFS volume usage."
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Read: \(ByteFormatter.formatSpeed(storage.aggregateReadSpeed))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Write: \(ByteFormatter.formatSpeed(storage.aggregateWriteSpeed))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        SparklineChart(
                            points: coordinator.diskReadHistory.values().suffix(30),
                            color: .green,
                            height: 35
                        )
                    }
                }
            }
            
            // 4. Network Card
            if let net = coordinator.network {
                GaugeCard(
                    title: "Network Activity",
                    systemImage: "network",
                    valueString: ByteFormatter.formatSpeed(net.totalDownloadSpeed),
                    statusLevel: .normal,
                    subtitle: "DL Speed",
                    tooltipText: "Current active network interface throughput."
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("UL: \(ByteFormatter.formatSpeed(net.totalUploadSpeed))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Interface: \(net.primaryInterfaceName)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        SparklineChart(
                            points: coordinator.networkDlHistory.values().suffix(30),
                            color: .cyan,
                            height: 35
                        )
                    }
                }
            }
            
            // 5. Battery Card
            if let bat = coordinator.battery, bat.isPresent {
                GaugeCard(
                    title: "Battery",
                    systemImage: bat.isCharging ? "battery.100.bolt" : "battery.100",
                    valueString: String(format: "%.0f%%", bat.percentage),
                    statusLevel: bat.percentage < 20 ? .warning : .normal,
                    subtitle: bat.isCharging ? "Charging (\(bat.powerSource))" : bat.powerSource,
                    tooltipText: "Native AppleSmartBattery power source metrics."
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            if let cycles = bat.cycleCount {
                                Text("Cycles: \(cycles)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if let watts = bat.powerDrawWatts {
                                Text(String(format: "%.1f W", watts))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        SparklineChart(
                            points: coordinator.batteryHistory.values().suffix(30),
                            color: .green,
                            height: 35
                        )
                    }
                }
            }
            
            // 6. Thermal Card
            if let therm = coordinator.thermal {
                GaugeCard(
                    title: "Thermal Pressure",
                    systemImage: "thermometer.medium",
                    valueString: therm.thermalStateLabel,
                    statusLevel: therm.statusLevel,
                    subtitle: therm.isFanless ? "Fanless Mac" : "Active Cooling",
                    tooltipText: "Native macOS ProcessInfo thermal pressure state."
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(therm.isThrottling ? "Throttling Active" : "No Throttling")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(therm.isThrottling ? .red : .secondary)
                            Spacer()
                            if therm.isFanless {
                                Label("Passive", systemImage: "fan.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        SparklineChart(
                            points: coordinator.thermalHistory.values().suffix(30),
                            color: therm.statusLevel == .critical ? .red : (therm.statusLevel == .warning ? .orange : .blue),
                            height: 35
                        )
                    }
                }
            }
            
            // 7. GPU Utilization Card (Public API Policy Compliant)
            if let gpu = coordinator.gpu {
                GaugeCard(
                    title: "GPU Utilization",
                    systemImage: "display",
                    valueString: gpu.isAvailable ? String(format: "%.0f%%", gpu.usagePercentage ?? 0) : "N/A",
                    statusLevel: .normal,
                    subtitle: gpu.isAvailable ? "Active" : "Public API Restricted",
                    tooltipText: gpu.statusMessage
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(gpu.statusMessage)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        Rectangle()
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 35)
                            .cornerRadius(4)
                            .overlay(
                                Text("No Fake Data Policy Enforced")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            )
                    }
                }
            }
        }
    }
}
