import Foundation
import AppKit
import SwiftUI

public struct MediaTrackInfo: Sendable, Equatable {
    public let title: String
    public let artist: String
    public let album: String
    public let artworkUrl: String?
    public let isPlaying: Bool
    public let sourceApp: String // "Spotify" or "Music"
    
    public init(title: String, artist: String, album: String, artworkUrl: String?, isPlaying: Bool, sourceApp: String) {
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkUrl = artworkUrl
        self.isPlaying = isPlaying
        self.sourceApp = sourceApp
    }
}

@MainActor
public class MediaControllerService: ObservableObject {
    public static let shared = MediaControllerService()
    
    @Published public private(set) var activeTrack: MediaTrackInfo? = nil
    @Published public private(set) var isPlaying: Bool = false
    
    private var updateTimer: Timer?
    
    private init() {
        startPolling()
    }
    
    public func startPolling() {
        fetchNowPlaying()
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchNowPlaying()
            }
        }
    }
    
    public func fetchNowPlaying() {
        let running = NSWorkspace.shared.runningApplications
        let runningNames = Set(running.compactMap { $0.localizedName })
        let runningBundleIDs = Set(running.compactMap { $0.bundleIdentifier?.lowercased() })
        
        let hasSpotify = runningNames.contains("Spotify") || runningBundleIDs.contains("com.spotify.client")
        let hasMusic = runningNames.contains("Music") || runningBundleIDs.contains("com.apple.music")
        
        guard hasSpotify || hasMusic else {
            if activeTrack != nil {
                activeTrack = nil
                isPlaying = false
            }
            return
        }
        
        let targetApp = hasSpotify ? "Spotify" : "Music"
        
        Task.detached(priority: .userInitiated) {
            let script = """
            tell application "\(targetApp)"
                if it is running then
                    set pState to (player state as string)
                    set tName to (name of current track as string)
                    set tArtist to (artist of current track as string)
                    set tAlbum to (album of current track as string)
                    set tArt to ""
                    try
                        set tArt to (artwork url of current track as string)
                    end try
                    return pState & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & tArt
                end if
            end tell
            return ""
            """
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let rawOutput = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            guard !rawOutput.isEmpty else {
                await MainActor.run {
                    self.activeTrack = nil
                    self.isPlaying = false
                }
                return
            }
            
            let parts = rawOutput.components(separatedBy: "|||")
            if parts.count >= 4 {
                let stateStr = parts[0]
                let titleStr = parts[1]
                let artistStr = parts[2]
                let albumStr = parts[3]
                let artUrlStr = parts.count > 4 && !parts[4].isEmpty ? parts[4] : nil
                let playing = stateStr.lowercased().contains("playing")
                
                let track = MediaTrackInfo(
                    title: titleStr,
                    artist: artistStr,
                    album: albumStr,
                    artworkUrl: artUrlStr,
                    isPlaying: playing,
                    sourceApp: targetApp
                )
                
                await MainActor.run {
                    self.activeTrack = track
                    self.isPlaying = playing
                }
            }
        }
    }
    
    public func playPause() {
        guard let source = activeTrack?.sourceApp else { return }
        runCommand("tell application \"\(source)\" to playpause")
        // Immediate local state toggle for instant UX response
        isPlaying.toggle()
    }
    
    public func nextTrack() {
        guard let source = activeTrack?.sourceApp else { return }
        runCommand("tell application \"\(source)\" to next track")
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            fetchNowPlaying()
        }
    }
    
    public func previousTrack() {
        guard let source = activeTrack?.sourceApp else { return }
        runCommand("tell application \"\(source)\" to previous track")
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            fetchNowPlaying()
        }
    }
    
    private func runCommand(_ script: String) {
        Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            try? process.run()
            process.waitUntilExit()
        }
    }
}
