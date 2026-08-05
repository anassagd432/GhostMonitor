import SwiftUI

public struct CyberChartView: View {
    public let title: String
    public let currentUsageGB: Double
    public let totalGB: Double
    public let dataPoints: [Double] // Values 0 to 100
    
    public init(
        title: String = "Memory Usage",
        currentUsageGB: Double = 64.2,
        totalGB: Double = 92.1,
        dataPoints: [Double] = [30, 45, 35, 60, 75, 55, 80, 65, 78]
    ) {
        self.title = title
        self.currentUsageGB = currentUsageGB
        self.totalGB = totalGB
        self.dataPoints = dataPoints
    }
    
    private var percentage: Int {
        guard totalGB > 0 else { return 0 }
        return Int((currentUsageGB / totalGB) * 100)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(percentage)%")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                    }
                }
                Spacer()
                Text("\(currentUsageGB, specifier: "%.1f")GB / \(totalGB, specifier: "%.1f")GB")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(GhostTheme.textSecondary)
            }
            
            // Chart Canvas
            ZStack(alignment: .bottom) {
                // Background Gridlines
                VStack {
                    Divider().background(Color.white.opacity(0.05))
                    Spacer()
                    Divider().background(Color.white.opacity(0.05))
                    Spacer()
                    Divider().background(Color.white.opacity(0.05))
                }
                .frame(height: 110)
                
                // Gradient Fill Under Spline
                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height
                    let points = normalizePoints(dataPoints, width: width, height: height)
                    
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))
                        if let first = points.first {
                            path.addLine(to: first)
                        }
                        for i in 1..<points.count {
                            path.addLine(to: points[i])
                        }
                        if let last = points.last {
                            path.addLine(to: CGPoint(x: last.x, y: height))
                        }
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [GhostTheme.cyan.opacity(0.3), GhostTheme.purple.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Cyan/Purple Gradient Stroke
                    Path { path in
                        if let first = points.first {
                            path.move(to: first)
                        }
                        for i in 1..<points.count {
                            path.addLine(to: points[i])
                        }
                    }
                    .stroke(GhostTheme.cyberGradient, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .shadow(color: GhostTheme.cyan.opacity(0.6), radius: 4)
                    
                    // Glowing Data Node Points
                    ForEach(0..<points.count, id: \.self) { idx in
                        let pt = points[idx]
                        if idx == points.count - 1 || idx == 4 {
                            Circle()
                                .fill(GhostTheme.cyan)
                                .frame(width: 8, height: 8)
                                .shadow(color: GhostTheme.cyan, radius: 6)
                                .position(pt)
                        }
                    }
                }
                .frame(height: 110)
            }
            
            // X-Axis Time Labels matching mockup
            HStack {
                Text("06:00").font(.system(size: 9, design: .monospaced))
                Spacer()
                Text("08:00").font(.system(size: 9, design: .monospaced))
                Spacer()
                Text("10:00").font(.system(size: 9, design: .monospaced))
                Spacer()
                Text("12:00").font(.system(size: 9, design: .monospaced))
                Spacer()
                Text("14:00").font(.system(size: 9, design: .monospaced))
                Spacer()
                Text("15:00").font(.system(size: 9, design: .monospaced))
            }
            .foregroundColor(GhostTheme.textSecondary)
        }
        .padding(16)
        .cyberCardStyle()
    }
    
    private func normalizePoints(_ values: [Double], width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let step = width / CGFloat(values.count - 1)
        return values.enumerated().map { (idx, val) in
            let x = CGFloat(idx) * step
            let clampedVal = max(0, min(100, val))
            let y = height - (CGFloat(clampedVal / 100.0) * height)
            return CGPoint(x: x, y: y)
        }
    }
}
