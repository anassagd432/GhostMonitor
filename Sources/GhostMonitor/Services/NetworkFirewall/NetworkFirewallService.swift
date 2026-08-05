import Foundation
import AppKit
import SwiftUI

@MainActor
public class NetworkFirewallService: ObservableObject {
    public static let shared = NetworkFirewallService()
    
    @Published public var blockedApps: [URL] = []
    @Published public var isLoading = false
    
    private let defaultsKey = "GhostMonitor_BlockedFirewallApps"
    private let fw = "/usr/libexec/ApplicationFirewall/socketfilterfw"
    
    private init() {
        loadPersistedApps()
    }
    
    // MARK: - Persistence
    
    private func loadPersistedApps() {
        isLoading = true
        // Restore saved paths from UserDefaults
        let savedPaths = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        blockedApps = savedPaths.compactMap { URL(fileURLWithPath: $0) }
        
        // Sync with actual macOS ALF state in background
        Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/libexec/ApplicationFirewall/socketfilterfw")
            process.arguments = ["--listapps"]
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            // Parse lines like: "/Applications/Zoom.us.app ( Block incoming connections)"
            let blockedLines = output.components(separatedBy: "\n")
                .filter { $0.contains("Block incoming connections") }
                .compactMap { line -> URL? in
                    let path = line.trimmingCharacters(in: .whitespaces)
                        .components(separatedBy: " (").first?
                        .trimmingCharacters(in: .whitespaces) ?? ""
                    return path.isEmpty ? nil : URL(fileURLWithPath: path)
                }
            
            await MainActor.run {
                // Merge: keep saved + add any found in ALF not already in list
                let existing = Set(self.blockedApps.map { $0.path })
                let newFromALF = blockedLines.filter { !existing.contains($0.path) }
                self.blockedApps.append(contentsOf: newFromALF)
                self.isLoading = false
            }
        }
    }
    
    private func saveToDefaults() {
        let paths = blockedApps.map { $0.path }
        UserDefaults.standard.set(paths, forKey: defaultsKey)
    }
    
    // MARK: - Block / Unblock
    
    public func blockApp(at url: URL) {
        let path = url.path
        Task.detached {
            try? await PrivilegeService.shared.executeAsRoot("\(self.fw) --setglobalstate on")
            try? await PrivilegeService.shared.executeAsRoot("\(self.fw) --add \"\(path)\"")
            try? await PrivilegeService.shared.executeAsRoot("\(self.fw) --blockapp \"\(path)\"")
            
            await MainActor.run {
                if !self.blockedApps.contains(url) {
                    self.blockedApps.append(url)
                    self.saveToDefaults()
                }
            }
        }
    }
    
    public func unblockApp(at url: URL) {
        let path = url.path
        Task.detached {
            try? await PrivilegeService.shared.executeAsRoot("\(self.fw) --unblockapp \"\(path)\"")
            try? await PrivilegeService.shared.executeAsRoot("\(self.fw) --remove \"\(path)\"")
            
            await MainActor.run {
                self.blockedApps.removeAll { $0 == url }
                self.saveToDefaults()
            }
        }
    }
}
