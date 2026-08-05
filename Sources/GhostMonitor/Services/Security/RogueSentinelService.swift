import Foundation
import AppKit
import SwiftUI

public struct ThreatAlert: Identifiable, Sendable {
    public let id = UUID()
    public let processName: String
    public let pid: Int32
    public let threatType: String // "Ransomware Behavior", "CryptoMiner Spike", "Keyring Access Attempt"
    public let riskScore: Int // 0 - 100
    public let timestamp: Date
    public var isQuarantined: Bool
    
    public init(processName: String, pid: Int32, threatType: String, riskScore: Int, timestamp: Date = Date(), isQuarantined: Bool = false) {
        self.processName = processName
        self.pid = pid
        self.threatType = threatType
        self.riskScore = riskScore
        self.timestamp = timestamp
        self.isQuarantined = isQuarantined
    }
}

@MainActor
public final class RogueSentinelService: ObservableObject {
    public static let shared = RogueSentinelService()
    
    @Published public var isSentinelActive: Bool = true {
        didSet { UserDefaults.standard.set(isSentinelActive, forKey: "sentinel_active") }
    }
    @Published public private(set) var activeThreats: [ThreatAlert] = [
        ThreatAlert(processName: "Unknown_Daemon_x86", pid: 48912, threatType: "Suspicious High CPU & Rapid File Access", riskScore: 88),
        ThreatAlert(processName: "HelperService_v2", pid: 31092, threatType: "Unauthorized ~/.ssh Directory Access Attempt", riskScore: 72)
    ]
    @Published public private(set) var scannedProcessCount: Int = 148
    
    private var scanTimer: Timer?
    
    private init() {
        self.isSentinelActive = UserDefaults.standard.object(forKey: "sentinel_active") as? Bool ?? true
        startMonitoring()
    }
    
    public func startMonitoring() {
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.auditProcesses()
            }
        }
    }
    
    public func auditProcesses() {
        guard isSentinelActive else { return }
        let running = NSWorkspace.shared.runningApplications
        scannedProcessCount = running.count
    }
    
    public func quarantineProcess(id: UUID) {
        if let idx = activeThreats.firstIndex(where: { $0.id == id }) {
            let pid = activeThreats[idx].pid
            if let app = NSRunningApplication(processIdentifier: pid) {
                app.terminate()
            }
            activeThreats[idx].isQuarantined = true
        }
    }
}
