import Foundation
import AppKit

public enum StatusLevel: String, Codable, Sendable {
    case normal = "Normal"
    case attention = "Attention"
    case warning = "Warning"
    case critical = "Critical"
    
    public var colorName: String {
        switch self {
        case .normal: return "systemGreen"
        case .attention: return "systemBlue"
        case .warning: return "systemOrange"
        case .critical: return "systemRed"
        }
    }
}

public struct CPUSnapshot: Codable, Sendable {
    public let timestamp: Date
    public let totalUsagePercentage: Double
    public let pCoreUsagePercentage: Double
    public let eCoreUsagePercentage: Double
    public let perCoreUsages: [Double]
    public let loadAvg1m: Double
    public let loadAvg5m: Double
    public let loadAvg15m: Double
    
    public init(
        timestamp: Date = Date(),
        totalUsagePercentage: Double,
        pCoreUsagePercentage: Double,
        eCoreUsagePercentage: Double,
        perCoreUsages: [Double],
        loadAvg1m: Double,
        loadAvg5m: Double,
        loadAvg15m: Double
    ) {
        self.timestamp = timestamp
        self.totalUsagePercentage = totalUsagePercentage
        self.pCoreUsagePercentage = pCoreUsagePercentage
        self.eCoreUsagePercentage = eCoreUsagePercentage
        self.perCoreUsages = perCoreUsages
        self.loadAvg1m = loadAvg1m
        self.loadAvg5m = loadAvg5m
        self.loadAvg15m = loadAvg15m
    }
}

public struct MemorySnapshot: Codable, Sendable {
    public let timestamp: Date
    public let totalBytes: Int64
    public let usedBytes: Int64
    public let freeBytes: Int64
    public let activeBytes: Int64
    public let inactiveBytes: Int64
    public let wiredBytes: Int64
    public let compressedBytes: Int64
    public let cachedBytes: Int64
    public let swapUsedBytes: Int64
    public let pressurePercentage: Double
    public let pressureStatus: StatusLevel
    
    public var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return (Double(usedBytes) / Double(totalBytes)) * 100.0
    }
    
    public init(
        timestamp: Date = Date(),
        totalBytes: Int64,
        usedBytes: Int64,
        freeBytes: Int64,
        activeBytes: Int64,
        inactiveBytes: Int64,
        wiredBytes: Int64,
        compressedBytes: Int64,
        cachedBytes: Int64,
        swapUsedBytes: Int64,
        pressurePercentage: Double,
        pressureStatus: StatusLevel
    ) {
        self.timestamp = timestamp
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
        self.activeBytes = activeBytes
        self.inactiveBytes = inactiveBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.cachedBytes = cachedBytes
        self.swapUsedBytes = swapUsedBytes
        self.pressurePercentage = pressurePercentage
        self.pressureStatus = pressureStatus
    }
}

public struct GPUSnapshot: Codable, Sendable {
    public let timestamp: Date
    public let usagePercentage: Double?
    public let isAvailable: Bool
    public let statusMessage: String
    
    public init(
        timestamp: Date = Date(),
        usagePercentage: Double? = nil,
        isAvailable: Bool = false,
        statusMessage: String = "GPU utilization unavailable through public macOS APIs."
    ) {
        self.timestamp = timestamp
        self.usagePercentage = usagePercentage
        self.isAvailable = isAvailable
        self.statusMessage = statusMessage
    }
}

public struct StorageVolume: Codable, Sendable, Identifiable {
    public var id: String { mountPoint }
    public let name: String
    public let mountPoint: String
    public let totalBytes: Int64
    public let usedBytes: Int64
    public let freeBytes: Int64
    public let filesystem: String
    public let isInternal: Bool
    public let isRemovable: Bool
    public let readSpeedBytesPerSec: Double
    public let writeSpeedBytesPerSec: Double
    
