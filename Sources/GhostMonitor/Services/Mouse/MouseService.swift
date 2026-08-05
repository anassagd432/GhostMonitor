import Foundation
import Combine
import AppKit

@MainActor
public class MouseService: ObservableObject {
    public static let shared = MouseService()
    
    @Published public var isRawInputEnabled: Bool = false
    
    private init() {
        checkStatus()
    }
    
    public func checkStatus() {
        Task {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
            process.arguments = ["read", ".GlobalPreferences", "com.apple.mouse.scaling"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   let scaling = Double(output) {
                    await MainActor.run {
                        self.isRawInputEnabled = scaling < 0
                    }
                }
            } catch {
                print("Failed to read mouse scaling: \(error)")
            }
        }
    }
    
    public func setRawInput(_ enabled: Bool) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        // -1 disables acceleration, 1 is the default
        let scalingValue = enabled ? "-1" : "1"
        process.arguments = ["write", ".GlobalPreferences", "com.apple.mouse.scaling", scalingValue]
        
        do {
            try process.run()
            process.waitUntilExit()
            isRawInputEnabled = enabled
            
            // Note: Restarting the user session or replugging the mouse is usually required for this to take full effect in macOS.
        } catch {
            print("Failed to write mouse scaling: \(error)")
        }
    }
}
