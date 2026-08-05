import SwiftUI

public struct NetworkSectionView: View {
    let snapshot: NetworkSnapshot
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active Network Interfaces", systemImage: "network")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                HStack(spacing: 12) {
                    Text("DL: \(ByteFormatter.formatSpeed(snapshot.totalDownloadSpeed))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("UL: \(ByteFormatter.formatSpeed(snapshot.totalUploadSpeed))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(snapshot.activeInterfaces) { iface in
                    HStack {
                        Image(systemName: iface.isWifi ? "wifi" : (iface.isEthernet ? "cable.connector" : "network"))
                            .font(.system(size: 14))
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(iface.interfaceName)
                                    .font(.system(size: 12, weight: .bold))
                                if iface.interfaceName == snapshot.primaryInterfaceName {
                                    Text("Primary")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                            }
                            if !iface.ipAddress.isEmpty {
                                Text("IP: \(iface.ipAddress)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("↓ \(ByteFormatter.formatSpeed(iface.downloadSpeedBytesPerSec))  ↑ \(ByteFormatter.formatSpeed(iface.uploadSpeedBytesPerSec))")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Total: \(ByteFormatter.formatBytes(Int64(iface.totalBytesReceived))) in / \(ByteFormatter.formatBytes(Int64(iface.totalBytesSent))) out")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
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
