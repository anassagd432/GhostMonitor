import SwiftUI
import AppKit

public struct GamingBoosterView: View {
    @StateObject private var booster = GamingBoosterService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gaming Booster")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Maximize system performance for gaming sessions.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Toggle("Auto-Detect Games", isOn: $booster.autoDetectEnabled)
                    .toggleStyle(.switch)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Hero Boost Button Card
            VStack(spacing: 14) {
                Image(systemName: booster.isBoosted ? "bolt.fill" : "gamecontroller")
                    .font(.system(size: 44))
                    .foregroundColor(booster.isBoosted ? .orange : .cyan)
                
                Text(booster.isBoosted ? "Gaming Boost Active" : "Gaming Booster Idle")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Button(action: {
                    Task {
                        if booster.isBoosted {
                            await booster.unboost()
                        } else {
                            await booster.boost()
                        }
                    }
                }) {
                    Text(booster.isBoosted ? "Restore Normal Mode" : "Boost Now")
                        .fontWeight(.bold)
                        .frame(minWidth: 160, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(booster.isBoosted ? .orange : .cyan)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Game Library Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Tracked Games")
                        .font(.headline)
                    Spacer()
                    Button(action: selectCustomApp) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("Add Custom .app")
                        }
                    }
                }
                
                List {
                    ForEach(booster.allGames) { game in
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(game.name)
                                    .font(.system(size: 13, weight: .medium))
                                Text(game.bundleIdentifier)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(game.isCustom ? "Custom" : "Hardcoded")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 2)
                    }
                }
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func selectCustomApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK, let url = panel.url {
            booster.addCustomGame(url: url)
        }
    }
}
