import Foundation
import Combine

public struct NetworkAppUsage: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let pid: Int
    public let bytesIn: Int64
    public let bytesOut: Int64
    
    public var totalBytes: Int64 {
        bytesIn + bytesOut
    }
}

@MainActor
public final class NetworkService: ObservableObject {
    public static let shared = NetworkService()
    
    @Published public private(set) var activeConnections: [NetworkAppUsage] = []
    @Published public private(set) var isScanning = false
    
    private var timer: Timer?
    
    private init() {}
    
    public func startMonitoring() {
        isScanning = true
        fetchNetworkStats()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchNetworkStats()
            }
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isScanning = false
    }
    
    private func fetchNetworkStats() {
        Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/nettop")
            // -P: parsable, -L 1: run once, -J bytes_in,bytes_out: just those columns
            process.arguments = ["-P", "-L", "1", "-J", "bytes_in,bytes_out"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let parsed = Self.parseNettopOutput(output)
                    Task { @MainActor in
                        self.activeConnections = parsed.sorted(by: { $0.totalBytes > $1.totalBytes })
                    }
                }
            } catch {
                print("NetworkService failed to run nettop: \(error)")
            }
        }
    }
    
    private nonisolated static func parseNettopOutput(_ output: String) -> [NetworkAppUsage] {
        var results: [NetworkAppUsage] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let parts = line.components(separatedBy: ",")
            if parts.count >= 3 {
                let nameAndPid = parts[0]
                if nameAndPid == "time" || nameAndPid.isEmpty { continue }
                
                let nameParts = nameAndPid.components(separatedBy: ".")
                guard nameParts.count >= 2,
                      let pidString = nameParts.last,
                      let pid = Int(pidString) else { continue }
                
                let appName = nameParts.dropLast().joined(separator: ".")
                
                let bIn = Int64(parts[1]) ?? 0
                let bOut = Int64(parts[2]) ?? 0
                
                // Aggregate by PID (nettop can output multiple rows per PID for different interfaces)
                if let existingIndex = results.firstIndex(where: { $0.pid == pid }) {
                    let existing = results[existingIndex]
                    results[existingIndex] = NetworkAppUsage(
                        name: existing.name,
                        pid: existing.pid,
                        bytesIn: existing.bytesIn + bIn,
                        bytesOut: existing.bytesOut + bOut
                    )
                } else {
                    results.append(NetworkAppUsage(name: appName, pid: pid, bytesIn: bIn, bytesOut: bOut))
                }
            }
        }
        
        return results
    }
    
    public func blockApp(pid: Int) async {
        // Without an endpoint security extension or Little Snitch kext,
        // true network blocking requires modifying PF rules as root.
        // For Phase 2, we will kill the process to stop its network activity instantly.
        do {
            try await PrivilegeService.shared.executeAsRoot("kill -9 \(pid)")
            fetchNetworkStats() // refresh
        } catch {
            print("Failed to block app (kill process): \(error)")
        }
    }
}
