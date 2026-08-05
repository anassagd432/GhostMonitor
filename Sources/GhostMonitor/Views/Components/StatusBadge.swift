import SwiftUI

public struct StatusBadge: View {
    public let level: StatusLevel
    public var label: String? = nil
    
    public init(level: StatusLevel, label: String? = nil) {
        self.level = level
        self.label = label
    }
    
    private var color: Color {
        switch level {
        case .normal: return Color.green
        case .attention: return Color.blue
        case .warning: return Color.orange
        case .critical: return Color.red
        }
    }
    
    private var iconName: String {
        switch level {
        case .normal: return "checkmark.circle.fill"
        case .attention: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .semibold))
            Text(label ?? level.rawValue)
                .font(.system(size: 11, weight: .bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.18))
        .foregroundColor(color)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
