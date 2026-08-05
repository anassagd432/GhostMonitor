import Foundation
import AppKit

@MainActor
public class PrivacyKillswitchService: ObservableObject {
    public static let shared = PrivacyKillswitchService()
    
    @Published public var isMicBlocked = false
    @Published public var isCameraBlocked = false
    @Published public var micStatusMessage = ""
    @Published public var cameraStatusMessage = ""
    
    private init() {}
    
    // MARK: - Microphone
    
    public func toggleMicBlock() {
        if isMicBlocked {
            restoreMic()
        } else {
            blockMic()
        }
    }
    
    private func blockMic() {
        micStatusMessage = "Revoking microphone access…"
        Task.detached {
            do {
                // Reset TCC permissions for Microphone for all apps — requires root
                try await PrivilegeService.shared.executeAsRoot("tccutil reset Microphone")
                await MainActor.run {
                    self.isMicBlocked = true
                    self.micStatusMessage = "✅ Microphone access revoked for all apps. They will re-ask on next use."
                }
            } catch {
                await MainActor.run {
                    self.isMicBlocked = false
                    self.micStatusMessage = "❌ Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func restoreMic() {
        // Restoring mic is simply un-blocking the OS gate.
        // Apps will prompt for permission again when needed — that IS the restore.
        isMicBlocked = false
        micStatusMessage = "Microphone access restored. Apps will request permission on next use."
    }
    
    // MARK: - Camera
    
    public func toggleCameraBlock() {
        if isCameraBlocked {
            restoreCamera()
        } else {
            blockCamera()
        }
    }
    
    private func blockCamera() {
        cameraStatusMessage = "Revoking camera access…"
        Task.detached {
            do {
                // Reset TCC permissions for Camera for all apps — requires root
                try await PrivilegeService.shared.executeAsRoot("tccutil reset Camera")
                await MainActor.run {
                    self.isCameraBlocked = true
                    self.cameraStatusMessage = "✅ Camera access revoked for all apps. They will re-ask on next use."
                }
            } catch {
                await MainActor.run {
                    self.isCameraBlocked = false
                    self.cameraStatusMessage = "❌ Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func restoreCamera() {
        isCameraBlocked = false
        cameraStatusMessage = "Camera access restored. Apps will request permission on next use."
    }
}