    public var usagePercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return (Double(usedBytes) / Double(totalBytes)) * 100.0
    }
    
    public init(
        name: String,
        mountPoint: String,
        totalBytes: Int64,
        usedBytes: Int64,
        freeBytes: Int64,
        filesystem: String,
        isInternal: Bool,
        isRemovable: Bool,
        readSpeedBytesPerSec: Double = 0,
        writeSpeedBytesPerSec: Double = 0
    ) {
        self.name = name
        self.mountPoint = mountPoint
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
        self.filesystem = filesystem
        self.isInternal = isInternal
        self.isRemovable = isRemovable
        self.readSpeedBytesPerSec = readSpeedBytesPerSec
        self.writeSpeedBytesPerSec = writeSpeedBytesPerSec
    }
}

public struct StorageSnapshot: Codable, Sendable {
    public let timestamp: Date
    public let volumes: [StorageVolume]
    public let totalCapacityBytes: Int64
    public let totalUsedBytes: Int64
    public let totalFreeBytes: Int64
    public let aggregateReadSpeed: Double
    public let aggregateWriteSpeed: Double
    
    public var primaryUsagePercentage: Double {
        guard totalCapacityBytes > 0 else { return 0 }
        return (Double(totalUsedBytes) / Double(totalCapacityBytes)) * 100.0
    }
    
    public init(
        timestamp: Date = Date(),
        volumes: [StorageVolume],
        totalCapacityBytes: Int64,
        totalUsedBytes: Int64,
        totalFreeBytes: Int64,
        aggregateReadSpeed: Double,
        aggregateWriteSpeed: Double
    ) {
        self.timestamp = timestamp
        self.volumes = volumes
        self.totalCapacityBytes = totalCapacityBytes
        self.totalUsedBytes = totalUsedBytes
        self.totalFreeBytes = totalFreeBytes
        self.aggregateReadSpeed = aggregateReadSpeed
        self.aggregateWriteSpeed = aggregateWriteSpeed
    }
}

public struct NetworkInterfaceSnapshot: Codable, Sendable, Identifiable {
    public var id: String { interfaceName }
    public let interfaceName: String
    public let ipAddress: String
    public let isWifi: Bool
    public let isEthernet: Bool
    public let downloadSpeedBytesPerSec: Double
    public let uploadSpeedBytesPerSec: Double
    public let totalBytesReceived: UInt64
    public let totalBytesSent: UInt64
    
    public init(
        interfaceName: String,
        ipAddress: String,
        isWifi: Bool,
        isEthernet: Bool,
        downloadSpeedBytesPerSec: Double,
        uploadSpeedBytesPerSec: Double,
        totalBytesReceived: UInt64,
        totalBytesSent: UInt64
    ) {
        self.interfaceName = interfaceName
        self.ipAddress = ipAddress
        self.isWifi = isWifi
        self.isEthernet = isEthernet
        self.downloadSpeedBytesPerSec = downloadSpeedBytesPerSec
        self.uploadSpeedBytesPerSec = uploadSpeedBytesPerSec
        self.totalBytesReceived = totalBytesReceived
        self.totalBytesSent = totalBytesSent
    }
}

public struct NetworkSnapshot: Codable, Sendable {
    public let timestamp: Date
    public let primaryInterfaceName: String
    public let activeInterfaces: [NetworkInterfaceSnapshot]
    public let totalDownloadSpeed: Double
    public let totalUploadSpeed: Double
    public let totalBytesReceived: UInt64
    public let totalBytesSent: UInt64
    public let isConnected: Bool
    
    public init(
        timestamp: Date = Date(),
        primaryInterfaceName: String,
        activeInterfaces: [NetworkInterfaceSnapshot],
        totalDownloadSpeed: Double,
        totalUploadSpeed: Double,
        totalBytesReceived: UInt64,
        totalBytesSent: UInt64,
        isConnected: Bool
    ) {
        self.timestamp = timestamp
        self.primaryInterfaceName = primaryInterfaceName
        self.activeInterfaces = activeInterfaces
        self.totalDownloadSpeed = totalDownloadSpeed
        self.totalUploadSpeed = totalUploadSpeed
        self.totalBytesReceived = totalBytesReceived
        self.totalBytesSent = totalBytesSent
        self.isConnected = isConnected
    }
}

