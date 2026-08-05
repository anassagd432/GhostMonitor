import Foundation
import AppKit
import SwiftUI

@MainActor
public class DynamicIslandService: ObservableObject {
    public static let shared = DynamicIslandService()
    
    private var islandPanel: NSPanel?
    @Published public var isIslandVisible = false
    
    private init() {}
    
    public func toggleIsland() {
        if isIslandVisible {
            hideIsland()
        } else {
            showIsland()
        }
    }
    
    public func showIsland() {
        if islandPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.level = .statusBar // Float ABOVE the menu bar
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.ignoresMouseEvents = false
            
            // Position it at the exact top center of the primary screen
            if let screen = NSScreen.screens.first {
                let screenRect = screen.frame
                // Exact horizontal center of the display
                let x = screenRect.midX - (400 / 2)
                
                // Position it at the absolute top pixel of the screen, covering the menu bar
                let y = screenRect.maxY
                panel.setFrameTopLeftPoint(NSPoint(x: x, y: y))
            }
            
            let islandView = GhostControlCenterView()
            panel.contentView = NSHostingView(rootView: islandView)
            
            self.islandPanel = panel
        }
        
        islandPanel?.makeKeyAndOrderFront(nil)
        isIslandVisible = true
    }
    
    public func hideIsland() {
        islandPanel?.orderOut(nil)
        isIslandVisible = false
    }
}
