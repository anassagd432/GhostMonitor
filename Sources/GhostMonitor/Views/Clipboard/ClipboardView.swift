import SwiftUI

public struct ClipboardView: View {
    @StateObject private var service = ClipboardService.shared
    @State private var showToast = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header & Controls
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clipboard Shield")
                        .font(.title2.bold())
                    Text("Securely remembers recent copies and auto-wipes sensitive data.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: { service.clearHistory() }) {
                    Label("Clear Vault", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(20)
            
            // MARK: - Auto-Wipe Settings
            HStack {
                Toggle(isOn: $service.autoWipeEnabled) {
                    Label("Auto-Wipe Sensitive Data", systemImage: "shield.fill")
                        .foregroundColor(service.autoWipeEnabled ? .green : .secondary)
                }
                .toggleStyle(.switch)
                .tint(.green)
                
                Spacer()
                
                if service.autoWipeEnabled {
                    Picker("Wipe after", selection: $service.wipeAfterSeconds) {
                        Text("10 Seconds").tag(10)
                        Text("30 Seconds").tag(30)
                        Text("1 Minute").tag(60)
                        Text("5 Minutes").tag(300)
                    }
                    .frame(width: 150)
                }
            }
            .padding(14)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            Divider()
                .padding(.top, 16)
            
            // MARK: - History List
            if service.history.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Clipboard history is empty.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(service.history) { item in
                        HStack(spacing: 14) {
                            
                            // Sensitive icon
                            if let type = item.sensitiveType {
                                Image(systemName: type.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                            } else {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.content)
                                    .lineLimit(2)
                                    .font(.system(size: 13, design: item.sensitiveType != nil ? .monospaced : .default))
                                    .blur(radius: item.sensitiveType != nil ? 3 : 0)
                                    .onHover { hovering in
                                        // A real implementation would use state to unblur on hover,
                                        // but SwiftUI List rows don't handle local state easily without extracted views.
                                        // For simplicity, we just keep it blurred to protect from shoulder-surfing.
                                    }
                                
                                HStack(spacing: 8) {
                                    Text(item.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    if let type = item.sensitiveType {
                                        Text(type.rawValue.uppercased())
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.15))
                                            .foregroundColor(.red)
                                            .clipShape(Capsule())
                                    }
                                    
                                    if let expiry = item.expiresAt {
                                        Text("Wipes in \(max(0, Int(expiry.timeIntervalSinceNow)))s")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.15))
                                            .foregroundColor(.orange)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                service.copyToClipboard(item: item)
                                showToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showToast = false
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button(action: {
                                service.deleteItem(item)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(item.sensitiveType != nil ? Color.red.opacity(0.04) : Color.clear)
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            VStack {
                Spacer()
                if showToast {
                    Text("Copied to Clipboard!")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.9))
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(), value: showToast)
        )
    }
}
