import SwiftUI

public struct PrivacyView: View {
    @StateObject private var privacy = PrivacyService.shared
    @State private var showSuccess = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.indigo)
                Text("Privacy & Security")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Protect your digital footprint and secure your Mac.")
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 16) {
                    actionCard(
                        title: "Browser History Wipe",
                        subtitle: "Instantly clear history and cookies across Safari, Chrome, and Arc.",
                        icon: "safari.fill",
                        color: .blue,
                        action: { await privacy.wipeBrowsers() }
                    )
                    
                    actionCard(
                        title: "Flush DNS Cache",
                        subtitle: "Prevents forensic tracking of recently visited domains at the OS level.",
                        icon: "network",
                        color: .purple,
                        action: { await privacy.flushDNSCache() }
                    )
                    
                    actionCard(
                        title: "Wipe Recent Documents",
                        subtitle: "Erases the macOS recent files list and shared file list history.",
                        icon: "doc.text.magnifyingglass",
                        color: .orange,
                        action: { await privacy.wipeRecentDocuments() }
                    )
                    
                    actionCard(
                        title: "Secure Empty Trash",
                        subtitle: "Overwrites deleted files multiple times making recovery impossible.",
                        icon: "trash.fill",
                        color: .red,
                        action: { await privacy.secureEmptyTrash() }
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func actionCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await action()
                    showSuccess = true
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    showSuccess = false
                }
            }) {
                if privacy.isWiping {
                    ProgressView().controlSize(.small).frame(width: 80)
                } else if showSuccess {
                    Image(systemName: "checkmark").foregroundColor(.green)
                        .frame(width: 80)
                } else {
                    Text("Execute")
                        .fontWeight(.bold)
                        .frame(width: 80)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(color)
            .disabled(privacy.isWiping)
        }
        .padding(16)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }
}
