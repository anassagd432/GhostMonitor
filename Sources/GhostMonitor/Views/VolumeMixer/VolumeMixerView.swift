import SwiftUI

public struct VolumeMixerView: View {
    @StateObject private var mixer = VolumeMixerService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - Header
            VStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                Text("Per-App Volume Mixer")
                    .font(.title.bold())
                Text("Control sound levels for supported media applications.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            
            if mixer.appVolumes.isEmpty {
                // MARK: - Empty State
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No Supported Apps Running")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                    
                    Text("Open Spotify or Apple Music to control their volume from here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    HStack(spacing: 12) {
                        supportedAppBadge(name: "Spotify", icon: "music.note")
                        supportedAppBadge(name: "Apple Music", icon: "music.note")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                // MARK: - Sliders
                VStack(spacing: 0) {
                    ForEach(Array(mixer.appVolumes.keys.sorted()), id: \.self) { appName in
                        HStack(spacing: 16) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text(appName)
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 120, alignment: .leading)
                            
                            let binding = Binding<Double>(
                                get: { mixer.appVolumes[appName] ?? 1.0 },
                                set: { mixer.setVolume(for: appName, to: $0) }
                            )
                            
                            Slider(value: binding, in: 0...1)
                                .tint(.blue)
                            
                            Text("\(Int(binding.wrappedValue * 100))%")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .frame(width: 40, alignment: .trailing)
                                .foregroundColor(binding.wrappedValue == 0 ? .red : .primary)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        
                        if appName != mixer.appVolumes.keys.sorted().last {
                            Divider().padding(.horizontal, 30)
                        }
                    }
                }
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(14)
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            // MARK: - Limitation Note
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("Per-app volume is limited to apps that support AppleScript volume control. Full system-level mixing requires a virtual audio driver like BlackHole.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func supportedAppBadge(name: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(name)
                .font(.caption.bold())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}
