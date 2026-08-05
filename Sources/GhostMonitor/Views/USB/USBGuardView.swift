import SwiftUI

public struct USBGuardView: View {
    @StateObject private var service = USBGuardService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("USB Device Guard")
                        .font(.title2.bold())
                    Text("Monitor and control USB devices connecting to your Mac.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Toggle(isOn: $service.isGuardActive) {
                    Label(service.isGuardActive ? "Guard Active" : "Guard Off", systemImage: "shield.fill")
                        .foregroundColor(service.isGuardActive ? .green : .secondary)
                        .font(.subheadline.bold())
                }
                .toggleStyle(.switch)
                .tint(.green)
            }
            .padding(20)
            
            Divider()
            
            // MARK: - Alert Banner
            if !service.alertHistory.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("\(service.alertHistory.count) unrecognised device(s) connected this session.")
                        .font(.subheadline.bold())
                    Spacer()
                    Button("Clear") { service.clearAlertHistory() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            
            // MARK: - Device List
            if service.connectedDevices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cable.connector")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No USB devices detected.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                List(service.connectedDevices) { device in
                    HStack(spacing: 14) {
                        Image(systemName: deviceIcon(for: device.deviceClass))
                            .font(.system(size: 24))
                            .foregroundColor(device.isTrusted ? .green : .orange)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(device.name)
                                    .font(.system(size: 13, weight: .semibold))
                                if !device.isTrusted {
                                    Text("UNKNOWN")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .foregroundColor(.orange)
                                        .clipShape(Capsule())
                                }
                            }
                            HStack(spacing: 12) {
                                Label(device.deviceClass, systemImage: "tag")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Label("\(device.vendorID):\(device.productID)", systemImage: "number")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("Connected \(device.connectedAt.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !device.isTrusted {
                            Button("Trust") { service.trustDevice(device) }
                                .buttonStyle(.bordered)
                                .tint(.green)
                                .controlSize(.small)
                        } else {
                            Label("Trusted", systemImage: "checkmark.shield.fill")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listStyle(.inset)
            }
            
            // MARK: - Info
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("Guard uses IOKit to monitor USB connections in real time. Unknown devices trigger a system notification.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deviceIcon(for deviceClass: String) -> String {
        switch deviceClass {
        case "Storage":          return "externaldrive.fill"
        case "HID / Input Device": return "keyboard.fill"
        case "Hub":              return "point.3.connected.trianglepath.dotted"
        case "Network":          return "network"
        case "Video":            return "camera.fill"
        case "Wireless":         return "wifi"
        default:                 return "cable.connector"
        }
    }
}
