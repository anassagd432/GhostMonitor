import XCTest
@testable import GhostMonitor

final class MemoryCalculationTests: XCTestCase {
    func testMemorySnapshotCalculations() {
        let total: Int64 = 16 * 1024 * 1024 * 1024 // 16 GB
        let used: Int64 = 8 * 1024 * 1024 * 1024  // 8 GB
        let free: Int64 = 8 * 1024 * 1024 * 1024
        
        let snapshot = MemorySnapshot(
            totalBytes: total,
            usedBytes: used,
            freeBytes: free,
            activeBytes: 4 * 1024 * 1024 * 1024,
            inactiveBytes: 2 * 1024 * 1024 * 1024,
            wiredBytes: 2 * 1024 * 1024 * 1024,
            compressedBytes: 0,
            cachedBytes: 1 * 1024 * 1024 * 1024,
            swapUsedBytes: 0,
            pressurePercentage: 50.0,
            pressureStatus: .normal
        )
        
        XCTAssertEqual(snapshot.usedPercentage, 50.0, accuracy: 0.1)
    }
}
