import SwiftUI

public struct GhostControlCenterView: View {
    @State private var isExpanded = false
    @State private var isHovering = false
    @State private var selectedTab: ControlCenterTab = .media
    
    @ObservedObject private var mixer = VolumeMixerService.shared
    @ObservedObject private var vault = DropVaultService.shared
    @ObservedObject private var monitor = MonitoringCoordinator.shared
    
    enum ControlCenterTab: String, CaseIterable {
        case media = "Media"
        case stats = "Stats"
        case mixer = "Mixer"
        case vault = "Vault"
        case display = "Display"
        
        var icon: String {
            switch self {
            case .media: return "play.circle.fill"
            case .stats: return "speedometer"
            case .mixer: return "slider.horizontal.3"
            case .vault: return "shippingbox.fill"
            case .display: return "display"
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 25 : 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: isExpanded ? 25 : 20, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                VStack(spacing: 0) {
                    // Collapsed / Header State
                    HStack(spacing: 12) {
                        Image(systemName: "ghost.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .symbolEffect(.bounce, value: isHovering)
                        
                        if isExpanded {
                            // Tab Selector
                            HStack(spacing: 15) {
                                ForEach(ControlCenterTab.allCases, id: \.self) { tab in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedTab = tab
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: tab.icon)
                                            Text(tab.rawValue)
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(selectedTab == tab ? Color.white.opacity(0.2) : Color.clear)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(selectedTab == tab ? .white : .gray)
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    isExpanded = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Text("Ghost Monitor")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, isExpanded ? 20 : 16)
                    .frame(height: 40)
                    
                    // Expanded Content
                    if isExpanded {
                        VStack {
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            
                            switch selectedTab {
                            case .media:
                                NowPlayingWidget()
                                    .padding(.horizontal, 20)
                            case .stats:
                                statsView
                            case .mixer:
                                mixerView
                            case .vault:
                                vaultView
                            case .display:
                                displayView
                            }
                        }
                        .padding(.bottom, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .frame(width: isExpanded ? 400 : 160, height: isExpanded ? 250 : 40)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isExpanded)
            .onTapGesture {
                if !isExpanded {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isExpanded = true
                    }
                }
            }
            .onHover { hovering in
                isHovering = hovering
            }
            // Add negative padding if you want it to truly touch the menu bar without any gap
            .padding(.top, 0) 
            
            Spacer()
        }
        .frame(width: 400, height: 400) // Ensure the whole view fills the NSPanel
    }
    
    // MARK: - Tab Views
    
    private var statsView: some View {
        VStack(spacing: 15) {
            HStack {
                statBox(title: "CPU", value: "\(Int(monitor.cpu?.totalUsagePercentage ?? 0))%", color: .cyan, icon: "cpu")
                statBox(title: "RAM", value: "\(Int((monitor.memory?.usedPercentage ?? 0)))%", color: .purple, icon: "memorychip")
            }
            HStack {
                statBox(title: "TEMP", value: "\(Int(monitor.battery?.temperatureCelsius ?? 0))°C", color: .orange, icon: "thermometer.medium")
                statBox(title: "SSD", value: "\(Int(monitor.storage?.primaryUsagePercentage ?? 0))%", color: .green, icon: "internaldrive")
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func statBox(title: String, value: String, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var mixerView: some View {
        VStack(spacing: 12) {
            if mixer.appVolumes.isEmpty {
                Text("No active media apps")
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(mixer.appVolumes.keys.sorted().prefix(5)), id: \.self) { appName in
                            HStack {
                                Text(appName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 80, alignment: .leading)
                                    .lineLimit(1)
                                
                                let binding = Binding<Double>(
                                    get: { mixer.appVolumes[appName] ?? 1.0 },
                                    set: { mixer.setVolume(for: appName, to: $0) }
                                )
                                
                                Slider(value: binding, in: 0...1)
                                    .tint(.blue)
                                
                                Text("\(Int(binding.wrappedValue * 100))%")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 35, alignment: .trailing)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 120)
            }
        }
    }
    
    private var vaultView: some View {
        VStack {
            if vault.stashedItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    Text("Drag files here to stash them")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(vault.stashedItems.enumerated()), id: \.element) { index, url in
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.blue)
                                Text(url.lastPathComponent)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button(action: {
                                    vault.removeItem(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .onDrag {
                                NSItemProvider(object: url as NSURL)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 120)
            }
        }
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            for provider in providers {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data,
                       let urlString = String(data: data, encoding: .utf8),
                       let url = URL(string: urlString) {
                        DispatchQueue.main.async {
                            vault.addItems([url])
                        }
                    }
                }
            }
            return true
        }
    }
    
    private var displayView: some View {
        VStack(spacing: 12) {
            Text("HiDPI Retina Scaler")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Text("Force macOS to expose hidden 4K/5K Scaled Resolutions (requires restart).")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: {
                Task {
                    do {
                        try await DisplayManagerService.shared.unlockHiDPI()
                        // Provide some user feedback (in a real app, maybe an alert)
                        print("HiDPI unlocked. Restart required.")
                    } catch {
                        print("Failed: \(error)")
                    }
                }
            }) {
                Text("Unlock HiDPI Resolutions")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                DisplayManagerService.shared.openDisplaySettings()
            }) {
                Text("Open Apple Display Settings")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
}
