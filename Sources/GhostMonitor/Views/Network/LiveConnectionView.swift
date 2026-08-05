import SwiftUI

public struct LiveConnectionView: View {
    @StateObject private var service = LiveConnectionService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Network Connections")
                        .font(.title2.bold())
                    Text("\(service.displayedConnections.count) active connections")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Toggle("Suspicious Only", isOn: $service.filterSuspiciousOnly)
                    .toggleStyle(.switch)
                    .tint(.orange)
                
                Button(action: {
                    service.isMonitoring ? service.stopMonitoring() : service.startMonitoring()
                }) {
                    Label(service.isMonitoring ? "Stop" : "Monitor", systemImage: service.isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(service.isMonitoring ? .red : .green)
            }
            .padding(20)
            
            Divider()
            
            // MARK: - Suspicious Banner
            let suspiciousCount = service.connections.filter { $0.isSuspicious }.count
            if suspiciousCount > 0 {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .foregroundColor(.red)
                    Text("\(suspiciousCount) connection(s) on known suspicious port(s) detected!")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(12)
                .background(Color.red.opacity(0.08))
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            
            // MARK: - Connection List
            if !service.isMonitoring {
                VStack(spacing: 12) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Press Monitor to start watching live connections.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else if service.displayedConnections.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Fetching connections…")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                List(service.displayedConnections) { conn in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(conn.isSuspicious ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(conn.processName)
                                    .font(.system(size: 13, weight: .semibold))
                                Text("PID \(conn.pid)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                if conn.isSuspicious {
                                    Text("SUSPICIOUS PORT")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.15))
                                        .foregroundColor(.red)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            HStack(spacing: 4) {
                                Text(conn.localAddress)
                                    .foregroundColor(.secondary)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                Text(conn.remoteAddress)
                                    .foregroundColor(conn.isSuspicious ? .red : .primary)
                                    .fontWeight(conn.isSuspicious ? .bold : .regular)
                            }
                            .font(.system(size: 10, design: .monospaced))
                            
                            HStack(spacing: 8) {
                                Text(conn.proto).font(.caption2)
                                Text(conn.state).font(.caption2).foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { service.killProcess(conn) }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Kill process \(conn.processName)")
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(conn.isSuspicious ? Color.red.opacity(0.04) : Color.clear)
                }
                .listStyle(.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear { service.stopMonitoring() }
    }
}
