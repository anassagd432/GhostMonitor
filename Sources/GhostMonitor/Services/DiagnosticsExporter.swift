import Foundation
import AppKit

@MainActor
public enum DiagnosticsExporter {
    @MainActor
    public static func exportReport(coordinator: MonitoringCoordinator) {
        guard let hw = coordinator.hardware,
              let cpu = coordinator.cpu,
              let mem = coordinator.memory,
              let storage = coordinator.storage,
              let bat = coordinator.battery,
              let therm = coordinator.thermal else {
            let alert = NSAlert()
            alert.messageText = "Export Diagnostics Unavailable"
            alert.informativeText = "System metrics are still loading. Please try again in a moment."
            alert.runModal()
            return
        }
        
        let reportDict: [String: Any] = [
            "application": "Ghost Monitor",
            "version": "1.0.0",
            "exportTimestamp": ISO8601DateFormatter().string(from: Date()),
            "system": [
                "model": hw.friendlyModelName,
                "modelIdentifier": hw.modelIdentifier,
                "chip": hw.chipName,
                "macosVersion": hw.macosVersion,
                "hostname": hw.hostname,
                "uptimeSeconds": hw.uptimeSeconds
            ],
            "cpu": [
                "totalUsagePercentage": cpu.totalUsagePercentage,
                "pCoreUsagePercentage": cpu.pCoreUsagePercentage,
                "eCoreUsagePercentage": cpu.eCoreUsagePercentage,
                "loadAvg1m": cpu.loadAvg1m,
                "loadAvg5m": cpu.loadAvg5m,
                "loadAvg15m": cpu.loadAvg15m
            ],
            "memory": [
                "totalBytes": mem.totalBytes,
                "usedBytes": mem.usedBytes,
                "freeBytes": mem.freeBytes,
                "wiredBytes": mem.wiredBytes,
                "activeBytes": mem.activeBytes,
                "inactiveBytes": mem.inactiveBytes,
                "compressedBytes": mem.compressedBytes,
                "swapUsedBytes": mem.swapUsedBytes,
                "pressurePercentage": mem.pressurePercentage
            ],
            "storage": [
                "totalCapacityBytes": storage.totalCapacityBytes,
                "totalUsedBytes": storage.totalUsedBytes,
                "totalFreeBytes": storage.totalFreeBytes,
                "primaryUsagePercentage": storage.primaryUsagePercentage,
                "readSpeedBytesPerSec": storage.aggregateReadSpeed,
                "writeSpeedBytesPerSec": storage.aggregateWriteSpeed
            ],
            "battery": [
                "isPresent": bat.isPresent,
                "percentage": bat.percentage,
                "isCharging": bat.isCharging,
                "powerSource": bat.powerSource,
                "cycleCount": bat.cycleCount ?? -1,
                "maxCapacityPercentage": bat.maxCapacityPercentage ?? -1,
                "condition": bat.condition
            ],
            "thermal": [
                "state": therm.thermalStateLabel,
                "isFanless": therm.isFanless,
                "isThrottling": therm.isThrottling
            ],
            "warnings": coordinator.activeWarnings
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: reportDict, options: [.prettyPrinted, .sortedKeys]) else { return }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Export Ghost Monitor Diagnostics"
        savePanel.nameFieldStringValue = "GhostMonitor_Diagnostics_\(Int(Date().timeIntervalSince1970)).json"
        savePanel.allowedContentTypes = [.json]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? jsonData.write(to: url)
            }
        }
    }
}
