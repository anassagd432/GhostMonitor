import SwiftUI

public struct PrivacyKillswitchView: View {
    @StateObject private var service = PrivacyKillswitchService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 24) {
            
            // MARK: - Header
            VStack(spacing: 8) {
                Image(systemName: "hand.raised.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                Text("Privacy Killswitch")
                    .font(.title.bold())
                Text("Instantly revoke hardware access from all apps using macOS system commands.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 30)
            
            // MARK: - Cards
            HStack(spacing: 20) {
                killswitchCard(
                    icon: service.isMicBlocked ? "mic.slash.fill" : "mic.fill",
                    title: "Microphone",
                    status: service.isMicBlocked ? "BLOCKED" : "ACTIVE",
                    statusColor: service.isMicBlocked ? .red : .green,
                    message: service.micStatusMessage,
                    isBlocked: service.isMicBlocked,
                    action: { service.toggleMicBlock() }
                )
                
                killswitchCard(
                    icon: service.isCameraBlocked ? "video.slash.fill" : "video.fill",
                    title: "Camera",
                    status: service.isCameraBlocked ? "BLOCKED" : "ACTIVE",
                    statusColor: service.isCameraBlocked ? .red : .green,
                    message: service.cameraStatusMessage,
                    isBlocked: service.isCameraBlocked,
                    action: { service.toggleCameraBlock() }
                )
            }
            .padding(.horizontal, 30)
            
            // MARK: - Info Banner
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.cyan)
                Text("Uses macOS tccutil to revoke TCC permissions — works on all apps including Zoom, FaceTime, and Chrome. Apps will prompt for access again when they next need the hardware.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Color.cyan.opacity(0.08))
            .cornerRadius(12)
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func killswitchCard(
        icon: String,
        title: String,
        status: String,
        statusColor: Color,
        message: String,
        isBlocked: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundColor(statusColor)
                .animation(.easeInOut, value: isBlocked)
            
            Text(title)
                .font(.title3.bold())
            
            Text(status)
                .font(.caption.bold())
                .foregroundColor(statusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.12))
                .clipShape(Capsule())
            
            Button(action: action) {
                Text(isBlocked ? "Restore \(title)" : "Block \(title)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(isBlocked ? .gray : .red)
            
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(message.hasPrefix("❌") ? .red : .secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
                    .animation(.easeInOut, value: message)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(Color.secondary.opacity(0.07))
        .cornerRadius(20)
    }
}
