import Foundation

public struct MetricThresholds: Codable, Sendable, Equatable {
    public var cpuWarningPercentage: Double
    public var cpuCriticalPercentage: Double
    public var memoryWarningPercentage: Double
    public var memoryCriticalPercentage: Double
    public var storageWarningPercentage: Double
    public var storageCriticalPercentage: Double
    
    public init(
        cpuWarningPercentage: Double = 75.0,
        cpuCriticalPercentage: Double = 90.0,
        memoryWarningPercentage: Double = 80.0,
        memoryCriticalPercentage: Double = 92.0,
        storageWarningPercentage: Double = 85.0,
        storageCriticalPercentage: Double = 95.0
    ) {
        self.cpuWarningPercentage = cpuWarningPercentage
        self.cpuCriticalPercentage = cpuCriticalPercentage
        self.memoryWarningPercentage = memoryWarningPercentage
        self.memoryCriticalPercentage = memoryCriticalPercentage
        self.storageWarningPercentage = storageWarningPercentage
        self.storageCriticalPercentage = storageCriticalPercentage
    }
    
    public func evaluateCPU(_ percentage: Double) -> StatusLevel {
        if percentage >= cpuCriticalPercentage { return .critical }
        if percentage >= cpuWarningPercentage { return .warning }
        return .normal
    }
    
    public func evaluateMemory(_ percentage: Double) -> StatusLevel {
        if percentage >= memoryCriticalPercentage { return .critical }
        if percentage >= memoryWarningPercentage { return .warning }
        return .normal
    }
    
    public func evaluateStorage(_ percentage: Double) -> StatusLevel {
        if percentage >= storageCriticalPercentage { return .critical }
        if percentage >= storageWarningPercentage { return .warning }
        return .normal
    }
}

public enum ProcessSortField: String, CaseIterable, Identifiable, Codable, Sendable {
    case cpu = "CPU %"
    case memory = "Memory"
    case pid = "PID"
    case name = "Name"
    
    public var id: String { rawValue }
}

public enum HistoryWindow: TimeInterval, CaseIterable, Identifiable, Codable, Sendable {
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case oneHour = 3600
    
    public var id: Double { rawValue }
    
    public var label: String {
        switch self {
        case .oneMinute: return "1m"
        case .fiveMinutes: return "5m"
        case .fifteenMinutes: return "15m"
        case .oneHour: return "1h"
        }
    }
}
