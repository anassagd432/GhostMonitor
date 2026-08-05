import Foundation
import IOKit

public final class StorageMetricProvider: MetricProvider, @unchecked Sendable {
    private var prevReadBytes: Int64 = 0
    private var prevWriteBytes: Int64 = 0
    private var prevTime: Date?
    private let lock = NSLock()
    
    public init() {}
    
    public func collect() async throws -> StorageSnapshot {
        return lock.withLock {
            let now = Date()
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeIsInternalKey,
            .volumeIsRemovableKey,
            .volumeLocalizedFormatDescriptionKey
        ]
        
        var volumes: [StorageVolume] = []
        var totalCap: Int64 = 0
        var totalUsed: Int64 = 0
        var totalFree: Int64 = 0
        
        if let urls = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) {
            for url in urls {
                guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
                let name = values.volumeName ?? url.lastPathComponent
                let mountPoint = url.path
                let total = Int64(values.volumeTotalCapacity ?? 0)
                let free = Int64(values.volumeAvailableCapacity ?? 0)
                let used = max(0, total - free)
                let isInternal = values.volumeIsInternal ?? true
                let isRemovable = values.volumeIsRemovable ?? false
                let filesystem = values.volumeLocalizedFormatDescription ?? "APFS"
                
                guard total > 0 else { continue }
                
                let vol = StorageVolume(
                    name: name,
                    mountPoint: mountPoint,
                    totalBytes: total,
                    usedBytes: used,
                    freeBytes: free,
                    filesystem: filesystem,
                    isInternal: isInternal,
                    isRemovable: isRemovable
                )
                volumes.append(vol)
                
                if isInternal && mountPoint == "/" {
                    totalCap = total
                    totalUsed = used
                    totalFree = free
                }
            }
        }
        
        if totalCap == 0 && !volumes.isEmpty {
            totalCap = volumes.reduce(0) { $0 + $1.totalBytes }
            totalUsed = volumes.reduce(0) { $0 + $1.usedBytes }
            totalFree = volumes.reduce(0) { $0 + $1.freeBytes }
        }
        
        // Compute Disk Read/Write speeds via IOKit IOBlockStorageDriver
        let (currentRead, currentWrite) = fetchDiskIOBytes()
        
        var readSpeed: Double = 0
        var writeSpeed: Double = 0
        
        if let prevTime = prevTime {
            let deltaTime = now.timeIntervalSince(prevTime)
            if deltaTime > 0 {
                let readDelta = Double(max(0, currentRead - prevReadBytes))
                let writeDelta = Double(max(0, currentWrite - prevWriteBytes))
                readSpeed = readDelta / deltaTime
                writeSpeed = writeDelta / deltaTime
            }
        }
        
        prevReadBytes = currentRead
        prevWriteBytes = currentWrite
        prevTime = now
        
        return StorageSnapshot(
            timestamp: now,
            volumes: volumes,
            totalCapacityBytes: totalCap,
            totalUsedBytes: totalUsed,
            totalFreeBytes: totalFree,
            aggregateReadSpeed: readSpeed,
            aggregateWriteSpeed: writeSpeed
        )
        }
    }
    
    private func fetchDiskIOBytes() -> (Int64, Int64) {
        let matchDict = IOServiceMatching("IOBlockStorageDriver")
        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matchDict, &iterator)
        
        guard kr == KERN_SUCCESS else { return (0, 0) }
        defer { IOObjectRelease(iterator) }
        
        var totalRead: Int64 = 0
        var totalWrite: Int64 = 0
        var drive = IOIteratorNext(iterator)
        
        while drive != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(drive, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let props = properties?.takeRetainedValue() as? [String: Any],
               let stats = props["Statistics"] as? [String: Any] {
                if let read = stats["Bytes (Read)"] as? Int64 ?? stats["BytesRead"] as? Int64 {
                    totalRead += read
                }
                if let write = stats["Bytes (Write)"] as? Int64 ?? stats["BytesWritten"] as? Int64 {
                    totalWrite += write
                }
            }
            IOObjectRelease(drive)
            drive = IOIteratorNext(iterator)
        }
        
        return (totalRead, totalWrite)
    }
}
