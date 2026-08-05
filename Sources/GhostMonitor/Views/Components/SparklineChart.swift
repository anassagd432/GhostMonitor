import SwiftUI
import Charts

public struct SparklineChart: View {
    public let points: [TimeSeriesPoint]
    public let color: Color
    public var height: CGFloat = 40
    public var showArea: Bool = true
    
    public init(points: [TimeSeriesPoint], color: Color = .blue, height: CGFloat = 40, showArea: Bool = true) {
        self.points = points
        self.color = color
        self.height = height
        self.showArea = showArea
    }
    
    public var body: some View {
        Group {
            if points.isEmpty {
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: height)
                    .overlay(
                        Text("Gathering data...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    )
            } else {
                Chart(points) { point in
                    if showArea {
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color.opacity(0.35), color.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)
                    }
                    
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: 0...max(100.0, (points.map(\.value).max() ?? 100.0) * 1.1))
                .frame(height: height)
            }
        }
    }
}
