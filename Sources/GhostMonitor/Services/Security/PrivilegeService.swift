import Foundation
import AppKit

public final class PrivilegeService: Sendable {
    public static let shared = PrivilegeService()
    
    private init() {}
    
    /// Checks if a file or directory at the given path requires root access to modify/delete.
    public func requiresRootAccess(at path: String) -> Bool {
        let fileManager = FileManager.default
        return !fileManager.isWritableFile(atPath: path)
    }
    
    /// Safely deletes a list of URLs. If any require root, it groups them and prompts for Administrator privileges via AppleScript.
    public func deletePaths(_ urls: [URL]) async throws {
        var userWritablePaths: [String] = []
        var rootRequiredPaths: [String] = []
        
        for url in urls {
            if requiresRootAccess(at: url.path) {
                rootRequiredPaths.append(url.path)
            } else {
                userWritablePaths.append(url.path)
            }
        }
        
        // 1. Delete user-writable paths directly
        let fileManager = FileManager.default
        for path in userWritablePaths {
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
                print("Failed to remove writable path \(path): \(error)")
            }
        }
        
        // 2. Delete root-required paths via AppleScript Administrator prompt
        if !rootRequiredPaths.isEmpty {
            try await executeRootCommand(commands: rootRequiredPaths.map { "rm -rf \($0.escapedForShell)" })
        }
    }
    
    /// Modifies a launch daemon/agent using standard or privileged launchctl.
    public func toggleLaunchItem(path: String, enable: Bool, requiresRoot: Bool) async throws {
        let command = enable ? "load" : "unload"
        let shellCommand = "/bin/launchctl \(command) -w \(path.escapedForShell)"
        
        if requiresRoot {
            try await executeRootCommand(commands: [shellCommand])
        } else {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", shellCommand]
            try process.run()
            process.waitUntilExit()
        }
    }
    
    /// Executes the purge command to free RAM (Requires root)
    public func freeMemory() async throws {
        try await executeRootCommand(commands: ["/usr/sbin/purge"])
    }
    
    /// Executes a single root command via AppleScript privilege escalation.
    public func executeAsRoot(_ command: String) async throws {
        try await executeRootCommand(commands: [command])
    }
    
    /// Runs a batch of shell commands securely with administrator privileges.
    private func executeRootCommand(commands: [String]) async throws {
        _ = try await executeRootCommandWithOutput(commands: commands)
    }
    
    /// Executes a single root command and returns standard output.
    public func executeAndReturnOutputAsRoot(_ command: String) async throws -> String {
        return try await executeRootCommandWithOutput(commands: [command])
    }
    
    private func executeRootCommandWithOutput(commands: [String]) async throws -> String {
        let fullCommand = commands.joined(separator: " && ")
        // AppleScript requires quotes to be escaped. We will use a safe wrapper.
        // `do shell script "..." with administrator privileges`
        let appleScriptSource = "do shell script \"\(fullCommand.replacingOccurrences(of: "\"", with: "\\\""))\" with administrator privileges"
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: appleScriptSource) {
            let result = script.executeAndReturnError(&error)
            if let error = error {
                throw NSError(domain: "PrivilegeServiceError", code: 1, userInfo: error as? [String: Any])
            }
            return result.stringValue ?? ""
        } else {
            throw NSError(domain: "PrivilegeServiceError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize AppleScript"])
        }
    }
}

extension String {
    /// Safely escapes paths for shell execution to prevent injection
    var escapedForShell: String {
        return "'" + self.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
