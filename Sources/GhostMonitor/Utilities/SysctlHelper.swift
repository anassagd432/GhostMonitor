import Foundation
import Darwin

public enum SysctlHelper {
    public static func string(for name: String) -> String? {
        var size: Int = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var data = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &data, &size, nil, 0) == 0 else { return nil }
        return String(cString: data).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public static func int64(for name: String) -> Int64? {
        var val: Int64 = 0
        var size = MemoryLayout<Int64>.size
        guard sysctlbyname(name, &val, &size, nil, 0) == 0 else { return nil }
        return val
    }
    
    public static func int32(for name: String) -> Int32? {
        var val: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname(name, &val, &size, nil, 0) == 0 else { return nil }
        return val
    }
    
    public static func bootTime() -> Date? {
        var bootTime = timeval()
        var size = MemoryLayout<timeval>.size
        guard sysctlbyname("kern.boottime", &bootTime, &size, nil, 0) == 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(bootTime.tv_sec))
    }
}
