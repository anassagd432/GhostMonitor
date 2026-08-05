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
            
            if !ntfs.isDriverInstalled {
                // Driver installation prompt
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("NTFS Drivers Not Found")
                        .font(.headline)
                    Text("To unlock NTFS drives on macOS, Ghost Monitor needs to install the open-source macFUSE and ntfs-3g drivers under the hood.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        Task { await ntfs.installDrivers() }
                    }) {
                        if ntfs.isInstallingDriver {
                            ProgressView().padding(.horizontal, 20)
                        } else {
                            Text("Install Drivers Now (Requires Homebrew)")
                                .fontWeight(.bold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(ntfs.isInstallingDriver)
                }
                .frame(maxHeight: .infinity)
            } else {
                // Drive List
                if ntfs.drives.isEmpty {
                    VStack {
                        Image(systemName: "externaldrive.fill.badge.xmark")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No NTFS Drives Detected")
                            .font(.headline)
                            .padding(.top, 8)
                        Text("Plug in a Windows formatted SSD or USB to begin.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(ntfs.drives) { drive in
                            HStack {
                                Image(systemName: "externaldrive.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(drive.isMountedRW ? .green : .red)
                                
                                VStack(alignment: .leading) {
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
                                    .tint(.red)
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
