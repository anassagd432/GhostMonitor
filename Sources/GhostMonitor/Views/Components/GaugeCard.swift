import SwiftUI

public struct GaugeCard<Content: View>: View {
    public let title: String
    public let systemImage: String
    public let valueString: String
    public let statusLevel: StatusLevel
    public var subtitle: String? = nil
    public var tooltipText: String? = nil
    public let content: Content
    
    public init(
        title: String,
        systemImage: String,
        valueString: String,
        statusLevel: StatusLevel = .normal,
        subtitle: String? = nil,
        tooltipText: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.valueString = valueString
        self.statusLevel = statusLevel
        self.subtitle = subtitle
        self.tooltipText = tooltipText
        self.content = content()
    }
    
    private var cardBorderColor: Color {
        switch statusLevel {
        case .normal: return Color.white.opacity(0.08)
        case .attention: return Color.blue.opacity(0.3)
        case .warning: return Color.orange.opacity(0.5)
        case .critical: return Color.red.opacity(0.7)
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cyan)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let tooltip = tooltipText {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .help(tooltip)
                }
                
                Spacer()
                
                if statusLevel != .normal {
                    StatusBadge(level: statusLevel)
                }
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(valueString)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(cardBorderColor, lineWidth: statusLevel == .normal ? 1 : 1.5)
        )
    }
}
