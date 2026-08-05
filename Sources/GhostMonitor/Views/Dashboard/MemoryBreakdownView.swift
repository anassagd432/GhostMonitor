import SwiftUI

public struct MemoryBreakdownView: View {
    let memory: MemorySnapshot
    
    private var segments: [SegmentItem] {
        [
            SegmentItem(name: "Wired", value: Double(memory.wiredBytes), color: .red),
            SegmentItem(name: "Active", value: Double(memory.activeBytes), color: .blue),
            SegmentItem(name: "Compressed", value: Double(memory.compressedBytes), color: .orange),
            SegmentItem(name: "Inactive", value: Double(memory.inactiveBytes), color: .purple),
            SegmentItem(name: "Free/Cached", value: Double(memory.freeBytes + memory.cachedBytes), color: .green.opacity(0.6))
        ]
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Memory Allocation Breakdown", systemImage: "memorychip.fill")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("Total: \(ByteFormatter.formatBytes(memory.totalBytes))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            SegmentedProgressBar(segments: segments, height: 14)
            
            // Grid of exact metric values
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 10) {
                metricCell(title: "Used Memory", value: ByteFormatter.formatBytes(memory.usedBytes), color: .primary)
                metricCell(title: "Wired Memory", value: ByteFormatter.formatBytes(memory.wiredBytes), color: .red)
                metricCell(title: "Active Memory", value: ByteFormatter.formatBytes(memory.activeBytes), color: .blue)
                metricCell(title: "Inactive Memory", value: ByteFormatter.formatBytes(memory.inactiveBytes), color: .purple)
                metricCell(title: "Compressed", value: ByteFormatter.formatBytes(memory.compressedBytes), color: .orange)
                metricCell(title: "Cached Files", value: ByteFormatter.formatBytes(memory.cachedBytes), color: .green)
                metricCell(title: "Free Memory", value: ByteFormatter.formatBytes(memory.freeBytes), color: .secondary)
                metricCell(title: "Swap Used", value: ByteFormatter.formatBytes(memory.swapUsedBytes), color: memory.swapUsedBytes > 0 ? .orange : .secondary)
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
    
    private func metricCell(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(6)
    }
}
