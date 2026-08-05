import SwiftUI

public struct OverloadProtectorView: View {
    @StateObject private var protector = OverloadProtectorService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 80))
                .foregroundColor(protector.isEnabled ? .green : .secondary)
            
            VStack(spacing: 8) {
                Text("Thermal Guardian")
                    .font(.title.bold())
                
                Text("Automatically detects and kills apps that get stuck or overheat your Mac.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Toggle(isOn: $protector.isEnabled) {
                Text(protector.isEnabled ? "Guardian is Active" : "Guardian is Off")
                    .font(.title3.bold())
                    .foregroundColor(protector.isEnabled ? .green : .primary)
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            
            if protector.isEnabled {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Protection Rules")
                        .font(.headline)
                    
                    VStack(alignment: .leading) {
                        Text("Kill app if CPU usage exceeds: \(Int(protector.cpuThreshold))%")
                        Slider(value: $protector.cpuThreshold, in: 50...100, step: 5)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("For longer than: \(protector.timeThreshold) seconds")
                        Slider(value: Binding(
                            get: { Double(protector.timeThreshold) },
                            set: { protector.timeThreshold = Int($0) }
                        ), in: 5...60, step: 5)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                .transition(.opacity)
            }
            
            if !protector.killHistory.isEmpty {
                VStack(alignment: .leading) {
                    Text("Recent Terminations")
                        .font(.headline)
                        .padding(.top)
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(protector.killHistory) { record in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(record.processName)
                                            .font(.system(.body, design: .monospaced))
                                            .bold()
                                        Text(record.reason)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    Spacer()
                                    Text(record.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
