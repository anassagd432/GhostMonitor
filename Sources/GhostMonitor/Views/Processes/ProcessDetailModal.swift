import SwiftUI

public struct ProcessDetailModal: View {
    let process: ProcessItem
    @ObservedObject var viewModel: ProcessListViewModel
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                if let path = process.iconPath, !path.isEmpty {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                        .resizable()
                        .frame(width: 48, height: 48)
                } else {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(process.name)
                        .font(.system(size: 18, weight: .bold))
                    Text("PID: \(process.pid) • User: \(process.user)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                detailRow(label: "Executable Path", value: process.iconPath ?? "Unknown")
                detailRow(label: "CPU Usage", value: String(format: "%.1f%%", process.cpuUsagePercentage))
                detailRow(label: "Memory Usage", value: ByteFormatter.formatBytes(process.memoryBytes))
                detailRow(label: "Total Runtime", value: TimeFormatter.formatUptime(process.runtimeSeconds))
                detailRow(label: "State", value: process.state)
                detailRow(label: "Classification", value: process.isSystemProcess ? "System Process" : "User Application")
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Button("Reveal in Finder") {
                    viewModel.revealInFinder(process: process)
                }
                
                Button("Copy PID") {
                    viewModel.copyPID(process: process)
                }
                
                Spacer()
                
                Button("Quit Process") {
                    dismiss()
                    viewModel.promptQuit(process: process, force: false)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Force Quit") {
                    dismiss()
                    viewModel.promptQuit(process: process, force: true)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(20)
        .frame(width: 480)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
}
