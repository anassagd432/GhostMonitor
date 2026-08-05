import XCTest
@testable import GhostMonitor

final class ProcessSortingTests: XCTestCase {
    func testProcessSortingByCPU() {
        let p1 = ProcessItem(pid: 100, name: "Alpha", user: "user", cpuUsagePercentage: 15.0, memoryBytes: 100, runtimeSeconds: 10, state: "Run", iconPath: nil, isSystemProcess: false)
        let p2 = ProcessItem(pid: 200, name: "Beta", user: "user", cpuUsagePercentage: 45.0, memoryBytes: 50, runtimeSeconds: 20, state: "Run", iconPath: nil, isSystemProcess: false)
        let p3 = ProcessItem(pid: 300, name: "Gamma", user: "user", cpuUsagePercentage: 5.0, memoryBytes: 200, runtimeSeconds: 30, state: "Run", iconPath: nil, isSystemProcess: false)
        
        var list = [p1, p2, p3]
        list.sort { $0.cpuUsagePercentage > $1.cpuUsagePercentage }
        
        XCTAssertEqual(list.map(\.pid), [200, 100, 300])
    }
}
