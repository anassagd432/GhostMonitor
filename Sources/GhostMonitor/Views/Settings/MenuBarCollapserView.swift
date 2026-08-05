import SwiftUI

public struct MenuBarCollapserView: View {
    @StateObject private var collapser = MenuBarCollapserService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GhostTheme.cyan.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .shadow(color: GhostTheme.cyan, radius: 12)
                        
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(GhostTheme.cyan)
                    }
                    
                    Text("Menu Bar Icon Collapser")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Hide unwanted menu bar icons behind a clean overflow toggle to prevent MacBook notch overlap.")
                        .font(.system(size: 13))
                        .foregroundColor(GhostTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                // Toggle Master Switch Card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MENU BAR OVERFLOW MANAGER")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        Text(collapser.isCollapserEnabled ? "Active • Collapsing Overflow Icons" : "Disabled")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(collapser.isCollapserEnabled ? GhostTheme.mint : GhostTheme.textSecondary)
                    }
                    Spacer()
                    
                    Toggle("", isOn: $collapser.isCollapserEnabled)
                        .toggleStyle(CyberToggleStyle())
                        .frame(width: 44)
                }
                .padding(20)
                .cyberCardStyle(glowing: collapser.isCollapserEnabled)
                
                // Items Configuration List
                VStack(alignment: .leading, spacing: 14) {
                    Text("MENU BAR ICON CATEGORIZATION")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    VStack(spacing: 10) {
                        ForEach(collapser.itemConfigs) { config in
                            HStack(spacing: 12) {
                                Image(systemName: iconForConfig(config.name))
                                    .font(.system(size: 16))
                                    .foregroundColor(GhostTheme.cyan)
                                    .frame(width: 24)
                                
                                Text(config.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Picker("", selection: Binding(
                                    get: { config.visibility },
                                    set: { collapser.updateVisibility(forName: config.name, to: $0) }
                                )) {
                                    ForEach(MenuBarItemVisibility.allCases, id: \.self) { vis in
                                        Text(vis.rawValue).tag(vis)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 160)
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
    
    private func iconForConfig(_ name: String) -> String {
        switch name {
        case "Ghost Monitor": return "ghost.fill"
        case "Wi-Fi & Network": return "wifi"
        case "Battery Status": return "battery.100.bolt"
        case "Spotlight & Siri": return "magnifyingglass"
        case "Clock & Date": return "clock.fill"
        case "Bluetooth Devices": return "bluetooth"
        case "Focus & Do Not Disturb": return "moon.fill"
        case "Time Machine Backup": return "clock.arrow.circlepath"
        default: return "app.badge.fill"
        }
    }
}
