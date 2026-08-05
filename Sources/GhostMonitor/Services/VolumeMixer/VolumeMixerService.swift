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
        
        // Only keep controllable apps that are currently running
        var updated: [String: Double] = [:]
        for appName in Self.controllableApps {
            if runningNames.contains(appName) {
                updated[appName] = appVolumes[appName] ?? 1.0  // preserve existing value
            }
        }
        appVolumes = updated
    }
    
    public func setVolume(for appName: String, to volume: Double) {
        appVolumes[appName] = volume
        let volumeInt = Int(volume * 100)
        
        var scriptStr = ""
        switch appName {
        case "Spotify":
            scriptStr = "tell application \"Spotify\" to set sound volume to \(volumeInt)"
        case "Music":
            scriptStr = "tell application \"Music\" to set sound volume to \(volumeInt)"
        default:
            break
        }
        
        guard !scriptStr.isEmpty else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if let script = NSAppleScript(source: scriptStr) {
                var errorInfo: NSDictionary?
                script.executeAndReturnError(&errorInfo)
            }
        }
    }
}
