import SwiftUI

public struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    
    public init(viewModel: DashboardViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? DashboardViewModel())
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                // A. Cyber Top Header Bar
                CyberHeaderView(coordinator: viewModel.coordinator)
                
                // B. Quick Actions Row
                QuickActionsView()
                
                // Active Warnings Banner
                if !viewModel.coordinator.activeWarnings.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(viewModel.coordinator.activeWarnings, id: \.self) { warn in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(GhostTheme.magenta)
                                Text(warn)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GhostTheme.magenta.opacity(0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(GhostTheme.magenta.opacity(0.4), lineWidth: 1)
                    )
                }
                
                // C. Hero Cyber Grid (Live Real-Time Monitoring)
                HStack(alignment: .top, spacing: 16) {
                    // Real-Time Dynamic Memory Spline Chart
                    let mem = viewModel.coordinator.memory
                    let memoryUsed = Double(mem?.usedBytes ?? 0) / 1073741824.0
                    let memoryTotal = Double(mem?.totalBytes ?? 16 * 1024 * 1024 * 1024) / 1073741824.0
                    let currentPercentage = mem?.usedPercentage ?? 0.0
                    
                    // Extract real live history points from MonitoringCoordinator
                    let rawHistory = viewModel.coordinator.memoryHistory.values().map { $0.value }
                    let liveDataPoints: [Double] = {
                        if rawHistory.isEmpty {
                            return Array(repeating: currentPercentage, count: 10)
                        } else if rawHistory.count < 10 {
                            let pad = Array(repeating: rawHistory.first ?? currentPercentage, count: 10 - rawHistory.count)
                            return pad + rawHistory
                        } else {
                            return Array(rawHistory.suffix(12))
                        }
                    }()
                    
                    CyberChartView(
                        title: "Memory Usage",
                        currentUsageGB: memoryUsed,
                        totalGB: memoryTotal,
                        dataPoints: liveDataPoints
                    )
                    
                    // Real-Time CPU Load Ring Gauge
                    let cpuUsage = viewModel.coordinator.cpu?.totalUsagePercentage ?? 0.0
                    let chipName = viewModel.coordinator.hardware?.chipName ?? "Apple Silicon"
                    let coreCount = viewModel.coordinator.hardware?.totalCores ?? 8
                    
                    CyberGaugeView(
                        title: "CPU Load",
                        percentage: cpuUsage,
                        subtitle: "\(chipName) | \(coreCount) Cores"
                    )
                    .frame(width: 260)
                }
                
                // D. Cyber Trio Cards (Live Real-Time Traffic & Activity)
                HStack(alignment: .top, spacing: 16) {
                    let upKbps = (viewModel.coordinator.network?.totalUploadSpeed ?? 0) / 1024.0
                    let downKbps = (viewModel.coordinator.network?.totalDownloadSpeed ?? 0) / 1024.0
                    NetworkSpectrumCard(upKbps: upKbps, downKbps: downKbps)
                    
                    PrivacyStatusCard()
                    
                    ThreadActivityCard()
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // E. Detailed Memory Breakdown
                if let memorySnapshot = viewModel.coordinator.memory {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MEMORY BREAKDOWN & PRESSURE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        MemoryBreakdownView(memory: memorySnapshot)
                    }
                }
                
                // F. Storage Volumes Breakdown
                if let storageSnapshot = viewModel.coordinator.storage {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("STORAGE VOLUMES & SPEEDS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        StorageSectionView(snapshot: storageSnapshot)
                    }
                }
                
                // G. Network Interfaces
                if let networkSnapshot = viewModel.coordinator.network {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NETWORK INTERFACES & TRAFFIC")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        NetworkSectionView(snapshot: networkSnapshot)
                    }
                }
                
                // H. Battery & Thermal Status
                HStack(alignment: .top, spacing: 16) {
                    if let batterySnapshot = viewModel.coordinator.battery, batterySnapshot.isPresent {
                        BatterySectionView(battery: batterySnapshot)
                    }
                    if let thermalSnapshot = viewModel.coordinator.thermal {
                        ThermalSectionView(thermal: thermalSnapshot)
                    }
                }
            }
            .padding(16)
        }
        .background(GhostTheme.bgDark)
    }
}

public struct QuickActionsView: View {
    @StateObject private var insomnia = InsomniaService.shared
    @StateObject private var killswitch = PrivacyKillswitchService.shared
    @StateObject private var battery = AdvancedBatteryService.shared
    @StateObject private var gaming = GamingBoosterService.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            quickButton(title: "Insomnia", icon: "cup.and.saucer.fill", isOn: insomnia.isAwake, color: .orange) {
                insomnia.toggleInsomnia()
            }
            
            quickButton(title: "Mic Mute", icon: "mic.slash.fill", isOn: killswitch.isMicBlocked, color: GhostTheme.magenta) {
                Task { await killswitch.toggleMicBlock() }
            }
            
            quickButton(title: "Bat Limit", icon: "battery.100.bolt", isOn: battery.chargeLimitEnabled, color: GhostTheme.mint) {
                Task {
                    if battery.chargeLimitEnabled { await battery.toggleChargeLimit(false) }
                    else { await battery.toggleChargeLimit(true) }
                }
            }
            
            quickButton(title: "Game Boost", icon: "gamecontroller.fill", isOn: gaming.isBoosted, color: GhostTheme.purple) {
                Task {
                    if gaming.isBoosted { await gaming.unboost() }
                    else { await gaming.boost() }
                }
            }
        }
    }
    
    private func quickButton(title: String, icon: String, isOn: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title).fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isOn ? color : Color.white.opacity(0.06))
            .foregroundColor(isOn ? .black : .white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isOn ? color : GhostTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: isOn ? color.opacity(0.4) : Color.clear, radius: 6)
        }
        .buttonStyle(.plain)
    }
}
