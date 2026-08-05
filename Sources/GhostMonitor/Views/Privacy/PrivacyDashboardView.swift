import SwiftUI

public struct PrivacyDashboardView: View {
    @StateObject private var dashboard = PrivacyDashboardService.shared
    @State private var selectedFilter: PermissionType? = nil
    
    public init() {}
    
    var filteredPermissions: [AppPermission] {
        if let f = selectedFilter {
            return dashboard.permissions.filter { $0.permission == f }
        }
        return dashboard.permissions
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy Permissions Dashboard")
                        .font(.title2.bold())
                    Text("See which apps have access to your hardware.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: { dashboard.scan() }) {
                    Label(dashboard.isScanning ? "Scanning…" : "Scan Now", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(dashboard.isScanning)
            }
            .padding(20)
            
            Divider()
            
            // MARK: - Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    filterBadge(title: "All", icon: "square.grid.2x2.fill", type: nil)
                    ForEach(PermissionType.allCases, id: \.self) { type in
                        filterBadge(title: type.rawValue, icon: type.icon, type: type)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color.secondary.opacity(0.05))
            
            Divider()
            
            // MARK: - List
            if dashboard.isScanning {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Reading TCC Database…")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if dashboard.permissions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.slash.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Click Scan Now to review granted permissions.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                List {
                    ForEach(filteredPermissions) { perm in
                        HStack(spacing: 16) {
                            
                            if let icon = NSWorkspace.shared.icon(forFile: "/Applications/\(perm.appName).app").cgImage(forProposedRect: nil, context: nil, hints: nil) {
                                Image(decorative: icon, scale: 1)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: "app.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(perm.appName)
                                    .font(.headline)
                                Text(perm.bundleID)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Label(perm.permission.rawValue, systemImage: perm.permission.icon)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.indigo.opacity(0.1))
                                    .foregroundColor(.indigo)
                                    .clipShape(Capsule())
                                
                                if perm.isGranted {
                                    Text("GRANTED")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .clipShape(Capsule())
                                } else {
                                    Text("DENIED")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.red.opacity(0.15))
                                        .foregroundColor(.red)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            Button(action: { dashboard.revoke(permission: perm) }) {
                                Image(systemName: "xmark.shield.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.bordered)
                            .help("Revoke permission (Reset TCC)")
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if dashboard.permissions.isEmpty { dashboard.scan() }
        }
    }
    
    private func filterBadge(title: String, icon: String, type: PermissionType?) -> some View {
        let isSelected = selectedFilter == type
        return Button(action: { selectedFilter = type }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title).fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.indigo : Color.secondary.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
