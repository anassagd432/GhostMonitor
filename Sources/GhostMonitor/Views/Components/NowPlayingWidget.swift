import SwiftUI

public struct NowPlayingWidget: View {
    @StateObject private var media = MediaControllerService.shared
    @StateObject private var mixer = VolumeMixerService.shared
    
    public init() {}
    
    public var body: some View {
        if let track = media.activeTrack {
            VStack(alignment: .leading, spacing: 10) {
                // Header Badge
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: track.sourceApp == "Spotify" ? "music.note" : "applelogo")
                            .font(.system(size: 10))
                        Text(track.sourceApp.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(track.sourceApp == "Spotify" ? Color(red: 0.11, green: 0.73, blue: 0.33) : Color(red: 0.98, green: 0.14, blue: 0.23))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        (track.sourceApp == "Spotify" ? Color(red: 0.11, green: 0.73, blue: 0.33) : Color(red: 0.98, green: 0.14, blue: 0.23)).opacity(0.12)
                    )
                    .cornerRadius(4)
                    
                    Spacer()
                    
                    if media.isPlaying {
                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(GhostTheme.cyan)
                                    .frame(width: 2, height: CGFloat([8, 14, 10, 16][i]))
                            }
                        }
                    }
                }
                
                // Track Info & Playback Controls Row
                HStack(spacing: 12) {
                    // Album Cover Art Thumbnail
                    ZStack {
                        if let urlStr = track.artworkUrl, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "music.note")
                                    .foregroundColor(GhostTheme.textSecondary)
                            }
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(GhostTheme.textSecondary)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                    .shadow(color: GhostTheme.cyan.opacity(0.2), radius: 4)
                    
                    // Track & Artist Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(track.artist)
                            .font(.system(size: 10))
                            .foregroundColor(GhostTheme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Playback Controls (⏮️ ⏯️ ⏭️)
                    HStack(spacing: 8) {
                        Button(action: { media.previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { media.playPause() }) {
                            Image(systemName: media.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .frame(width: 28, height: 28)
                                .background(GhostTheme.cyan)
                                .clipShape(Circle())
                                .shadow(color: GhostTheme.cyan.opacity(0.5), radius: 6)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { media.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Volume Slider
                let volumeBinding = Binding<Double>(
                    get: { mixer.appVolumes[track.sourceApp] ?? 1.0 },
                    set: { mixer.setVolume(for: track.sourceApp, to: $0) }
                )
                
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 9))
                        .foregroundColor(GhostTheme.textSecondary)
                    
                    Slider(value: volumeBinding, in: 0...1)
                        .controlSize(.mini)
                        .tint(GhostTheme.cyan)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 9))
                        .foregroundColor(GhostTheme.textSecondary)
                }
            }
            .padding(12)
            .cyberCardStyle()
            .onAppear {
                media.fetchNowPlaying()
            }
        }
    }
}
