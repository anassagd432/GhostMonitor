import XCTest
@testable import GhostMonitor

final class RingBufferTests: XCTestCase {
    func testRingBufferCapacity() {
        let buffer = RingBuffer<Int>(capacity: 3)
        XCTAssertEqual(buffer.currentCount, 0)
        
        buffer.append(10)
        buffer.append(20)
        XCTAssertEqual(buffer.values(), [10, 20])
        
        buffer.append(30)
        XCTAssertEqual(buffer.values(), [10, 20, 30])
        
        buffer.append(40)
        XCTAssertEqual(buffer.values(), [20, 30, 40])
        
        buffer.append(50)
        XCTAssertEqual(buffer.values(), [30, 40, 50])
    }
    
    func testRingBufferClear() {
        let buffer = RingBuffer<String>(capacity: 5)
        buffer.append("A")
        buffer.append("B")
        XCTAssertEqual(buffer.currentCount, 2)
        
        buffer.clear()
        XCTAssertEqual(buffer.currentCount, 0)
        XCTAssertEqual(buffer.values(), [])
    }
}
