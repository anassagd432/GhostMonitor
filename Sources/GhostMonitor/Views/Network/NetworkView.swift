import SwiftUI

public struct NetworkView: View {
    @StateObject private var network = NetworkService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Network & Firewall")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Monitor and control app data usage in real-time.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if network.isScanning {
                    ProgressView()
                        .scaleEffect(0.6)
                        .padding(.trailing, 8)
                }
            }
            .padding(20)
            
            Divider()
            
            // List Header
            HStack {
                Text("APP NAME")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("PID")
                    .frame(width: 60, alignment: .trailing)
                Text("DATA IN")
                    .frame(width: 80, alignment: .trailing)
                Text("DATA OUT")
                    .frame(width: 80, alignment: .trailing)
                Text("ACTION")
                    .frame(width: 90, alignment: .trailing)
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.05))
            
            // List Body
            List {
                ForEach(network.activeConnections) { app in
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "network")
                                .foregroundColor(.cyan)
                            Text(app.name)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("\(app.pid)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        
                        Text(formatBytes(app.bytesIn))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.green)
                            .frame(width: 80, alignment: .trailing)
                        
                        Text(formatBytes(app.bytesOut))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.orange)
                            .frame(width: 80, alignment: .trailing)
                        
                        Button(action: {
                            Task {
                                await network.blockApp(pid: app.pid)
                            }
                        }) {
                            Text("Block (Kill)")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                        .frame(width: 90, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            network.startMonitoring()
        }
        .onDisappear {
            network.stopMonitoring()
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
