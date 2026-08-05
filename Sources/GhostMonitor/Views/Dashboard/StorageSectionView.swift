import SwiftUI

public struct StorageSectionView: View {
    let snapshot: StorageSnapshot
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Mounted Disk Volumes", systemImage: "internaldrive.fill")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("Total Capacity: \(ByteFormatter.formatBytes(snapshot.totalCapacityBytes))")
                    .font(.system(size: 12, weight: .bold))
            }
            
            VStack(spacing: 10) {
                ForEach(snapshot.volumes) { vol in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: vol.isInternal ? "internaldrive" : "externaldrive")
                                .foregroundColor(vol.isInternal ? .cyan : .orange)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(vol.name)
                                    .font(.system(size: 12, weight: .bold))
                                Text("\(vol.mountPoint) • \(vol.filesystem)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(ByteFormatter.formatBytes(vol.usedBytes)) used / \(ByteFormatter.formatBytes(vol.totalBytes)) (\(String(format: "%.1f%%", vol.usagePercentage)))")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.15))
                                Rectangle()
                                    .fill(vol.usagePercentage > 85 ? Color.orange : Color.blue)
                                    .frame(width: (vol.usagePercentage / 100.0) * geo.size.width)
                            }
                        }
                        .frame(height: 8)
                        .clipShape(Capsule())
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.06))
                    .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
}
