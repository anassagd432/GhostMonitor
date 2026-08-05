import Foundation
import AppKit

public struct NetworkConnection: Identifiable, Sendable {
    public let id: UUID = UUID()
    public let processName: String
    public let pid: Int
    public let localAddress: String
    public let remoteAddress: String
    public let remotePort: Int
    public let proto: String
    public let state: String
    public let isSuspicious: Bool
    
    public static let suspiciousPorts: Set<Int> = [
        4444, 1337, 31337, 6666, 6667, 6668, 6669, // common reverse shells / IRC C2
        9001, 9030,                                   // Tor
        3389,                                         // RDP
        5900, 5901,                                   // VNC
        8888, 8889,                                   // common RAT ports
        2222, 4000                                    // common backdoors
    ]
}

@MainActor
public class LiveConnectionService: ObservableObject {
    public static let shared = LiveConnectionService()
    
    @Published public private(set) var connections: [NetworkConnection] = []
    @Published public private(set) var isMonitoring = false
    @Published public var filterSuspiciousOnly = false
    
    private var pollingTask: Task<Void, Never>?
    
    private init() {}
    
    public var displayedConnections: [NetworkConnection] {
        filterSuspiciousOnly ? connections.filter { $0.isSuspicious } : connections
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        pollingTask = Task.detached(priority: .utility) {
            while !Task.isCancelled {
                await self.fetchConnections()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }
    
    public func stopMonitoring() {
        pollingTask?.cancel()
        pollingTask = nil
        isMonitoring = false
    }
    
    public func killProcess(_ connection: NetworkConnection) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/kill")
        process.arguments = ["-9", "\(connection.pid)"]
        try? process.run()
    }
    
    private func fetchConnections() async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        // -i: network, -n: no DNS, -P: no port names, -F: parseable output
        process.arguments = ["-i", "-n", "-P", "-F", "pcnPTs"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return
        }
        
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let parsed = Self.parse(lsofOutput: output)
        
        await MainActor.run {
            self.connections = parsed
        }
    }
    
    // Parse lsof -F output format
    // Lines start with field identifier: p=pid, c=command, n=name, P=protocol, T=state
    private static func parse(lsofOutput: String) -> [NetworkConnection] {
        var results: [NetworkConnection] = []
        var currentPID = 0
        var currentName = ""
        var currentProto = ""
        var currentState = ""
        
        let lines = lsofOutput.components(separatedBy: "\n")
        var i = 0
        while i < lines.count {
            let line = lines[i]
            guard !line.isEmpty else { i += 1; continue }
            
            let key = String(line.prefix(1))
            let value = String(line.dropFirst())
            
            switch key {
            case "p": currentPID = Int(value) ?? 0
            case "c": currentName = value
            case "P": currentProto = value
            case "T":
                // STATE=ESTABLISHED or ST=ESTABLISHED
                if value.hasPrefix("ST=") { currentState = String(value.dropFirst(3)) }
            case "n":
                // Format: localAddr->remoteAddr or just localAddr
                if value.contains("->") {
                    let parts = value.components(separatedBy: "->")
                    let local = parts[0]
                    let remote = parts.count > 1 ? parts[1] : ""
                    let remotePort = Int(remote.components(separatedBy: ":").last ?? "0") ?? 0
                    
                    let suspicious = NetworkConnection.suspiciousPorts.contains(remotePort)
                    
                    results.append(NetworkConnection(
                        processName: currentName,
                        pid: currentPID,
                        localAddress: local,
                        remoteAddress: remote,
                        remotePort: remotePort,
                        proto: currentProto,
                        state: currentState,
                        isSuspicious: suspicious
                    ))
                    currentState = ""
                }
            default: break
            }
            i += 1
        }
        
        // Deduplicate and sort: suspicious first
        let unique = Array(Dictionary(grouping: results, by: { "\($0.processName)\($0.remoteAddress)\($0.remotePort)" })
            .compactMapValues { $0.first }.values)
        return unique.sorted { $0.isSuspicious && !$1.isSuspicious }
    }
}
