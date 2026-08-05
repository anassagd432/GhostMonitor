import SwiftUI

public struct DynamicIslandMixerView: View {
    @ObservedObject private var mixer = VolumeMixerService.shared
    @State private var isExpanded = false
    @State private var isHovering = false
    
    public var body: some View {
        ZStack {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 25 : 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 0) {
                // Collapsed State (Pill)
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .symbolEffect(.bounce, value: isHovering)
                    
                    if isExpanded {
                        Text("Volume Mixer")
                            .font(.system(size: 14, weight: .semibold))
                            .transition(.opacity.combined(with: .scale))
                        Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isExpanded = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, isExpanded ? 20 : 16)
                .frame(height: 36)
                
                // Expanded State (Content)
                if isExpanded {
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.horizontal, 20)
                        
                        if mixer.appVolumes.isEmpty {
                            Text("No active media apps")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 10)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(mixer.appVolumes.keys.sorted().prefix(5)), id: \.self) { appName in
                                    HStack {
                                        Text(appName)
                                            .font(.system(size: 13, weight: .medium))
                                            .frame(width: 80, alignment: .leading)
                                            .lineLimit(1)
                                        
                                        let binding = Binding<Double>(
                                            get: { mixer.appVolumes[appName] ?? 1.0 },
                                            set: { mixer.setVolume(for: appName, to: $0) }
                                        )
                                        
                                        Slider(value: binding, in: 0...1)
                                            .tint(.blue)
                                        
                                        Text("\(Int(binding.wrappedValue * 100))%")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .frame(width: 35, alignment: .trailing)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(width: isExpanded ? 350 : 60, height: isExpanded ? (mixer.appVolumes.isEmpty ? 100 : CGFloat(36 + 20 + 20 + (mixer.appVolumes.count * 30))) : 36)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isExpanded)
        .onTapGesture {
            if !isExpanded {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isExpanded = true
                }
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
