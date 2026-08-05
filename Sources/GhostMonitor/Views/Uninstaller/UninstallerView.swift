import SwiftUI

public struct UninstallerView: View {
    @StateObject private var uninstaller = UninstallerService()
    @State private var selectedApp: AppInstall?
    @State private var showingConfirmation = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Uninstaller")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Safely remove applications and their hidden leftover files.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: {
                    Task {
                        await uninstaller.scan()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(.degrees(uninstaller.isScanning ? 360 : 0))
                            .animation(uninstaller.isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: uninstaller.isScanning)
                        Text(uninstaller.isScanning ? "Scanning..." : "Scan Apps")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(uninstaller.isScanning || uninstaller.isUninstalling)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // App List
            List(selection: $selectedApp) {
                if uninstaller.apps.isEmpty {
                    if uninstaller.isScanning {
                        HStack {
                            Spacer()
                            ProgressView("Scanning Applications...")
                                .padding()
                            Spacer()
                        }
                    } else {
                        HStack {
                            Spacer()
                            Text("Click 'Scan Apps' to find installed applications.")
                                .foregroundColor(.secondary)
                                .padding()
                            Spacer()
                        }
                    }
                } else {
                    ForEach(uninstaller.apps) { app in
                        HStack(spacing: 12) {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: "app.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .font(.system(size: 14, weight: .medium))
                                Text(app.bundleIdentifier)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(ByteFormatter.formatBytes(app.totalSizeBytes))
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                Text("Leftovers: \(ByteFormatter.formatBytes(app.relatedFilesBytes))")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .tag(app)
                    }
                }
            }
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Bottom Action
            HStack {
                if let app = selectedApp {
                    Text("Selected: \(app.name)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("Select an application to uninstall")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingConfirmation = true
                }) {
                    Text(uninstaller.isUninstalling ? "Uninstalling..." : "Uninstall App")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(selectedApp == nil || uninstaller.isScanning || uninstaller.isUninstalling)
                .alert("Uninstall \(selectedApp?.name ?? "")?", isPresented: $showingConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Uninstall", role: .destructive) {
                        if let app = selectedApp {
                            Task {
                                await uninstaller.uninstall(app: app)
                                selectedApp = nil
                            }
                        }
                    }
                } message: {
                    Text("This will permanently delete the application and \(ByteFormatter.formatBytes(selectedApp?.relatedFilesBytes ?? 0)) of related hidden files. This action cannot be undone.")
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
