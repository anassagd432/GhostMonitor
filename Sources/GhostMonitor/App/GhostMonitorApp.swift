import SwiftUI
import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Always run in the background (Menu Bar mode)
        return false
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        MonitoringCoordinator.shared.stopMonitoring()
    }
}

@main
struct GhostMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var coordinator = MonitoringCoordinator.shared
    @StateObject private var settings = SettingsService.shared
    
    init() {
        // 1. Run Anti-Tamper checks immediately before anything else loads
        AntiTamper.runChecks()
        
        MonitoringCoordinator.shared.startMonitoring()
        
        // 2. Validate Trial / License state
        Task {
            await LicenseValidator.shared.checkTrialOrLicenseOnLaunch()
        }
        
        // Register to start at login (will throw if already registered, which is fine)
        try? SMAppService.mainApp.register()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
        }
        
        MenuBarExtra(isInserted: Binding(
            get: { settings.enableMenuBarExtra },
            set: { newValue in
                if settings.enableMenuBarExtra != newValue {
                    settings.enableMenuBarExtra = newValue
                }
            }
        )) {
            MenuBarControlCenterView()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bolt.shield.fill")
                
                let parts: [String] = [
                    settings.showCpuInMenuBar && coordinator.cpu != nil ? "CPU \(String(format: "%.0f%%", coordinator.cpu!.totalUsagePercentage))" : nil,
                    settings.showRamInMenuBar && coordinator.memory != nil ? "RAM \(String(format: "%.0f%%", coordinator.memory!.usedPercentage))" : nil,
                    settings.showSsdInMenuBar && coordinator.storage != nil ? "SSD \(String(format: "%.0f%%", coordinator.storage!.primaryUsagePercentage))" : nil,
                    settings.showBatteryInMenuBar && coordinator.battery?.isPresent == true ? "BAT \(String(format: "%.0f%%", coordinator.battery!.percentage))" : nil,
                    settings.showThermalInMenuBar && coordinator.battery?.temperatureCelsius != nil ? "\(Int(coordinator.battery!.temperatureCelsius!))°" : (settings.showThermalInMenuBar && coordinator.thermal != nil ? coordinator.thermal!.thermalStateLabel : nil)
                ].compactMap { $0 }
                
                if !parts.isEmpty {
                    Text(parts.joined(separator: " "))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarControlCenterView: View {
    @ObservedObject private var insomnia = InsomniaService.shared
    @ObservedObject private var killswitch = PrivacyKillswitchService.shared
    @ObservedObject private var mouse = MouseService.shared
    @ObservedObject private var battery = AdvancedBatteryService.shared
    @ObservedObject private var crossdrop = CrossDropService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bolt.shield.fill")
                    .foregroundColor(.cyan)
                Text("Ghost Control Center")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
            }
            
            Divider()
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                Button(action: { insomnia.toggleInsomnia() }) {
                    Label("Anti-Sleep", systemImage: insomnia.isAwake ? "cup.and.saucer.fill" : "cup.and.saucer")
                        .foregroundColor(insomnia.isAwake ? .yellow : .primary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: { killswitch.toggleMicBlock() }) {
                    Label("Mic Block", systemImage: killswitch.isMicBlocked ? "mic.slash.fill" : "mic.fill")
                        .foregroundColor(killswitch.isMicBlocked ? .red : .primary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: { mouse.setRawInput(!mouse.isRawInputEnabled) }) {
                    Label("Raw Mouse", systemImage: mouse.isRawInputEnabled ? "computermouse.fill" : "computermouse")
                        .foregroundColor(mouse.isRawInputEnabled ? .green : .primary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    Task { await battery.toggleChargeLimit(!battery.chargeLimitEnabled) }
                }) {
                    Label("Bat Limit", systemImage: battery.chargeLimitEnabled ? "battery.100.bolt" : "battery.100")
                        .foregroundColor(battery.chargeLimitEnabled ? .blue : .primary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    if !crossdrop.isRunning {
                        crossdrop.startServer()
                    }
                }) {
                    Label(crossdrop.isRunning ? "Drop: On" : "CrossDrop", systemImage: "network")
                        .foregroundColor(crossdrop.isRunning ? .green : .primary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            
            Divider()
            
            MenuBarVolumeMixerView()
            
            Divider()
            
            Button("Open Ghost Monitor Dashboard") {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows {
                    if window.canBecomeMain {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Button("Quit Ghost Monitor") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 300)
    }
}

struct MenuBarVolumeMixerView: View {
    @ObservedObject private var mixer = VolumeMixerService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Volume Mixer")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            
            if mixer.appVolumes.isEmpty {
                Text("No active media apps")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(mixer.appVolumes.keys.sorted().prefix(5)), id: \.self) { appName in
                    HStack {
                        Text(appName)
                            .font(.system(size: 10))
                            .frame(width: 80, alignment: .leading)
                            .lineLimit(1)
                        
                        let binding = Binding<Double>(
                            get: { mixer.appVolumes[appName] ?? 1.0 },
                            set: { mixer.setVolume(for: appName, to: $0) }
                        )
                        
                        Slider(value: binding, in: 0...1)
                            .controlSize(.mini)
                            .tint(.blue)
                        
                        Text("\(Int(binding.wrappedValue * 100))%")
                            .font(.system(size: 9))
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

