import SwiftUI

public struct LoginItemsView: View {
    @StateObject private var service = LoginItemsService.shared
    @State private var selectedItem: LaunchItem?
    @State private var confirmDelete: LaunchItem?
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Login Items Monitor")
                        .font(.title2.bold())
                    if let date = service.lastScanDate {
                        Text("Last scan: \(date.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                
                HStack(spacing: 8) {
                    if !service.items.isEmpty {
                        Label("\(service.items.filter { $0.isSuspicious }.count) suspicious", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    
                    Button(action: { service.scan() }) {
                        Label(service.isScanning ? "Scanning…" : "Scan Now", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .disabled(service.isScanning)
                }
            }
            .padding(20)
            
            Divider()
            
            if service.isScanning {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Scanning LaunchAgents and LaunchDaemons…")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if service.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Press Scan Now to analyse your startup items.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                List(service.items, selection: $selectedItem) { item in
                    LaunchItemRow(item: item, onDisable: {
                        item.isEnabled ? service.disable(item) : service.enable(item)
                    }, onReveal: {
                        service.revealInFinder(item)
                    }, onDelete: {
                        confirmDelete = item
                    })
                    .tag(item)
                }
                .listStyle(.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Delete Launch Item?", isPresented: Binding(
            get: { confirmDelete != nil },
            set: { if !$0 { confirmDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let item = confirmDelete { service.deleteItem(item) }
                confirmDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmDelete = nil }
        } message: {
            Text("This will unload and permanently delete \(confirmDelete?.name ?? "this item"). This cannot be undone.")
        }
        .onAppear { if service.items.isEmpty { service.scan() } }
    }
}

private struct LaunchItemRow: View {
    let item: LaunchItem
    let onDisable: () -> Void
    let onReveal: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Status dot
            Circle()
                .fill(item.isEnabled ? Color.green : Color.secondary.opacity(0.4))
                .frame(width: 8, height: 8)
            
            // Suspicious badge
            if item.isSuspicious {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                    
                    Text(item.isUserLevel ? "User" : "System")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.isUserLevel ? Color.blue.opacity(0.15) : Color.red.opacity(0.15))
                        .foregroundColor(item.isUserLevel ? .blue : .red)
                        .clipShape(Capsule())
                }
                
                Text(item.executablePath.isEmpty ? item.plistPath : item.executablePath)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if item.isSuspicious {
                    Text("⚠️ \(item.suspiciousReason)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Button(item.isEnabled ? "Disable" : "Enable") { onDisable() }
                    .buttonStyle(.bordered)
                    .tint(item.isEnabled ? .orange : .green)
                    .controlSize(.small)
                
                Button(action: onReveal) {
                    Image(systemName: "folder")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Reveal in Finder")
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Delete this launch item")
            }
        }
        .padding(.vertical, 4)
        .background(item.isSuspicious ? Color.orange.opacity(0.05) : Color.clear)
    }
}
