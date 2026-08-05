import SwiftUI

public struct CyberGaugeView: View {
    public let title: String
    public let percentage: Double // 0 to 100
    public let subtitle: String
    
    public init(title: String, percentage: Double, subtitle: String = "M-Series Apple Silicon | Active") {
        self.title = title
        self.percentage = percentage
        self.subtitle = subtitle
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text("\(Int(percentage))%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(GhostTheme.cyan)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(GhostTheme.textSecondary)
            }
            
            ZStack {
                // Outer Track
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                // Outer Dashed Accent Ring
                Circle()
                    .stroke(GhostTheme.purple.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 140, height: 140)
                
                // Glowing Gauge Ring
                Circle()
                    .trim(from: 0, to: CGFloat(min(percentage / 100.0, 1.0)))
                    .stroke(
                        GhostTheme.gaugeGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: GhostTheme.cyan.opacity(0.6), radius: 8)
                
                // Center Label
                VStack(spacing: 2) {
                    Text("\(Int(percentage))%")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 8)
            
            Text(subtitle)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(GhostTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
        }
        .padding(16)
        .cyberCardStyle(glowing: true)
    }
}
