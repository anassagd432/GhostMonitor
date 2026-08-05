import Foundation
import Darwin

public final class CPUMetricProvider: MetricProvider, @unchecked Sendable {
    private struct CPUTicks {
        let user: UInt32
        let system: UInt32
        let idle: UInt32
        let nice: UInt32
        
        var total: UInt32 { user + system + idle + nice }
    }
    
    private var previousTicks: [CPUTicks] = []
    private let lock = NSLock()
    
    public init() {
        Task { [weak self] in
            _ = try? await self?.collect()
        }
    }
    
    public func collect() async throws -> CPUSnapshot {
        return lock.withLock {
            var numCPUs: natural_t = 0
            var cpuInfo: processor_info_array_t?
            var numCpuInfo: mach_msg_type_number_t = 0
            
            let result = host_processor_info(
                mach_host_self(),
                PROCESSOR_CPU_LOAD_INFO,
                &numCPUs,
                &cpuInfo,
                &numCpuInfo
            )
            
            guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
                return CPUSnapshot(
                    totalUsagePercentage: 0,
                    pCoreUsagePercentage: 0,
                    eCoreUsagePercentage: 0,
                    perCoreUsages: [],
                    loadAvg1m: 0,
                    loadAvg5m: 0,
                    loadAvg15m: 0
                )
            }
            
            defer {
                let size = vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.size)
                vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: cpuInfo)), size)
            }
            
            var currentTicks: [CPUTicks] = []
            currentTicks.reserveCapacity(Int(numCPUs))
            
            for i in 0..<Int(numCPUs) {
                let offset = i * Int(CPU_STATE_MAX)
                let user = UInt32(cpuInfo[offset + Int(CPU_STATE_USER)])
                let system = UInt32(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
                let idle = UInt32(cpuInfo[offset + Int(CPU_STATE_IDLE)])
                let nice = UInt32(cpuInfo[offset + Int(CPU_STATE_NICE)])
                currentTicks.append(CPUTicks(user: user, system: system, idle: idle, nice: nice))
            }
            
            var perCoreUsages: [Double] = Array(repeating: 0.0, count: Int(numCPUs))
            var totalUsage: Double = 0.0
            
            if !previousTicks.isEmpty && previousTicks.count == currentTicks.count {
                var sumUsage: Double = 0.0
                for i in 0..<Int(numCPUs) {
                    let prev = previousTicks[i]
                    let curr = currentTicks[i]
                    
                    let userDelta = Double(curr.user >= prev.user ? curr.user - prev.user : 0)
                    let sysDelta = Double(curr.system >= prev.system ? curr.system - prev.system : 0)
                    let niceDelta = Double(curr.nice >= prev.nice ? curr.nice - prev.nice : 0)
                    let idleDelta = Double(curr.idle >= prev.idle ? curr.idle - prev.idle : 0)
                    
                    let totalDelta = userDelta + sysDelta + niceDelta + idleDelta
                    let activeDelta = userDelta + sysDelta + niceDelta
                    
                    let usage = totalDelta > 0 ? (activeDelta / totalDelta) * 100.0 : 0.0
                    perCoreUsages[i] = min(100.0, max(0.0, usage))
                    sumUsage += perCoreUsages[i]
                }
                totalUsage = sumUsage / Double(numCPUs)
            }
            
            previousTicks = currentTicks
            
            // Split P-cores and E-cores
            let half = Int(numCPUs) / 2
            var pCoreUsage: Double = totalUsage
            var eCoreUsage: Double = totalUsage
            
            if numCPUs >= 4 && half > 0 {
                let eCores = perCoreUsages.prefix(half)
                let pCores = perCoreUsages.suffix(Int(numCPUs) - half)
                
                eCoreUsage = eCores.reduce(0, +) / Double(eCores.count)
                pCoreUsage = pCores.reduce(0, +) / Double(pCores.count)
            }
            
            var loadAvg: [Double] = [0.0, 0.0, 0.0]
            getloadavg(&loadAvg, 3)
            
            return CPUSnapshot(
                totalUsagePercentage: totalUsage,
                pCoreUsagePercentage: pCoreUsage,
                eCoreUsagePercentage: eCoreUsage,
                perCoreUsages: perCoreUsages,
                loadAvg1m: loadAvg[0],
                loadAvg5m: loadAvg[1],
                loadAvg15m: loadAvg[2]
            )
        }
    }
}
