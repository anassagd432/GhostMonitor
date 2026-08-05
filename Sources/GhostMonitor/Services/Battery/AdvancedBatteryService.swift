import Foundation

@MainActor
public final class AdvancedBatteryService: ObservableObject {
    public static let shared = AdvancedBatteryService()
    
    @Published public private(set) var chargeLimitEnabled = false
    @Published public private(set) var statusMessage: String = ""
    
    public init() {
        checkCurrentState()
    }
    
    /// Reads the current pmset optimizebattery state to sync UI on launch
    private func checkCurrentState() {
        Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            process.arguments = ["-g", "custom"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let isEnabled = output.contains("optimizebattery 1")
            
            await MainActor.run {
                self.chargeLimitEnabled = isEnabled
                self.statusMessage = isEnabled ? "Optimized Battery Charging is active." : ""
            }
        }
    }
    
    public func toggleChargeLimit(_ enable: Bool) async {
        statusMessage = enable ? "Enabling Optimized Battery Charging…" : "Disabling Optimized Battery Charging…"
        
        do {
            // pmset -a optimizebattery 1 = ON (stop ~80% when plugged in long)
            // pmset -a optimizebattery 0 = OFF (always charge to 100%)
            try await PrivilegeService.shared.executeAsRoot(
                "/usr/bin/pmset -a optimizebattery \(enable ? 1 : 0)"
            )
            chargeLimitEnabled = enable
            statusMessage = enable
                ? "✅ Active — Mac will stop charging at ~80% when plugged in long-term."
                : "⏹️ Disabled — Mac will charge to 100% as normal."
        } catch {
            // User cancelled the privilege prompt or it failed
            chargeLimitEnabled = !enable  // revert UI state
            statusMessage = "❌ Failed: \(error.localizedDescription)"
        }
    }
}
