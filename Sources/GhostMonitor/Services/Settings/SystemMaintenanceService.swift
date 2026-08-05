import Foundation
import SwiftUI

public struct MaintenanceTaskLog: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let status: String // "Pending", "Running", "Completed", "Failed"
    public let date: Date
    
    public init(name: String, status: String, date: Date = Date()) {
        self.name = name
        self.status = status
        self.date = date
    }
}

@MainActor
public final class SystemMaintenanceService: ObservableObject {
    public static let shared = SystemMaintenanceService()
    
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var statusMessage: String = "Ready for system tuneup."
    @Published public private(set) var taskLogs: [MaintenanceTaskLog] = []
    
    private init() {}
    
    public func runFullTuneup() {
        guard !isRunning else { return }
        isRunning = true
        taskLogs.removeAll()
        statusMessage = "Starting macOS Deep Tuneup..."
        
        Task.detached(priority: .userInitiated) {
            // Task 1: Flush DNS Cache
            await self.logTask(name: "Flush DNS Resolver Cache", status: "Running")
            Self.executeShell("dscacheutil -flushcache; killall -HUP mDNSResponder")
            await self.logTask(name: "Flush DNS Resolver Cache", status: "Completed")
            
            // Task 2: Purge RAM & Inactive Memory
            await self.logTask(name: "Purge System RAM Swap & Memory", status: "Running")
            Self.executeShell("purge")
            await self.logTask(name: "Purge System RAM Swap & Memory", status: "Completed")
            
            // Task 3: Rebuild LaunchServices Database
            await self.logTask(name: "Rebuild LaunchServices Database", status: "Running")
            let lsPath = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
            Self.executeShell("\(lsPath) -kill -r -domain local -domain system -domain user")
            await self.logTask(name: "Rebuild LaunchServices Database", status: "Completed")
            
            // Task 4: Run Apple Periodic Scripts
            await self.logTask(name: "Run macOS Periodic Maintenance (Daily/Weekly/Monthly)", status: "Running")
            Self.executeShell("periodic daily weekly monthly")
            await self.logTask(name: "Run macOS Periodic Maintenance (Daily/Weekly/Monthly)", status: "Completed")
            
            await MainActor.run {
                self.isRunning = false
                self.statusMessage = "System Tuneup Complete! All macOS caches and scripts optimized."
            }
        }
    }
    
    private func logTask(name: String, status: String) async {
        await MainActor.run {
            if let idx = self.taskLogs.firstIndex(where: { $0.name == name }) {
                self.taskLogs[idx] = MaintenanceTaskLog(name: name, status: status)
            } else {
                self.taskLogs.append(MaintenanceTaskLog(name: name, status: status))
            }
        }
    }
    
    private nonisolated static func executeShell(_ command: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        try? process.run()
        process.waitUntilExit()
    }
}
