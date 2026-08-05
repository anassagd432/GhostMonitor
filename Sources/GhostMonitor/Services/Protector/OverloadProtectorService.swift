import Foundation
import Combine
import AppKit
import UserNotifications

@MainActor
public class OverloadProtectorService: ObservableObject {
    public static let shared = OverloadProtectorService()
    
    @Published public var isEnabled: Bool = false
    @Published public var cpuThreshold: Double = 90.0 // Percentage
    @Published public var timeThreshold: Int = 15 // Seconds
    
    @Published public var killHistory: [KillRecord] = []
    
    public struct KillRecord: Identifiable {
        public let id = UUID()
        public let timestamp: Date
        public let processName: String
        public let reason: String
    }
    
    private var processViolations: [Int32: Int] = [:] // PID: Consecutive Seconds
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Observe process updates from MonitoringCoordinator
        MonitoringCoordinator.shared.$processes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] processes in
                self?.checkProcesses(processes)
            }
            .store(in: &cancellables)
    }
    
    private func checkProcesses(_ processes: [ProcessItem]) {
        guard isEnabled else { 
            processViolations.removeAll()
            return 
        }
        
        var currentPIDs = Set<Int32>()
        
        for process in processes {
            // Never kill essential system processes or Ghost Monitor itself
            guard process.pid > 100, 
                  process.name.lowercased() != "ghost monitor", 
                  process.name.lowercased() != "windowserver",
                  process.name.lowercased() != "kernel_task" else {
                continue
            }
            
            currentPIDs.insert(process.pid)
            
            if process.cpuUsagePercentage >= cpuThreshold {
                processViolations[process.pid, default: 0] += 1 // Monitoring tick is usually 1 second
                
                if processViolations[process.pid]! >= timeThreshold {
                    killRogueProcess(process)
                    processViolations[process.pid] = nil
                }
            } else {
                // If it drops below threshold, reset the timer
                processViolations[process.pid] = 0
            }
        }
        
        // Clean up dead processes from the tracking dictionary
        for pid in processViolations.keys {
            if !currentPIDs.contains(pid) {
                processViolations[pid] = nil
            }
        }
    }
    
    private func killRogueProcess(_ process: ProcessItem) {
        print("Protector: Killing rogue process \(process.name) (PID: \(process.pid))")
        
        // Try NSRunningApplication first for a graceful quit
        if let app = NSRunningApplication(processIdentifier: pid_t(process.pid)) {
            app.forceTerminate()
        } else {
            // Force kill with kill command if NSRunningApplication fails
            let task = Process()
            task.launchPath = "/bin/kill"
            task.arguments = ["-9", "\(process.pid)"]
            try? task.run()
        }
        
        let record = KillRecord(
            timestamp: Date(), 
            processName: process.name, 
            reason: "CPU > \(Int(cpuThreshold))% for \(timeThreshold)s"
        )
        
        killHistory.insert(record, at: 0)
        if killHistory.count > 50 {
            killHistory.removeLast()
        }
        
        // Send a notification so the user knows Ghost Monitor saved them
        showNotification(title: "Rogue App Terminated", body: "\(process.name) was using too much CPU and was killed to protect your Mac.")
    }
    
    nonisolated private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .defaultCritical // Distinct sound for protector
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
