import Foundation
import AppKit
import SwiftUI

@MainActor
public class DropVaultService: ObservableObject {
    public static let shared = DropVaultService()
    
    private var vaultPanel: NSPanel?
    @Published public var isVaultOpen = false
    @Published public var stashedItems: [URL] = []
    
    private init() {}
    
    public func toggleVault() {
        if isVaultOpen {
            closeVault()
        } else {
            openVault()
        }
    }
    
    private func openVault() {
        if vaultPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 100, y: 100, width: 300, height: 400),
                styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .floating
            panel.isFloatingPanel = true
            panel.title = "Drop Vault"
            panel.hidesOnDeactivate = false
            panel.backgroundColor = .clear
            panel.isOpaque = false
            
            // Allow drag and drop natively or via SwiftUI
            let vaultView = DropVaultOverlayView()
            panel.contentView = NSHostingView(rootView: vaultView)
            
            self.vaultPanel = panel
        }
        
        vaultPanel?.makeKeyAndOrderFront(nil)
        isVaultOpen = true
    }
    
    public func closeVault() {
        vaultPanel?.orderOut(nil)
        isVaultOpen = false
    }
    
    public func addItems(_ urls: [URL]) {
        for url in urls {
            if !stashedItems.contains(url) {
                stashedItems.append(url)
            }
        }
    }
    
    public func removeItem(at index: Int) {
        stashedItems.remove(at: index)
    }
    
    public func clearVault() {
        stashedItems.removeAll()
    }
}
