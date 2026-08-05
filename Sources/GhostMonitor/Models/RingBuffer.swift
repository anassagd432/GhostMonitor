import Foundation

public struct TimeSeriesPoint: Codable, Sendable, Identifiable {
    public var id: TimeInterval { timestamp.timeIntervalSince1970 }
    public let timestamp: Date
    public let value: Double
    
    public init(timestamp: Date = Date(), value: Double) {
        self.timestamp = timestamp
        self.value = value
    }
}

public struct DualTimeSeriesPoint: Codable, Sendable, Identifiable {
    public var id: TimeInterval { timestamp.timeIntervalSince1970 }
    public let timestamp: Date
    public let value1: Double
    public let value2: Double
    
    public init(timestamp: Date = Date(), value1: Double, value2: Double) {
        self.timestamp = timestamp
        self.value1 = value1
        self.value2 = value2
    }
}

public final class RingBuffer<T: Sendable>: @unchecked Sendable {
    private var buffer: [T?]
    private var writeIndex = 0
    private var count = 0
    private let capacity: Int
    private let lock = NSLock()
    
    public init(capacity: Int) {
        self.capacity = max(1, capacity)
        self.buffer = Array(repeating: nil, count: self.capacity)
    }
    
    public func append(_ element: T) {
        lock.lock()
        defer { lock.unlock() }
        
        buffer[writeIndex] = element
        writeIndex = (writeIndex + 1) % capacity
        if count < capacity {
            count += 1
        }
    }
    
    public func values() -> [T] {
        lock.lock()
        defer { lock.unlock() }
        
        guard count > 0 else { return [] }
        var result: [T] = []
        result.reserveCapacity(count)
        
        let startIndex = count < capacity ? 0 : writeIndex
        for i in 0..<count {
            let idx = (startIndex + i) % capacity
            if let val = buffer[idx] {
                result.append(val)
            }
        }
        return result
    }
    
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        buffer = Array(repeating: nil, count: capacity)
        writeIndex = 0
        count = 0
    }
    
    public var currentCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }
}
