import Foundation
import AppKit
import Combine

public struct LaunchItem: Identifiable, Sendable, Hashable, Equatable {
    public let id: String        // full plist path (unique)
    public let name: String
    public let plistPath: String
    public let executablePath: String
    public let isEnabled: Bool
    public let isUserLevel: Bool // ~/Library vs /Library
    public let isSuspicious: Bool
    public let suspiciousReason: String
}

@MainActor
public class LoginItemsService: ObservableObject {
    public static let shared = LoginItemsService()
    
    @Published public private(set) var items: [LaunchItem] = []
    @Published public private(set) var isScanning = false
    @Published public private(set) var lastScanDate: Date? = nil
    
    private let scanLocations: [(path: String, userLevel: Bool)] = [
        (FileManager.default.homeDirectoryForCurrentUser.path + "/Library/LaunchAgents", true),
        ("/Library/LaunchAgents", false),
        ("/Library/LaunchDaemons", false)
    ]
    
    private init() {}
    
    public func scan() {
        guard !isScanning else { return }
        isScanning = true
        items = []
        let locations = self.scanLocations
        
        Task.detached {
            var found: [LaunchItem] = []
            let fm = FileManager.default
            
            for location in locations {
                guard let contents = try? fm.contentsOfDirectory(atPath: location.path) else { continue }
                
                for filename in contents where filename.hasSuffix(".plist") {
                    let fullPath = "\(location.path)/\(filename)"
                    guard let dict = NSDictionary(contentsOfFile: fullPath) as? [String: Any] else { continue }
                    
                    let name = (dict["Label"] as? String) ?? filename.replacingOccurrences(of: ".plist", with: "")
                    
                    // Extract executable path
                    var execPath = ""
                    if let prog = dict["Program"] as? String {
                        execPath = prog
                    } else if let args = dict["ProgramArguments"] as? [String], let first = args.first {
                        execPath = first
                    }
                    
                    // Check if loaded (enabled)
                    let launchctlOutput = await Self.runLaunchctl("list", label: name)
                    let isEnabled = !launchctlOutput.contains("Could not find service")
                    
                    // Heuristic suspicious check
                    var suspicious = false
                    var reason = ""
                    
                    if !execPath.isEmpty && !fm.fileExists(atPath: execPath) {
                        suspicious = true
                        reason = "Executable not found at: \(execPath)"
                    } else if execPath.contains("/tmp/") || execPath.contains("/var/folders/") {
                        suspicious = true
                        reason = "Runs from a temporary directory"
                    } else if name.range(of: #"^[a-z0-9]{8,}$"#, options: .regularExpression) != nil {
                        suspicious = true
                        reason = "Random-looking launch label"
                    }
                    
                    found.append(LaunchItem(
                        id: fullPath,
                        name: name,
                        plistPath: fullPath,
                        executablePath: execPath,
                        isEnabled: isEnabled,
                        isUserLevel: location.userLevel,
                        isSuspicious: suspicious,
                        suspiciousReason: reason
                    ))
                }
            }
            
            // Sort: suspicious first, then alphabetical
            found.sort {
                if $0.isSuspicious != $1.isSuspicious { return $0.isSuspicious }
                return $0.name.lowercased() < $1.name.lowercased()
            }
            
            let finalFound = found
            await MainActor.run {
                self.items = finalFound
                self.isScanning = false
                self.lastScanDate = Date()
            }
        }
    }
    
    public func disable(_ item: LaunchItem) {
        Task.detached {
            let cmd = item.isUserLevel
                ? "launchctl unload -w \"\(item.plistPath)\""
                : "launchctl unload -w \"\(item.plistPath)\""
            
            if item.isUserLevel {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                process.arguments = ["unload", "-w", item.plistPath]
                try? process.run()
                process.waitUntilExit()
            } else {
                try? await PrivilegeService.shared.executeAsRoot(cmd)
            }
            await MainActor.run { self.scan() }
        }
    }
    
    public func enable(_ item: LaunchItem) {
        Task.detached {
            let cmd = "launchctl load -w \"\(item.plistPath)\""
            if item.isUserLevel {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                process.arguments = ["load", "-w", item.plistPath]
                try? process.run()
                process.waitUntilExit()
            } else {
                try? await PrivilegeService.shared.executeAsRoot(cmd)
            }
            await MainActor.run { self.scan() }
        }
    }
    
    public func revealInFinder(_ item: LaunchItem) {
        NSWorkspace.shared.selectFile(item.plistPath, inFileViewerRootedAtPath: "")
    }
    
    public func deleteItem(_ item: LaunchItem) {
        Task.detached {
            // Unload first
            let unload = "launchctl unload -w \"\(item.plistPath)\""
            if item.isUserLevel {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                process.arguments = ["unload", "-w", item.plistPath]
                try? process.run()
                process.waitUntilExit()
                try? FileManager.default.removeItem(atPath: item.plistPath)
            } else {
                try? await PrivilegeService.shared.executeAsRoot("\(unload) ; rm -f \"\(item.plistPath)\"")
            }
            await MainActor.run { self.scan() }
        }
    }
    
    private static func runLaunchctl(_ command: String, label: String) async -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = [command, label]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try? process.run()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
