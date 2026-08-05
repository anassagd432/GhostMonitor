import Foundation
import Darwin
import AppKit

public final class ProcessMetricProvider: MetricProvider, @unchecked Sendable {
    private struct PrevCPUInfo {
        let time: Date
        let totalCPUTimeNano: UInt64
    }
    
    private var prevProcessCPUTimes: [pid_t: PrevCPUInfo] = [:]
    private var userCache: [uid_t: String] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public func collect() async throws -> [ProcessItem] {
        return lock.withLock {
            let now = Date()
        var pids = [pid_t](repeating: 0, count: 1024)
        let bytes = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(MemoryLayout<pid_t>.size * pids.count))
        let count = max(0, Int(bytes) / MemoryLayout<pid_t>.size)
        
        var activePids = Set<pid_t>()
        var items: [ProcessItem] = []
        items.reserveCapacity(count)
        
        let numCores = Double(ProcessInfo.processInfo.activeProcessorCount)
        var pathBuffer = [CChar](repeating: 0, count: 1024)
        
        for i in 0..<count {
            let pid = pids[i]
            guard pid > 0 else { continue }
            activePids.insert(pid)
            
            var taskInfo = proc_taskinfo()
            let taskSize = Int32(MemoryLayout<proc_taskinfo>.size)
            guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, taskSize) == taskSize else { continue }
            
            var bsdInfo = proc_bsdinfo()
            let bsdSize = Int32(MemoryLayout<proc_bsdinfo>.size)
            let bsdResult = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsdInfo, bsdSize)
            
            let uid = bsdResult == bsdSize ? bsdInfo.pbi_uid : 999
            let user = getUserName(uid: uid)
            let isSystem = uid < 500 || pid <= 100
            
            pathBuffer[0] = 0
            proc_pidpath(pid, &pathBuffer, 1024)
            let rawPath = String(cString: pathBuffer)
            
            var name = withUnsafeBytes(of: bsdInfo.pbi_name) { ptr -> String in
                if let base = ptr.baseAddress?.assumingMemoryBound(to: CChar.self) {
                    return String(cString: base)
                }
                return ""
            }
            
            if name.isEmpty {
                name = (rawPath as NSString).lastPathComponent
            }
            if name.isEmpty {
                name = "Process \(pid)"
            }
            
            let totalCpuNano = taskInfo.pti_total_user + taskInfo.pti_total_system
            var cpuPercentage: Double = 0.0
            
            if let prev = prevProcessCPUTimes[pid] {
                let dt = now.timeIntervalSince(prev.time)
                if dt > 0 {
                    let cpuDeltaNano = Double(totalCpuNano >= prev.totalCPUTimeNano ? totalCpuNano - prev.totalCPUTimeNano : 0)
                    let secondsUsed = cpuDeltaNano / 1_000_000_000.0
                    cpuPercentage = (secondsUsed / dt) * 100.0
                }
            }
            
            prevProcessCPUTimes[pid] = PrevCPUInfo(time: now, totalCPUTimeNano: totalCpuNano)
            
            let residentBytes = Int64(taskInfo.pti_resident_size)
            let runtimeSeconds = Double(totalCpuNano) / 1_000_000_000.0
            let stateStr = bsdResult == bsdSize ? getProcStateString(bsdInfo.pbi_status) : "Running"
            
            items.append(
                ProcessItem(
                    pid: pid,
                    name: name,
                    user: user,
                    cpuUsagePercentage: min(numCores * 100.0, max(0.0, cpuPercentage)),
                    memoryBytes: residentBytes,
                    runtimeSeconds: runtimeSeconds,
                    state: stateStr,
                    iconPath: rawPath.isEmpty ? nil : rawPath,
                    isSystemProcess: isSystem
                )
            )
        }
        
        prevProcessCPUTimes = prevProcessCPUTimes.filter { activePids.contains($0.key) }
        return items
        }
    }
    
    private func getUserName(uid: uid_t) -> String {
        if let cached = userCache[uid] { return cached }
        if uid == 0 {
            userCache[0] = "root"
            return "root"
        }
        if let pwd = getpwuid(uid) {
            let name = String(cString: pwd.pointee.pw_name)
            userCache[uid] = name
            return name
        }
        let str = "\(uid)"
        userCache[uid] = str
        return str
    }
    
    private func getProcStateString(_ status: UInt32) -> String {
        switch status {
        case UInt32(SIDL): return "Idle"
        case UInt32(SRUN): return "Running"
        case UInt32(SSLEEP): return "Sleeping"
        case UInt32(SSTOP): return "Stopped"
        case UInt32(SZOMB): return "Zombie"
        default: return "Active"
        }
    }
    
    public static func terminateProcess(pid: pid_t, force: Bool) -> Bool {
        guard pid > 1 else { return false }
        let signal = force ? SIGKILL : SIGTERM
        return kill(pid, signal) == 0
    }
}
