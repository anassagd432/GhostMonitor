import Foundation
import AppKit
import SwiftUI

@MainActor
public final class GhostPanicService: ObservableObject {
    public static let shared = GhostPanicService()
    
    @Published public var isEnabled: Bool = true {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "panic_isEnabled") }
    }
    @Published public var lockScreenOnPanic: Bool = true {
        didSet { UserDefaults.standard.set(lockScreenOnPanic, forKey: "panic_lockScreen") }
    }
    @Published public var muteAudioOnPanic: Bool = true {
        didSet { UserDefaults.standard.set(muteAudioOnPanic, forKey: "panic_muteAudio") }
    }
    @Published public var clearClipboardOnPanic: Bool = true {
        didSet { UserDefaults.standard.set(clearClipboardOnPanic, forKey: "panic_clearClipboard") }
    }
    @Published public var blockMicCamOnPanic: Bool = true {
        didSet { UserDefaults.standard.set(blockMicCamOnPanic, forKey: "panic_blockMicCam") }
    }
    @Published public var hideAppsOnPanic: Bool = true {
        didSet { UserDefaults.standard.set(hideAppsOnPanic, forKey: "panic_hideApps") }
    }
    @Published public private(set) var lastPanicTriggered: Date? = nil
    
    private var globalMonitor: Any?
    
    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "panic_isEnabled") as? Bool ?? true
        self.lockScreenOnPanic = UserDefaults.standard.object(forKey: "panic_lockScreen") as? Bool ?? true
        self.muteAudioOnPanic = UserDefaults.standard.object(forKey: "panic_muteAudio") as? Bool ?? true
        self.clearClipboardOnPanic = UserDefaults.standard.object(forKey: "panic_clearClipboard") as? Bool ?? true
        self.blockMicCamOnPanic = UserDefaults.standard.object(forKey: "panic_blockMicCam") as? Bool ?? true
        self.hideAppsOnPanic = UserDefaults.standard.object(forKey: "panic_hideApps") as? Bool ?? true
        
        setupGlobalHotkeyMonitor()
    }
    
    public func setupGlobalHotkeyMonitor() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        
        // Listen for Cmd + Shift + L globally
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isEnabled else { return }
            
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains([.command, .shift]) && event.keyCode == 37 { // 37 = 'L' key
                Task { @MainActor in
                    self.triggerPanicMode()
                }
            }
        }
    }
    
    public func triggerPanicMode() {
        lastPanicTriggered = Date()
        
        // 1. Mute System Audio
        if muteAudioOnPanic {
            runShellCommand("osascript -e 'set volume set volume 0'")
            runShellCommand("osascript -e 'set volume output muted true'")
        }
        
        // 2. Clear Clipboard
        if clearClipboardOnPanic {
            NSPasteboard.general.clearContents()
        }
        
        // 3. Block Mic & Camera Drivers
        if blockMicCamOnPanic {
            Task {
                await PrivacyKillswitchService.shared.toggleMicBlock()
            }
        }
        
        // 4. Hide Non-Essential App Windows
        if hideAppsOnPanic {
            NSWorkspace.shared.hideOtherApplications()
        }
        
        // 5. Instantly Lock Screen
        if lockScreenOnPanic {
            // SACLockScreenImmediate via LoginWindow framework or pmset
            runShellCommand("pmset displaysleepnow")
        }
    }
    
    private nonisolated static func executeShell(_ command: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        try? process.run()
        process.waitUntilExit()
    }
    
    private func runShellCommand(_ command: String) {
        Task.detached(priority: .userInitiated) { [command] in
            Self.executeShell(command)
        }
    }
}
