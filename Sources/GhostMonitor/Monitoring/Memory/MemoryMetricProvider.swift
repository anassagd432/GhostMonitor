import Foundation
import Darwin

public final class MemoryMetricProvider: MetricProvider, Sendable {
    public init() {}
    
    public func collect() async throws -> MemorySnapshot {
        // 1. Physical Memory Size
        var totalMemoryBytes: Int64 = 0
        var size = MemoryLayout<Int64>.size
        sysctlbyname("hw.memsize", &totalMemoryBytes, &size, nil, 0)
        
        // 2. Page Size
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        let bytesPerPage = Int64(pageSize)
        
        // 3. Host VM Statistics 64
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64_data_t()
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return MemorySnapshot(
                totalBytes: totalMemoryBytes,
                usedBytes: 0,
                freeBytes: totalMemoryBytes,
                activeBytes: 0,
                inactiveBytes: 0,
                wiredBytes: 0,
                compressedBytes: 0,
                cachedBytes: 0,
                swapUsedBytes: 0,
                pressurePercentage: 0,
                pressureStatus: .normal
            )
        }
        
        let freePages = Int64(vmStats.free_count)
        let activePages = Int64(vmStats.active_count)
        let inactivePages = Int64(vmStats.inactive_count)
        let wirePages = Int64(vmStats.wire_count)
        let compressorPages = Int64(vmStats.compressor_page_count)
        let speculativePages = Int64(vmStats.speculative_count)
        let purgeablePages = Int64(vmStats.purgeable_count)
        let externalPages = Int64(vmStats.external_page_count)
        let internalPages = Int64(vmStats.internal_page_count)
        
        _ = freePages * bytesPerPage
        let activeBytes = activePages * bytesPerPage
        let inactiveBytes = inactivePages * bytesPerPage
        let wiredBytes = wirePages * bytesPerPage
        let compressedBytes = compressorPages * bytesPerPage
        _ = speculativePages * bytesPerPage
        let purgeableBytes = purgeablePages * bytesPerPage
        let externalBytes = externalPages * bytesPerPage
        let internalBytes = internalPages * bytesPerPage
        
        let cachedBytes = externalBytes + purgeableBytes
        
        /*
         * MEMORY USED CALCULATION NOTE:
         * Following Apple's macOS Activity Monitor standard methodology:
         * Used Memory = App Memory (Anonymous/Internal) + Wired Memory + Compressed Memory
         * Cached Files = External Pages + Purgeable Pages
         */
        let usedBytes = internalBytes + wiredBytes + compressedBytes
        
        // 4. Swap Usage
        var swapUsage = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        var swapUsedBytes: Int64 = 0
        if sysctlbyname("vm.swapusage", &swapUsage, &swapSize, nil, 0) == 0 {
            swapUsedBytes = Int64(swapUsage.xsu_used)
        }
        
        // 5. Memory Pressure
        // Calculated as percentage of (Wired + Active + Compressed) relative to total RAM
        let pressurePercentage = min(100.0, max(0.0, (Double(wiredBytes + activeBytes + compressedBytes) / Double(max(1, totalMemoryBytes))) * 100.0))
        
        let pressureStatus: StatusLevel
        if pressurePercentage >= 90.0 {
            pressureStatus = .critical
        } else if pressurePercentage >= 75.0 {
            pressureStatus = .warning
        } else if pressurePercentage >= 60.0 {
            pressureStatus = .attention
        } else {
            pressureStatus = .normal
        }
        
        return MemorySnapshot(
            totalBytes: totalMemoryBytes,
            usedBytes: usedBytes,
            freeBytes: max(0, totalMemoryBytes - usedBytes),
            activeBytes: activeBytes,
            inactiveBytes: inactiveBytes,
            wiredBytes: wiredBytes,
            compressedBytes: compressedBytes,
            cachedBytes: cachedBytes,
            swapUsedBytes: swapUsedBytes,
            pressurePercentage: pressurePercentage,
            pressureStatus: pressureStatus
        )
    }
}
