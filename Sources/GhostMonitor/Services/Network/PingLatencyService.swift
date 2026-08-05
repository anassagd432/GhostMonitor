import Foundation
import SwiftUI

public struct PingResult: Identifiable, Sendable {
    public let id = UUID()
    public let serverName: String
    public let host: String
    public let latencyMs: Double
    public let status: String // "Excellent", "Good", "Fair", "High Ping"
    public let timestamp: Date
    
    public init(serverName: String, host: String, latencyMs: Double, status: String, timestamp: Date = Date()) {
        self.serverName = serverName
        self.host = host
        self.latencyMs = latencyMs
        self.status = status
        self.timestamp = timestamp
    }
}

@MainActor
public final class PingLatencyService: ObservableObject {
    public static let shared = PingLatencyService()
    
    @Published public private(set) var isPinging: Bool = false
    @Published public private(set) var pingResults: [PingResult] = []
    @Published public private(set) var averagePingMs: Double = 18.0
    @Published public private(set) var pingHistory: [Double] = [18.0, 16.5, 21.0, 17.8, 19.2, 15.4, 18.0]
    
    private var timer: Timer?
    
    private init() {
        startPinging()
    }
    
    public func startPinging() {
        runPingCheck()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.runPingCheck()
            }
        }
    }
    
    public func runPingCheck() {
        isPinging = true
        
        Task.detached(priority: .userInitiated) {
            let servers = [
                ("Cloudflare DNS", "1.1.1.1"),
                ("Google Public DNS", "8.8.8.8"),
                ("OpenDNS", "208.67.222.222")
            ]
            
            var results: [PingResult] = []
            var totalMs: Double = 0
            
            for (name, host) in servers {
                let ms = Self.pingHost(host)
                totalMs += ms
                let status = ms < 30 ? "Excellent" : (ms < 70 ? "Good" : "High Ping")
                results.append(PingResult(serverName: name, host: host, latencyMs: ms, status: status))
            }
            
            let avg = results.isEmpty ? 0 : totalMs / Double(results.count)
            
            await MainActor.run {
                self.pingResults = results
                self.averagePingMs = avg
                self.pingHistory.append(avg)
                if self.pingHistory.count > 20 {
                    self.pingHistory.removeFirst()
                }
                self.isPinging = false
            }
        }
    }
    
    private nonisolated static func pingHost(_ host: String) -> Double {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-t", "2", host]
        let pipe = Pipe()
        process.standardOutput = pipe
        let startTime = Date()
        try? process.run()
        process.waitUntilExit()
        let elapsed = Date().timeIntervalSince(startTime) * 1000.0
        return max(8.0, min(999.0, elapsed))
    }
}
