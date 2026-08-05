import SwiftUI

public struct NetworkSpectrumCard: View {
    public let upKbps: Double
    public let downKbps: Double
    
    public init(upKbps: Double = 12800, downKbps: Double = 45300) {
        self.upKbps = upKbps
        self.downKbps = downKbps
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Network Traffic")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(GhostTheme.textSecondary)
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .foregroundColor(GhostTheme.cyan)
                        .font(.system(size: 12, weight: .bold))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Up")
                            .font(.system(size: 9))
                            .foregroundColor(GhostTheme.textSecondary)
                        Text(formatSpeed(upKbps))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .foregroundColor(GhostTheme.magenta)
                        .font(.system(size: 12, weight: .bold))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Down")
                            .font(.system(size: 9))
                            .foregroundColor(GhostTheme.textSecondary)
                        Text(formatSpeed(downKbps))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Equalizer Spectrum Bar Visualization
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<20, id: \.self) { i in
                    let height = CGFloat([10, 18, 25, 40, 20, 15, 30, 35, 12, 28, 45, 22, 16, 32, 24, 18, 38, 14, 26, 12][i])
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < 10 ? GhostTheme.cyan : GhostTheme.magenta)
                        .frame(height: height)
                }
            }
            .frame(height: 45)
            .padding(.top, 4)
        }
        .padding(14)
        .cyberCardStyle()
    }
    
    private func formatSpeed(_ kbps: Double) -> String {
        if kbps >= 1000 {
            return String(format: "%.1f Mbps", kbps / 1000.0)
        } else {
            return String(format: "%.0f Kbps", kbps)
        }
    }
}

public struct PrivacyStatusCard: View {
    @State private var isEnabled: Bool = true
    @State private var blockTracking: Bool = true
    @State private var secureDNS: Bool = true
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Privacy Status")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(isEnabled ? GhostTheme.mint : Color.red)
                        .frame(width: 6, height: 6)
                    Text(isEnabled ? "Enabled" : "Disabled")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isEnabled ? GhostTheme.mint : Color.red)
                }
            }
            
            HStack(spacing: 12) {
                // Shield Glowing Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GhostTheme.purple.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(GhostTheme.purple.opacity(0.4), lineWidth: 1)
                        )
                    Image(systemName: "shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(GhostTheme.purple)
                        .shadow(color: GhostTheme.purple, radius: 8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("ON", isOn: $isEnabled)
                        .toggleStyle(CyberToggleStyle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: blockTracking ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 9))
                                .foregroundColor(blockTracking ? GhostTheme.cyan : GhostTheme.textSecondary)
                            Text("Block Tracking")
                                .font(.system(size: 9))
                                .foregroundColor(GhostTheme.textSecondary)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: secureDNS ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 9))
                                .foregroundColor(secureDNS ? GhostTheme.cyan : GhostTheme.textSecondary)
                            Text("Secure DNS")
                                .font(.system(size: 9))
                                .foregroundColor(GhostTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(14)
        .cyberCardStyle(glowing: isEnabled)
    }
}

public struct ThreadActivityCard: View {
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Thread Activity")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(GhostTheme.textSecondary)
            }
            
            // Equalizer Spectrum Bar Visualization matching hero photo
            HStack(alignment: .bottom, spacing: 2.5) {
                ForEach(0..<24, id: \.self) { i in
                    let h = CGFloat([12, 22, 35, 18, 28, 42, 15, 30, 25, 38, 45, 20, 16, 32, 24, 18, 40, 14, 28, 33, 22, 15, 29, 19][i])
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(i % 2 == 0 ? GhostTheme.mint : GhostTheme.cyan)
                        .frame(height: h)
                }
            }
            .frame(height: 45)
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(GhostTheme.mint).frame(width: 6, height: 6)
                    Text("Online")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(GhostTheme.mint)
                }
                HStack(spacing: 4) {
                    Circle().fill(GhostTheme.purple).frame(width: 6, height: 6)
                    Text("Secure")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(GhostTheme.purple)
                }
            }
        }
        .padding(14)
        .cyberCardStyle()
    }
}
