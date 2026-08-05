import SwiftUI

public struct CyberHeaderView: View {
    @ObservedObject var coordinator: MonitoringCoordinator
    
    public init(coordinator: MonitoringCoordinator = .shared) {
        self.coordinator = coordinator
    }
    
    public var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .foregroundColor(GhostTheme.cyan)
                    .font(.system(size: 16, weight: .bold))
                Text("GHOST MONITOR v2.4")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if let storage = coordinator.storage {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .foregroundColor(GhostTheme.textSecondary)
                            .font(.system(size: 12))
                        Text("\(Double(storage.totalUsedBytes) / 1073741824.0, specifier: "%.1f")GB Used")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(GhostTheme.mint)
                        .frame(width: 6, height: 6)
                        .shadow(color: GhostTheme.mint, radius: 4)
                    Text("ONLINE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.mint)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(GhostTheme.mint.opacity(0.12))
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(GhostTheme.cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(GhostTheme.cardBorder, lineWidth: 1)
        )
    }
}
