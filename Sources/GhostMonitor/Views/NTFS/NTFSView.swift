import SwiftUI

public struct NTFSView: View {
    @StateObject private var ntfs = NTFSService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NTFS Unlocker")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Unlock Windows NTFS drives with full Read & Write permissions.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if ntfs.isScanning {
                    ProgressView().scaleEffect(0.6).padding(.trailing, 8)
                } else {
                    Button(action: {
                        ntfs.scanDrives()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
            }
            .padding(20)
            
            Divider()
            
            VStack(spacing: 0) {
                if !ntfs.isDriverInstalled {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("3rd Party NTFS-3G drivers not installed. Using native macOS read/write remount engine.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            Task { await ntfs.installDrivers() }
                        }) {
                            if ntfs.isInstallingDriver {
                                ProgressView().scaleEffect(0.6)
                            } else {
                                Text("Install macFUSE Driver")
                                    .font(.caption.bold())
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(ntfs.isInstallingDriver)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                }
                
                // Drive List
                if ntfs.drives.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "externaldrive.fill.badge.xmark")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No NTFS Drives Detected")
                            .font(.headline)
                        Text("Plug in a Windows formatted SSD, HDD, or USB drive to unlock.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Re-Scan Drives") {
                            ntfs.scanDrives()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 4)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(ntfs.drives) { drive in
                            HStack {
                                Image(systemName: "externaldrive.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(drive.isMountedRW ? .green : .cyan)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(drive.name)
                                        .font(.headline)
                                    Text("\(drive.deviceIdentifier) • \(formatBytes(drive.sizeBytes))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 8)
                                
                                Spacer()
                                
                                if drive.isMountedRW {
                                    Text("UNLOCKED (Read/Write)")
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .clipShape(Capsule())
                                } else {
                                    Button(action: {
                                        Task { await ntfs.mountReadWrite(drive: drive) }
                                    }) {
                                        Text("Mount as Read/Write")
                                            .fontWeight(.bold)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.cyan)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            ntfs.startScanning()
        }
        .onDisappear {
            ntfs.stopScanning()
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
