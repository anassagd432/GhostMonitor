import Foundation
import IOKit
import IOKit.ps

public final class BatteryMetricProvider: MetricProvider, Sendable {
    public init() {}
    
    public func collect() async throws -> BatterySnapshot {
        var isPresent = false
        var percentage: Double = 100.0
        var isCharging = false
        var powerSource = "AC Power"
        var timeRemaining: Double? = nil
        
        // 1. IOPS API
        if let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let list = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] {
            for ps in list {
                if let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] {
                    isPresent = true
                    if let curCap = desc[kIOPSCurrentCapacityKey] as? Int,
                       let maxCap = desc[kIOPSMaxCapacityKey] as? Int, maxCap > 0 {
                        percentage = (Double(curCap) / Double(maxCap)) * 100.0
                    }
                    
                    if let state = desc[kIOPSPowerSourceStateKey] as? String {
                        powerSource = state == kIOPSACPowerValue ? "AC Power" : "Battery Power"
                    }
                    
                    if let charging = desc[kIOPSIsChargingKey] as? Bool {
                        isCharging = charging
                    }
                    
                    if let timeToEmpty = desc[kIOPSTimeToEmptyKey] as? Int, timeToEmpty > 0 {
                        timeRemaining = Double(timeToEmpty * 60)
                    } else if let timeToFull = desc["TimeToFull"] as? Int ?? desc["Time to Full Charge"] as? Int, timeToFull > 0 {
                        timeRemaining = Double(timeToFull * 60)
                    }
                }
            }
        }
        
        // 2. IOKit AppleSmartBattery Registry
        var cycleCount: Int? = nil
        var designCapacity: Int? = nil
        var maxCapacityPercentage: Double? = nil
        var condition = "Normal"
        var powerDrawWatts: Double? = nil
        var temperatureCelsius: Double? = nil
        
        let matchDict = IOServiceMatching("AppleSmartBattery")
        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matchDict, &iterator)
        
        if kr == KERN_SUCCESS {
            let battery = IOIteratorNext(iterator)
            if battery != 0 {
                var properties: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(battery, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let props = properties?.takeRetainedValue() as? [String: Any] {
                    
                    if let cycle = props["CycleCount"] as? Int {
                        cycleCount = cycle
                    }
                    
                    if let design = props["DesignCapacity"] as? Int {
                        designCapacity = design
                    }
                    
                    let maxCap = props["AppleRawMaxCapacity"] as? Int ?? props["MaxCapacity"] as? Int
                    if let maxCap = maxCap, let design = designCapacity, design > 0 {
                        maxCapacityPercentage = min(100.0, max(0.0, (Double(maxCap) / Double(design)) * 100.0))
                    }
                    
                    if let cond = props["BatteryHealth"] as? String {
                        condition = cond
                    } else if let healthCondition = props["PermanentFailureStatus"] as? Int, healthCondition != 0 {
                        condition = "Service Recommended"
                    }
                    
                    let amp = props["Amperage"] as? Int64 ?? (props["Amperage"] as? Int).map { Int64($0) }
                    let volt = props["Voltage"] as? Int64 ?? (props["Voltage"] as? Int).map { Int64($0) }
                    
                    if let amp = amp, let volt = volt {
                        let watts = (Double(abs(amp)) * Double(volt)) / 1_000_000.0
                        powerDrawWatts = watts
                    }
                    
                    if let rawTemp = props["Temperature"] as? Double ?? (props["Temperature"] as? Int).map({ Double($0) }) {
                        // Temperature is reported in 1/10ths of a Kelvin (e.g. 3062 = 306.2 K = 33.05 °C)
                        let kelvin = rawTemp / 10.0
                        if kelvin > 200 && kelvin < 400 {
                            temperatureCelsius = kelvin - 273.15
                        }
                    }
                }
                IOObjectRelease(battery)
            }
            IOObjectRelease(iterator)
        }
        
        return BatterySnapshot(
            timestamp: Date(),
            isPresent: isPresent,
            percentage: min(100.0, max(0.0, percentage)),
            isCharging: isCharging,
            powerSource: powerSource,
            timeRemainingSeconds: timeRemaining,
            cycleCount: cycleCount,
            maxCapacityPercentage: maxCapacityPercentage,
            designCapacity: designCapacity,
            condition: condition,
            powerDrawWatts: powerDrawWatts,
            temperatureCelsius: temperatureCelsius
        )
    }
}
