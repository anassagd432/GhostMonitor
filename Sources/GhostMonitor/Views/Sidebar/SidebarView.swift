import SwiftUI

public enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case ghostAI = "Ghost AI Assistant"
    case jarvisAI = "JARVIS Voice OS"
    case processes = "Processes"
    case storage = "Storage"
    case duplicateFinder = "Duplicate Finder"
    case battery = "Battery"
    
    // Tools
    case cleaner = "PC Cleaner"
    case uninstaller = "Uninstaller"
    case optimizer = "Optimizer"
    case systemMaintenance = "System Tuneup"
    case gamingBooster = "Gaming Booster"
    case network = "Network & Firewall"
    case diskMapper = "Disk Mapper"
    case privacy = "Privacy & Security"
    case privacyDashboard = "Privacy Dashboard"
    case advBattery = "Advanced Battery"
    case ntfsUnlocker = "NTFS Unlocker"
    
    // New All-In-One Utilities
    case insomnia = "Insomnia Mode"
    case clipboard = "Clipboard Vault"
    case rawMouse = "Raw Mouse Input"
    case snipper = "Smart Snipper"
    case crossDrop = "Cross-Drop"
    case thermalGuardian = "Thermal Guardian"
    case windowSnapper = "Snap-Master"
    case spyCatcher = "Spy-Catcher"
    case dropVault = "Drop Vault"
    case killswitch = "Killswitch"
    case firewall = "Firewall"
    case volumeMixer = "Volume Mixer"
    case loginItems = "Login Items"
    case usbGuard = "USB Guard"
    case liveNetwork = "Live Connections"
    case pingLatency = "Ping & Latency Visualizer"
    case connectors = "API Connectors"
    case panicButton = "Ghost Panic Button"
    case rogueSentinel = "AI Threat Sentinel"
    case menuBarCollapser = "Menu Bar Collapser"
    case licensing = "Pro License"
    
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var systemImage: String {
        switch self {
        case .dashboard: return "gauge.medium"
        case .ghostAI: return "sparkles"
        case .jarvisAI: return "cpu.fill"
        case .processes: return "list.bullet.rectangle"
        case .storage: return "internaldrive"
        case .duplicateFinder: return "doc.on.doc.fill"
        case .battery: return "battery.100"
        case .cleaner: return "trash"
        case .uninstaller: return "xmark.bin.fill"
        case .optimizer: return "slider.horizontal.3"
        case .systemMaintenance: return "wrench.and.screwdriver.fill"
        case .gamingBooster: return "gamecontroller.fill"
        case .network: return "network.badge.shield.half.filled"
        case .diskMapper: return "chart.pie.fill"
        case .privacy: return "lock.shield.fill"
        case .privacyDashboard: return "eye.trianglebadge.exclamationmark.fill"
        case .advBattery: return "battery.100.bolt"
        case .ntfsUnlocker: return "externaldrive.fill.badge.plus"
        case .insomnia: return "cup.and.saucer.fill"
        case .clipboard: return "doc.on.clipboard.fill"
        case .rawMouse: return "cursorarrow"
        case .snipper: return "text.viewfinder"
        case .crossDrop: return "antenna.radiowaves.left.and.right"
        case .thermalGuardian: return "shield.lefthalf.filled"
        case .windowSnapper: return "uiwindow.split.2x1"
        case .spyCatcher: return "magnifyingglass.circle.fill"
        case .dropVault: return "shippingbox.fill"
        case .killswitch: return "lock.shield.fill"
        case .firewall: return "network.slash"
        case .volumeMixer: return "speaker.wave.2.fill"
        case .loginItems:  return "list.bullet.rectangle.portrait.fill"
        case .usbGuard:    return "cable.connector.slash"
        case .liveNetwork: return "network.badge.shield.half.filled"
        case .pingLatency: return "waveform.path.ecg"
        case .connectors: return "link.badge.plus"
        case .panicButton: return "exclamationmark.shield.fill"
        case .rogueSentinel: return "shield.pattern.checkered"
        case .menuBarCollapser: return "line.3.horizontal.decrease.circle.fill"
        case .licensing:   return "key.fill"
        case .settings:    return "gear"
        }
    }
}

public struct SidebarView: View {
    @Binding var selection: NavigationItem
    @ObservedObject var coordinator: MonitoringCoordinator = .shared
    
    public var body: some View {
        List(selection: $selection) {
            Section(header: Text("GHOST MONITOR").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(GhostTheme.textSecondary)) {
                ForEach(NavigationItem.allCases) { item in
                    NavigationLink(value: item) {
                        HStack(spacing: 10) {
                            Image(systemName: item.systemImage)
                                .font(.system(size: 14))
                                .foregroundColor(selection == item ? GhostTheme.cyan : GhostTheme.textSecondary)
                                .shadow(color: selection == item ? GhostTheme.cyan.opacity(0.8) : Color.clear, radius: 4)
                                .frame(width: 20)
                            
                            Text(item.rawValue)
                                .font(.system(size: 13, weight: selection == item ? .bold : .regular))
                                .foregroundColor(selection == item ? .white : GhostTheme.textSecondary)
                            
                            Spacer()
                            
                            if item == .processes && !coordinator.processes.isEmpty {
                                Text("\(coordinator.processes.count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(GhostTheme.cyan.opacity(0.2))
                                    .foregroundColor(GhostTheme.cyan)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .background(GhostTheme.bgDark)
        .frame(minWidth: 190, idealWidth: 210, maxWidth: 250)
    }
}
