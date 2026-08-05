import Foundation
import AppKit
import SwiftUI

@MainActor
public class DisplayManagerService: ObservableObject {
    public static let shared = DisplayManagerService()
    
    @Published public var scale: Double = 0.5 // 0 to 1 representing "Larger Text" to "More Space"
    
    private init() {}
    
    public func setScale(_ value: Double) {
        self.scale = value
        // Note: Real programmatic display scaling on macOS requires private CGS APIs or third-party CLI tools like `displayplacer`.
        // To natively trigger it safely without private APIs, we can open the Displays Preference Pane:
    }
    
    public func openDisplaySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.displays")!
        NSWorkspace.shared.open(url)
    }
    
    public func unlockHiDPI() async throws {
        // This command forces macOS WindowServer to expose hidden HiDPI resolutions for 4K/external monitors
        try await PrivilegeService.shared.executeAsRoot("defaults write /Library/Preferences/com.apple.windowserver.plist DisplayResolutionEnabled -bool true")
    }
}
