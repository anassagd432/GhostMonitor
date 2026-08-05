import SwiftUI

public struct DuplicateFinderView: View {
    @StateObject private var finder = DuplicateFinderService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GhostTheme.purple.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .shadow(color: GhostTheme.purple, radius: 12)
                        
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 38))
                            .foregroundColor(GhostTheme.purple)
                    }
                    
                    Text("Duplicate File & Media Finder")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Scan SSD directories for byte-for-byte identical photos, videos, and downloads using SHA-256 hashes.")
                        .font(.system(size: 13))
                        .foregroundColor(GhostTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                // Reclaimable Space Header Card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RECLAIMABLE DISK SPACE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        
                        let reclaimedGB = Double(finder.totalReclaimableBytes) / 1_073_741_824.0
                        Text(String(format: "%.2f GB", reclaimedGB))
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.mint)
                    }
                    Spacer()
                    
                    Button(action: { finder.startScan() }) {
                        HStack(spacing: 6) {
                            if finder.isScanning {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text(finder.isScanning ? "Scanning..." : "Scan SSD Now")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(finder.isScanning ? Color.white.opacity(0.1) : GhostTheme.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(color: GhostTheme.purple.opacity(0.5), radius: 8)
                    }
                    .buttonStyle(.plain)
                    .disabled(finder.isScanning)
                }
                .padding(20)
                .cyberCardStyle(glowing: finder.totalReclaimableBytes > 0)
                
                if !finder.progressText.isEmpty {
                    Text(finder.progressText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(GhostTheme.textSecondary)
                }
                
                // Duplicate Groups List
                if !finder.duplicateGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("DUPLICATE FILE GROUPS (\(finder.duplicateGroups.count))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        
                        VStack(spacing: 14) {
                            ForEach(finder.duplicateGroups) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        let groupReclaim = Double(group.reclaimableBytes) / 1_048_576.0
                                        Text("Group • \(group.files.count) copies (\(String(format: "%.1f MB", groupReclaim)) reclaimable)")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    
                                    ForEach(group.files, id: \.self) { url in
                                        HStack(spacing: 10) {
                                            Image(systemName: "doc.fill")
                                                .foregroundColor(GhostTheme.purple)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(url.lastPathComponent)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                Text(url.path)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(GhostTheme.textSecondary)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: { finder.deleteFile(url: url, from: group.id) }) {
                                                Image(systemName: "trash.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.red)
                                                    .padding(6)
                                                    .background(Color.red.opacity(0.12))
                                                    .cornerRadius(6)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(8)
                                        .background(Color.white.opacity(0.03))
                                        .cornerRadius(6)
                                    }
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
            }
            .padding(24)
        }
        .background(GhostTheme.bgDark)
    }
}
