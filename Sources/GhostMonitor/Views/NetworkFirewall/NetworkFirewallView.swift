import SwiftUI

public struct NetworkFirewallView: View {
    @StateObject private var firewall = NetworkFirewallService.shared
    @State private var isTargeted = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - Header
            VStack(spacing: 8) {
                Image(systemName: "network.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                Text("App Network Firewall")
                    .font(.title.bold())
                Text("Drag and drop any .app to completely block it from accessing the internet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            .padding(.top, 24)
            
            // MARK: - Drop Zone
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isTargeted ? Color.red : Color.secondary.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2.5, dash: [10])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isTargeted ? Color.red.opacity(0.08) : Color.clear)
                    )
                    .frame(height: 110)
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)
                
                VStack(spacing: 8) {
                    Image(systemName: isTargeted ? "xmark.shield.fill" : "arrow.down.app")
                        .font(.system(size: 28))
                        .foregroundColor(isTargeted ? .red : .secondary)
                    Text(isTargeted ? "Release to Block" : "Drop App Here to Block")
                        .font(.headline)
                        .foregroundColor(isTargeted ? .red : .secondary)
                }
            }
            .padding(.horizontal, 30)
            .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers in
                for provider in providers {
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                        if let data = item as? Data,
                           let urlString = String(data: data, encoding: .utf8),
                           let url = URL(string: urlString) {
                            DispatchQueue.main.async { firewall.blockApp(at: url) }
                        }
                    }
                }
                return true
            }
            
            // MARK: - Blocked Apps List
            if firewall.isLoading {
                ProgressView("Syncing with macOS Firewall…")
                    .padding()
            } else if firewall.blockedApps.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                    Text("No apps blocked")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Blocked Apps")
                            .font(.headline)
                        Spacer()
                        Text("\(firewall.blockedApps.count) blocked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 30)
                    
                    List {
                        ForEach(firewall.blockedApps, id: \.self) { url in
                            HStack(spacing: 12) {
                                if let icon = NSWorkspace.shared.icon(forFile: url.path).cgImage(forProposedRect: nil, context: nil, hints: nil) {
                                    Image(decorative: icon, scale: 1)
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(url.deletingPathExtension().lastPathComponent)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(url.path)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "xmark.shield.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                                
                                Button("Unblock") {
                                    firewall.unblockApp(at: url)
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)
                                .controlSize(.small)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.inset)
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
