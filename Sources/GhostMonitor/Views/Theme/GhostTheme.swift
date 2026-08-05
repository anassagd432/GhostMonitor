import SwiftUI

public enum GhostTheme {
    // Core Cyber Palette
    public static let bgDark = Color(red: 0.05, green: 0.06, blue: 0.09) // #0D0F17
    public static let cardBg = Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.85)
    public static let cardBorder = Color(red: 0.00, green: 0.95, blue: 0.99).opacity(0.2)
    public static let cardBorderGlowing = Color(red: 0.00, green: 0.95, blue: 0.99).opacity(0.4)
    
    // Accents matching the hero image
    public static let cyan = Color(red: 0.00, green: 0.95, blue: 0.99)    // #00F2FE
    public static let purple = Color(red: 0.64, green: 0.35, blue: 1.00)  // #A259FF
    public static let magenta = Color(red: 1.00, green: 0.16, blue: 0.52) // #FF2A85
    public static let mint = Color(red: 0.00, green: 1.00, blue: 0.62)    // #00FF9D
    public static let textSecondary = Color(red: 0.55, green: 0.60, blue: 0.70)
    
    // Gradients
    public static let cyberGradient = LinearGradient(
        colors: [cyan, purple],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    public static let gaugeGradient = AngularGradient(
        gradient: Gradient(colors: [cyan, purple, magenta, cyan]),
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )
}

// Custom Card Modifier
public struct CyberCardModifier: ViewModifier {
    var glowing: Bool = false
    
    public func body(content: Content) -> some View {
        content
            .background(GhostTheme.cardBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        glowing ? GhostTheme.cardBorderGlowing : GhostTheme.cardBorder,
                        lineWidth: 1
                    )
            )
            .shadow(color: glowing ? GhostTheme.cyan.opacity(0.25) : Color.black.opacity(0.4), radius: glowing ? 12 : 8, x: 0, y: 4)
    }
}

extension View {
    public func cyberCardStyle(glowing: Bool = false) -> some View {
        self.modifier(CyberCardModifier(glowing: glowing))
    }
}

// Custom Cyber Toggle Switch
public struct CyberToggleStyle: ToggleStyle {
    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .fill(configuration.isOn ? GhostTheme.cyberGradient : LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 44, height: 24)
                .cornerRadius(12)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                )
                .shadow(color: configuration.isOn ? GhostTheme.purple.opacity(0.5) : Color.clear, radius: 6)
                .onTapGesture {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}
