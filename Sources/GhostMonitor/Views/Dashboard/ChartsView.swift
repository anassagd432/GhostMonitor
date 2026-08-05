import SwiftUI
import Charts

public struct ChartsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedMetricTab: MetricTab = .cpu
    
    public enum MetricTab: String, CaseIterable, Identifiable {
        case cpu = "CPU"
        case memory = "Memory"
        case network = "Network"
        case disk = "Disk I/O"
        case battery = "Battery"
        case thermal = "Thermal"
        
        public var id: String { rawValue }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Chart Header Controls
            HStack {
                // Metric Selector Tabs
                Picker("", selection: $selectedMetricTab) {
                    ForEach(MetricTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 400)
                
                Spacer()
                
                // History Window Selector
                HStack(spacing: 6) {
                    Text("History:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $viewModel.selectedHistoryWindow) {
                        ForEach(HistoryWindow.allCases) { window in
                            Text(window.label).tag(window)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }
            
            // Detailed Swift Chart Content
            VStack(alignment: .leading, spacing: 8) {
                switch selectedMetricTab {
                case .cpu:
                    renderChart(
                        points: viewModel.cpuHistoryPoints,
                        title: "Total CPU Usage (%)",
                        color: .blue,
                        unit: "%",
                        maxVal: 100.0
                    )
                case .memory:
                    renderChart(
                        points: viewModel.memoryHistoryPoints,
                        title: "Memory Used (%)",
                        color: .purple,
                        unit: "%",
                        maxVal: 100.0
                    )
                case .network:
                    renderDualChart(
                        points1: viewModel.networkDlHistoryPoints,
                        points2: viewModel.networkUlHistoryPoints,
                        title: "Network Throughput (Download vs Upload)",
                        label1: "Download",
                        label2: "Upload",
                        color1: .cyan,
                        color2: .orange
                    )
                case .disk:
                    renderDualChart(
                        points1: viewModel.diskReadHistoryPoints,
                        points2: viewModel.diskWriteHistoryPoints,
                        title: "Disk Throughput (Read vs Write)",
                        label1: "Read",
                        label2: "Write",
                        color1: .green,
                        color2: .pink
                    )
                case .battery:
                    renderChart(
                        points: viewModel.coordinator.batteryHistory.values(),
                        title: "Battery Charge Level (%)",
                        color: .green,
                        unit: "%",
                        maxVal: 100.0
                    )
                case .thermal:
                    renderChart(
                        points: viewModel.coordinator.thermalHistory.values(),
                        title: "Thermal Pressure Raw Level (0: Nominal, 1: Fair, 2: Serious, 3: Critical)",
                        color: .orange,
                        unit: "lvl",
                        maxVal: 3.0
                    )
                }
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func renderChart(points: [TimeSeriesPoint], title: String, color: Color, unit: String, maxVal: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            
            if points.isEmpty {
                Rectangle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(height: 180)
                    .overlay(
                        Text("Gathering historical data...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    )
            } else {
                Chart(points) { point in
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value(unit, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.35), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                    
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value(unit, point.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartYScale(domain: 0...max(maxVal, (points.map(\.value).max() ?? maxVal) * 1.1))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour().minute().second())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 180)
            }
        }
    }
    
    @ViewBuilder
    private func renderDualChart(
        points1: [TimeSeriesPoint],
        points2: [TimeSeriesPoint],
        title: String,
        label1: String,
        label2: String,
        color1: Color,
        color2: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 12) {
                    Label(label1, systemImage: "circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(color1)
                    Label(label2, systemImage: "circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(color2)
                }
            }
            
            if points1.isEmpty && points2.isEmpty {
                Rectangle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(height: 180)
                    .overlay(
                        Text("Gathering throughput data...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    )
            } else {
                Chart {
                    ForEach(points1) { pt in
                        LineMark(
                            x: .value("Time", pt.timestamp),
                            y: .value("Speed", pt.value),
                            series: .value("Series", label1)
                        )
                        .foregroundStyle(color1)
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    ForEach(points2) { pt in
                        LineMark(
                            x: .value("Time", pt.timestamp),
                            y: .value("Speed", pt.value),
                            series: .value("Series", label2)
                        )
                        .foregroundStyle(color2)
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour().minute().second())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text(ByteFormatter.formatSpeed(val))
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
    }
}
