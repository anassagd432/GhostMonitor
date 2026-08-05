import SwiftUI

public struct MouseView: View {
    @StateObject private var service = MouseService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "mouse.fill")
                .font(.system(size: 80))
                .foregroundColor(service.isRawInputEnabled ? .purple : .secondary)
            
            VStack(spacing: 8) {
                Text("Raw Mouse Input")
                    .font(.title2.bold())
                
                Text(service.isRawInputEnabled ? "Acceleration is disabled. You have 1-to-1 movement." : "macOS mouse acceleration is currently active.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Toggle("Raw Input", isOn: Binding(
                get: { service.isRawInputEnabled },
                set: { newValue in service.setRawInput(newValue) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .scaleEffect(1.5)
            
            if service.isRawInputEnabled {
                Text("Note: You may need to unplug and replug your mouse for changes to take effect.")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            service.checkStatus()
        }
    }
}
