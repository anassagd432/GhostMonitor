import Foundation

public final class HardwareInfoProvider: MetricProvider, Sendable {
    public init() {}
    
    public func collectSync() -> HardwareSnapshot {
        let modelIdentifier = SysctlHelper.string(for: "hw.model") ?? "Mac"
        let chipName = SysctlHelper.string(for: "machdep.cpu.brand_string") ?? "Apple Silicon"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let hostname = Host.current().localizedName ?? SysctlHelper.string(for: "kern.hostname") ?? "Mac"
        let uptime = ProcessInfo.processInfo.systemUptime
        let bootTime = SysctlHelper.bootTime()
        
        var activeCores: Int32 = 0
        var size: Int = MemoryLayout<Int32>.size
        sysctlbyname("hw.activecpu", &activeCores, &size, nil, 0)
        let totalCores = Int(activeCores > 0 ? activeCores : 8)
        
        var pCores: Int32 = 0
        size = MemoryLayout<Int32>.size
        sysctlbyname("hw.perflevel0.physicalcpu", &pCores, &size, nil, 0)
        
        var eCores: Int32 = 0
        size = MemoryLayout<Int32>.size
        sysctlbyname("hw.perflevel1.physicalcpu", &eCores, &size, nil, 0)
        
        let pCoreCount = pCores > 0 ? Int(pCores) : totalCores / 2
        let eCoreCount = eCores > 0 ? Int(eCores) : totalCores - pCoreCount
        
        let friendlyModel = friendlyName(for: modelIdentifier)
        let isAppleSilicon = chipName.contains("Apple") || modelIdentifier.contains("MacBookAir10") || modelIdentifier.contains("Mac")
        
        return HardwareSnapshot(
            modelIdentifier: modelIdentifier,
            friendlyModelName: friendlyModel,
            chipName: chipName,
            macosVersion: osVersion,
            hostname: hostname,
            bootTime: bootTime,
            uptimeSeconds: uptime,
            totalCores: totalCores,
            pCoreCount: pCoreCount,
            eCoreCount: eCoreCount,
            isAppleSilicon: isAppleSilicon
        )
    }
    
    public func collect() async throws -> HardwareSnapshot {
        return collectSync()
    }
    
    private func friendlyName(for identifier: String) -> String {
        switch identifier {
        case "MacBookAir10,1":
            return "MacBook Air (M1, 2020)"
        case "MacBookAir14,2":
            return "MacBook Air (M2, 2022)"
        case "MacBookAir15,3", "MacBookAir15,12":
            return "MacBook Air (M3, 2024)"
        case "Mac14,2", "Mac14,7":
            return "MacBook Pro (M2, 2023)"
        case "Mac15,3", "Mac15,6", "Mac15,8", "Mac15,10":
            return "MacBook Pro (M3, 2023/2024)"
        default:
            if identifier.hasPrefix("MacBookAir") { return "MacBook Air" }
            if identifier.hasPrefix("MacBookPro") { return "MacBook Pro" }
            if identifier.hasPrefix("Macmini") { return "Mac mini" }
            if identifier.hasPrefix("MacStudio") { return "Mac Studio" }
            if identifier.hasPrefix("MacPro") { return "Mac Pro" }
            return identifier
        }
    }
}