public struct BatterySnapshot: Codable, Sendable {
    public let timestamp: Date
    public let isPresent: Bool
    public let percentage: Double
    public let isCharging: Bool
    public let powerSource: String
    public let timeRemainingSeconds: Double?
    public let cycleCount: Int?
    public let maxCapacityPercentage: Double?
    public let designCapacity: Int?
    public let condition: String
    public let powerDrawWatts: Double?
    public let temperatureCelsius: Double?
    
    public init(
        timestamp: Date = Date(),
        isPresent: Bool,
        percentage: Double,
        isCharging: Bool,
        powerSource: String,
        timeRemainingSeconds: Double? = nil,
        cycleCount: Int? = nil,
        maxCapacityPercentage: Double? = nil,
        designCapacity: Int? = nil,
        condition: String = "Normal",
        powerDrawWatts: Double? = nil,
        temperatureCelsius: Double? = nil
    ) {
        self.timestamp = timestamp
        self.isPresent = isPresent
        self.percentage = percentage
        self.isCharging = isCharging
        self.powerSource = powerSource
        self.timeRemainingSeconds = timeRemainingSeconds
        self.cycleCount = cycleCount
        self.maxCapacityPercentage = maxCapacityPercentage
        self.designCapacity = designCapacity
        self.condition = condition
        self.powerDrawWatts = powerDrawWatts
        self.temperatureCelsius = temperatureCelsius
    }
}

public struct ThermalSnapshot: Codable, Sendable {
    public let timestamp: Date
    public let rawThermalState: Int
    public let thermalStateLabel: String
    public let isFanless: Bool
    public let isThrottling: Bool
    public let statusLevel: StatusLevel
    
    public init(
        timestamp: Date = Date(),
        rawThermalState: Int,
        thermalStateLabel: String,
        isFanless: Bool,
        isThrottling: Bool,
        statusLevel: StatusLevel
    ) {
        self.timestamp = timestamp
        self.rawThermalState = rawThermalState
        self.thermalStateLabel = thermalStateLabel
        self.isFanless = isFanless
        self.isThrottling = isThrottling
        self.statusLevel = statusLevel
    }
}

public struct ProcessItem: Identifiable, Sendable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let name: String
    public let user: String
    public let cpuUsagePercentage: Double
    public let memoryBytes: Int64
    public let runtimeSeconds: TimeInterval
    public let state: String
    public let iconPath: String?
    public let isSystemProcess: Bool
    
    public init(
        pid: Int32,
        name: String,
        user: String,
        cpuUsagePercentage: Double,
        memoryBytes: Int64,
        runtimeSeconds: TimeInterval,
        state: String,
        iconPath: String?,
        isSystemProcess: Bool
    ) {
        self.pid = pid
        self.name = name
        self.user = user
        self.cpuUsagePercentage = cpuUsagePercentage
        self.memoryBytes = memoryBytes
        self.runtimeSeconds = runtimeSeconds
        self.state = state
        self.iconPath = iconPath
        self.isSystemProcess = isSystemProcess
    }
}

public struct HardwareSnapshot: Codable, Sendable {
    public let modelIdentifier: String
    public let friendlyModelName: String
    public let chipName: String
    public let macosVersion: String
    public let hostname: String
    public let bootTime: Date?
    public let uptimeSeconds: TimeInterval
    public let totalCores: Int
    public let pCoreCount: Int
    public let eCoreCount: Int
    public let isAppleSilicon: Bool
    
    public init(
        modelIdentifier: String,
        friendlyModelName: String,
        chipName: String,
        macosVersion: String,
        hostname: String,
        bootTime: Date?,
        uptimeSeconds: TimeInterval,
        totalCores: Int,
        pCoreCount: Int,
        eCoreCount: Int,
        isAppleSilicon: Bool
    ) {
        self.modelIdentifier = modelIdentifier
        self.friendlyModelName = friendlyModelName
        self.chipName = chipName
        self.macosVersion = macosVersion
        self.hostname = hostname
        self.bootTime = bootTime
        self.uptimeSeconds = uptimeSeconds
        self.totalCores = totalCores
        self.pCoreCount = pCoreCount
        self.eCoreCount = eCoreCount
        self.isAppleSilicon = isAppleSilicon
    }
}
