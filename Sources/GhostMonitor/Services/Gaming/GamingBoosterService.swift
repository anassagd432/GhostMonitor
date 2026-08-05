import Foundation
import AppKit
import Combine

public struct GameItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String { bundleIdentifier }
    public let name: String
    public let bundleIdentifier: String
    public let executableName: String
    public let isCustom: Bool
    public let path: String?
}

@MainActor
public final class GamingBoosterService: ObservableObject {
    public static let shared = GamingBoosterService()
    
    @Published public private(set) var isBoosted: Bool = false
    @Published public var autoDetectEnabled: Bool = false {
        didSet { setupAutoDetect() }
    }
    @Published public private(set) var customGames: [GameItem] = []
    
    public static let defaultGames: [GameItem] = [
        GameItem(name: "Steam", bundleIdentifier: "com.valvesoftware.steam", executableName: "steam", isCustom: false, path: nil),
        GameItem(name: "Epic Games Launcher", bundleIdentifier: "com.epicgames.EpicGamesLauncher", executableName: "EpicGamesLauncher", isCustom: false, path: nil),
        GameItem(name: "Baldur's Gate 3", bundleIdentifier: "com.larian.bg3", executableName: "bg3", isCustom: false, path: nil),
        GameItem(name: "World of Warcraft", bundleIdentifier: "com.blizzard.worldofwarcraft", executableName: "World of Warcraft", isCustom: false, path: nil),
        GameItem(name: "League of Legends", bundleIdentifier: "com.riotgames.LeagueofLegends.LeagueClient", executableName: "LeagueClient", isCustom: false, path: nil),
        GameItem(name: "Counter-Strike 2", bundleIdentifier: "com.valvesoftware.cs2", executableName: "cs2", isCustom: false, path: nil)
    ]
    
    public var allGames: [GameItem] {
        Self.defaultGames + customGames
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var runningGamePIDs: [pid_t] = []
    
    public init() {
        loadCustomGames()
    }
    
    // MARK: - Boost Actions
    
    public func boost() async {
        guard !isBoosted else { return }
        
        // 1. Identify running games & target PIDs
        let knownIdentifiers = Set(allGames.map { $0.bundleIdentifier.lowercased() })
        let runningApps = NSWorkspace.shared.runningApplications
        
        let gameApps = runningApps.filter { app in
            guard let bundleID = app.bundleIdentifier?.lowercased() else { return false }
            return knownIdentifiers.contains(bundleID)
        }
        runningGamePIDs = gameApps.map { $0.processIdentifier }
        
        // 2. Quit non-essential user GUI apps
        let selfBundleID = Bundle.main.bundleIdentifier?.lowercased()
        let gameBundleIDs = Set(gameApps.compactMap { $0.bundleIdentifier?.lowercased() })
        
        for app in runningApps {
            guard app.activationPolicy == .regular,
                  let bID = app.bundleIdentifier?.lowercased(),
                  bID != "com.apple.finder",
                  bID != selfBundleID,
                  !gameBundleIDs.contains(bID) else { continue }
            
            app.terminate()
        }
        
        // 3. Pause Spotlight
        do {
            try await PrivilegeService.shared.executeAsRoot("mdutil -i off /")
        } catch {
            print("GamingBooster: Failed to pause Spotlight: \(error)")
        }
        
        // 4. Boost game process priority via renice
        for pid in runningGamePIDs {
            do {
                try await PrivilegeService.shared.executeAsRoot("renice -n -20 -p \(pid)")
            } catch {
                print("GamingBooster: Failed to renice PID \(pid): \(error)")
            }
        }
        
        isBoosted = true
    }
    
    public func unboost() async {
        guard isBoosted else { return }
        
        // 1. Restore Spotlight
        do {
            try await PrivilegeService.shared.executeAsRoot("mdutil -i on /")
        } catch {
            print("GamingBooster: Failed to restore Spotlight: \(error)")
        }
        
        runningGamePIDs.removeAll()
        isBoosted = false
    }
    
    // MARK: - Auto Detection & Management
    
    private func setupAutoDetect() {
        cancellables.removeAll()
        guard autoDetectEnabled else { return }
        
        let nc = NSWorkspace.shared.notificationCenter
        
        nc.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .sink { [weak self] app in
                Task { @MainActor in
                    guard let self = self, self.autoDetectEnabled else { return }
                    if let bundleID = app.bundleIdentifier?.lowercased(),
                       self.allGames.contains(where: { $0.bundleIdentifier.lowercased() == bundleID }) {
                        await self.boost()
                    }
                }
            }
            .store(in: &cancellables)
        
        nc.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .sink { [weak self] app in
                Task { @MainActor in
                    guard let self = self, self.autoDetectEnabled, self.isBoosted else { return }
                    let runningApps = NSWorkspace.shared.runningApplications
                    let activeIdentifiers = Set(runningApps.compactMap { $0.bundleIdentifier?.lowercased() })
                    let anyGameRunning = self.allGames.contains { activeIdentifiers.contains($0.bundleIdentifier.lowercased()) }
                    if !anyGameRunning {
                        await self.unboost()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    public func addCustomGame(url: URL) {
        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else { return }
        let name = (bundle.infoDictionary?["CFBundleName"] as? String) ?? url.deletingPathExtension().lastPathComponent
        let execName = (bundle.infoDictionary?["CFBundleExecutable"] as? String) ?? name
        
        let game = GameItem(name: name, bundleIdentifier: bundleID, executableName: execName, isCustom: true, path: url.path)
        if !customGames.contains(where: { $0.bundleIdentifier == bundleID }) {
            customGames.append(game)
            saveCustomGames()
        }
    }
    
    private func saveCustomGames() {
        if let data = try? JSONEncoder().encode(customGames) {
            UserDefaults.standard.set(data, forKey: "GhostMonitor_CustomGames")
        }
    }
    
    private func loadCustomGames() {
        if let data = UserDefaults.standard.data(forKey: "GhostMonitor_CustomGames"),
           let decoded = try? JSONDecoder().decode([GameItem].self, from: data) {
            customGames = decoded
        }
    }
}
