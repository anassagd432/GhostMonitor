import Foundation
import AppKit
import SwiftUI

@MainActor
public class VolumeMixerService: ObservableObject {
    public static let shared = VolumeMixerService()
    
    /// Apps that support volume control via AppleScript
    public static let controllableApps: Set<String> = ["Spotify", "Music"]
    
    @Published public var appVolumes: [String: Double] = [:]
    
    private init() {
        refreshRunningApps()
        
        // Observe app launches/quits to keep list fresh
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshRunningApps() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshRunningApps() }
        }
    }
    
    public func refreshRunningApps() {
        let running = NSWorkspace.shared.runningApplications
        let runningNames = Set(running.compactMap { $0.localizedName })
        let runningBundleIDs = Set(running.compactMap { $0.bundleIdentifier?.lowercased() })
        
        var updated: [String: Double] = [:]
        
        // Check Spotify
        if runningNames.contains("Spotify") || runningBundleIDs.contains("com.spotify.client") {
            let current = appVolumes["Spotify"] ?? 1.0
            updated["Spotify"] = current
            fetchVolume(for: "Spotify")
        }
        
        // Check Apple Music
        if runningNames.contains("Music") || runningBundleIDs.contains("com.apple.music") {
            let current = appVolumes["Music"] ?? 1.0
            updated["Music"] = current
            fetchVolume(for: "Music")
        }
        
        appVolumes = updated
    }
    
    public func fetchVolume(for appName: String) {
        let script: String
        switch appName {
        case "Spotify":
            script = "tell application \"Spotify\" to get sound volume"
        case "Music":
            script = "tell application \"Music\" to get sound volume"
        default:
            return
        }
        
        Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               let volInt = Double(str) {
                await MainActor.run {
                    self.appVolumes[appName] = volInt / 100.0
                }
            }
        }
    }
    
    public func setVolume(for appName: String, to volume: Double) {
        appVolumes[appName] = volume
        let volumeInt = Int(volume * 100)
        
        let scriptStr: String
        switch appName {
        case "Spotify":
            scriptStr = "tell application \"Spotify\" to set sound volume to \(volumeInt)"
        case "Music":
            scriptStr = "tell application \"Music\" to set sound volume to \(volumeInt)"
        default:
            return
        }
        
        Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", scriptStr]
            try? process.run()
            process.waitUntilExit()
        }
    }
}
