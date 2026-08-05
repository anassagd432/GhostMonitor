import SwiftUI

public struct SegmentItem: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let value: Double
    public let color: Color
    
    public init(name: String, value: Double, color: Color) {
        self.name = name
        self.value = value
        self.color = color
    }
}

public struct SegmentedProgressBar: View {
    public let segments: [SegmentItem]
    public var height: CGFloat = 12
    
    public init(segments: [SegmentItem], height: CGFloat = 12) {
        self.segments = segments
        self.height = height
    }
    
    private var totalValue: Double {
        max(1.0, segments.reduce(0.0) { $0 + $1.value })
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                HStack(spacing: 1) {
                    ForEach(segments) { segment in
                        let width = (segment.value / totalValue) * geo.size.width
                        if width > 0 {
                            Rectangle()
                                .fill(segment.color)
                                .frame(width: width)
                        }
                    }
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Legend
            HStack(spacing: 12) {
                ForEach(segments) { segment in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 8, height: 8)
                        Text(segment.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
