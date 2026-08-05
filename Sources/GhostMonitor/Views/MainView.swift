import SwiftUI

public struct MainView: View {
    @State private var selection: NavigationItem = .dashboard
    @ObservedObject var coordinator: MonitoringCoordinator = .shared
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, coordinator: coordinator)
        } detail: {
            switch selection {
            case .dashboard:
                DashboardView()
            case .processes:
                ProcessListView()
            case .storage:
                ScrollView {
                    if let storage = coordinator.storage {
                        StorageSectionView(snapshot: storage)
                            .padding(16)
                    }
                }
            case .duplicateFinder:
                DuplicateFinderView()
            case .battery:
                ScrollView {
                    if let bat = coordinator.battery {
                        BatterySectionView(battery: bat)
                            .padding(16)
                    }
                }
            case .ghostAI:
                GhostAIView()
            case .jarvisAI:
                JarvisDashboardView()
            case .aiProviders:
                AIProvidersView()
            case .settings:
                SettingsView()
            case .cleaner:
                CleanerView()
            case .uninstaller:
                UninstallerView()
            case .optimizer:
                OptimizerView()
            case .systemMaintenance:
                SystemMaintenanceView()
            case .gamingBooster:
                GamingBoosterView()
            case .network:
                NetworkView()
            case .diskMapper:
                DiskMapperView()
            case .privacy:
                PrivacyView()
            case .privacyDashboard:
                PrivacyDashboardView()
            case .advBattery:
                AdvancedBatteryView()
            case .ntfsUnlocker:
                NTFSView()
            case .insomnia:
                InsomniaView()
            case .clipboard:
                ClipboardView()
            case .rawMouse:
                MouseView()
            case .snipper:
                SnipperView()
            case .crossDrop:
                CrossDropView()
            case .thermalGuardian:
                OverloadProtectorView()
            case .windowSnapper:
                SnapMasterView()
            case .spyCatcher:
                SpyCatcherView()
            case .dropVault:
                DropVaultMainView()
            case .killswitch:
                PrivacyKillswitchView()
            case .firewall:
                NetworkFirewallView()
            case .volumeMixer:
                VolumeMixerView()
            case .loginItems:
                LoginItemsView()
            case .usbGuard:
                USBGuardView()
            case .liveNetwork:
                LiveConnectionView()
            case .pingLatency:
                PingLatencyView()
            case .connectors:
                ConnectorsView()
            case .panicButton:
                GhostPanicView()
            case .rogueSentinel:
                RogueSentinelView()
            case .menuBarCollapser:
                MenuBarCollapserView()
            case .licensing:
                LicensingView()
            }
        }
        .background(GhostTheme.bgDark)
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            coordinator.isWindowVisible = true
        }
        .onDisappear {
            coordinator.isWindowVisible = false
        }
    }
}
