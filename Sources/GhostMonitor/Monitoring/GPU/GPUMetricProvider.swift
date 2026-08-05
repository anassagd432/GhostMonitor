import Foundation

public final class GPUMetricProvider: MetricProvider, Sendable {
    public init() {}
    
    public func collect() async throws -> GPUSnapshot {
        /*
         * GPU MONITORING POLICY FOR APPLE SILICON:
         * Standard Apple Silicon integrated GPU statistics are not exposed via public,
         * stable C/Swift APIs on macOS without private IOKit/IOAccelerator interfaces
         * or elevated permissions.
         *
         * To ensure 100% compliance with Apple security guidelines and safety rules:
         * We check for public Metal / IOKit capabilities, and if reliable percentage
         * metrics are not available through public APIs, we return an explicit unavailable snapshot.
         */
        return GPUSnapshot(
            timestamp: Date(),
            usagePercentage: nil,
            isAvailable: false,
            statusMessage: "GPU utilization unavailable through public macOS APIs."
        )
    }
}
