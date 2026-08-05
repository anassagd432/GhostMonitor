import SwiftUI

public struct PingLatencyView: View {
    @StateObject private var ping = PingLatencyService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GhostTheme.cyan.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .shadow(color: GhostTheme.cyan, radius: 12)
                        
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 38))
                            .foregroundColor(GhostTheme.cyan)
                    }
                    
                    Text("Real-Time Network Ping & Speed Visualizer")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Continuous round-trip latency measurements to major DNS edge nodes (Cloudflare, Google, OpenDNS).")
                        .font(.system(size: 13))
                        .foregroundColor(GhostTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                // Average Latency Card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AVERAGE NETWORK LATENCY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", ping.averagePingMs))
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(ping.averagePingMs < 40 ? GhostTheme.mint : GhostTheme.magenta)
                            Text("ms")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(GhostTheme.textSecondary)
                        }
                    }
                    Spacer()
                    
                    Button(action: { ping.runPingCheck() }) {
                        HStack(spacing: 6) {
                            if ping.isPinging {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Refresh Latency")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(GhostTheme.cyan)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .cyberCardStyle(glowing: true)
                
                // Edge Servers Ping List
                VStack(alignment: .leading, spacing: 14) {
                    Text("EDGE DNS SERVER LATENCY LOGS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    VStack(spacing: 10) {
                        ForEach(ping.pingResults) { res in
                            HStack(spacing: 14) {
                                Image(systemName: "network")
                                    .font(.system(size: 18))
                                    .foregroundColor(GhostTheme.mint)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(res.serverName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(res.host)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(GhostTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 6) {
                                    Text(String(format: "%.1f ms", res.latencyMs))
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(GhostTheme.mint)
                                    
                                    Text(res.status.uppercased())
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(GhostTheme.mint.opacity(0.15))
                                        .foregroundColor(GhostTheme.mint)
                                        .cornerRadius(4)
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
            .padding(24)
        }
        .background(GhostTheme.bgDark)
    }
}
