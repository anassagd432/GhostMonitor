import Foundation

public final class ThermalMetricProvider: MetricProvider, Sendable {
    public init() {}
    
    public func collect() async throws -> ThermalSnapshot {
        let processInfoState = ProcessInfo.processInfo.thermalState
        let rawValue = processInfoState.rawValue
        
        let label: String
        let statusLevel: StatusLevel
        let isThrottling: Bool
        
        switch processInfoState {
        case .nominal:
            label = "Nominal"
            statusLevel = .normal
            isThrottling = false
        case .fair:
            label = "Fair"
            statusLevel = .attention
            isThrottling = false
        case .serious:
            label = "Serious"
            statusLevel = .warning
            isThrottling = true
        case .critical:
            label = "Critical"
            statusLevel = .critical
            isThrottling = true
        @unknown default:
            label = "Unknown"
            statusLevel = .normal
            isThrottling = false
        }
        
        // Detect Fanless Mac (e.g. MacBook Air M1 / M2 / M3)
        var isFanless = false
        if let model = SysctlHelper.string(for: "hw.model"), model.contains("MacBookAir") {
            isFanless = true
        }
        
        return ThermalSnapshot(
            timestamp: Date(),
            rawThermalState: rawValue,
            thermalStateLabel: label,
            isFanless: isFanless,
            isThrottling: isThrottling,
            statusLevel: statusLevel
        )
    }
}
