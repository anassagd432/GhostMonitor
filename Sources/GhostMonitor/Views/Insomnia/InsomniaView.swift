import SwiftUI

public struct InsomniaView: View {
    @StateObject private var service = InsomniaService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 28) {
            
            // MARK: - Icon + Status
            VStack(spacing: 12) {
                Image(systemName: service.isAwake ? "cup.and.saucer.fill" : "cup.and.saucer")
                    .font(.system(size: 72))
                    .foregroundColor(service.isAwake ? .orange : .secondary)
                    .symbolEffect(.bounce, value: service.isAwake)
                
                Text(service.isAwake ? "Insomnia Mode Active" : "Mac Can Sleep Normally")
                    .font(.title2.bold())
                
                if service.isAwake && !service.durationString.isEmpty {
                    Label(service.durationString, systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 30)
            
            // MARK: - Mode Picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Mode")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Picker("Mode", selection: $service.mode) {
                    ForEach(InsomniaService.InsomniaMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(service.isAwake)
                .opacity(service.isAwake ? 0.5 : 1)
                
                if service.isAwake {
                    Text("Stop Insomnia first to change mode.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Group {
                        switch service.mode {
                        case .displayAndIdle:
                            Text("Prevents both the display and system from sleeping.")
                        case .displayOnly:
                            Text("Keeps the display on. System may still sleep.")
                        case .idleOnly:
                            Text("Prevents idle sleep. Display may turn off.")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            
            // MARK: - Toggle
            Toggle("Insomnia Mode", isOn: Binding(
                get: { service.isAwake },
                set: { _ in service.toggleInsomnia() }
            ))
            .toggleStyle(.switch)
            .tint(.orange)
            .labelsHidden()
            .scaleEffect(1.5)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
