import XCTest
@testable import GhostMonitor

final class ByteFormatterTests: XCTestCase {
    func testFormatBytes() {
        XCTAssertEqual(ByteFormatter.formatBytes(0), "0 B")
        XCTAssertEqual(ByteFormatter.formatBytes(512), "512 B")
        XCTAssertEqual(ByteFormatter.formatBytes(1024), "1.0 KB")
        XCTAssertEqual(ByteFormatter.formatBytes(1048576), "1.0 MB")
        XCTAssertEqual(ByteFormatter.formatBytes(1073741824), "1.0 GB")
        XCTAssertEqual(ByteFormatter.formatBytes(1099511627776), "1.0 TB")
    }
    
    func testFormatSpeed() {
        XCTAssertEqual(ByteFormatter.formatSpeed(0), "0 B/s")
        XCTAssertEqual(ByteFormatter.formatSpeed(500), "500 B/s")
        XCTAssertEqual(ByteFormatter.formatSpeed(1536), "1.5 KB/s")
        XCTAssertEqual(ByteFormatter.formatSpeed(2621440), "2.5 MB/s")
    }
}
