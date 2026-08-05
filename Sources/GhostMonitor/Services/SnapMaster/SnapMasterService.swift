import Foundation
import AppKit
import ApplicationServices
import Combine

@MainActor
public class SnapMasterService: ObservableObject {
    public static let shared = SnapMasterService()
    
    @Published public var hasAccessibilityPermission: Bool = false
    
    public enum SnapDirection {
        case leftHalf, rightHalf, topHalf, bottomHalf
        case fullScreen, center
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    private init() {
        checkPermission()
    }
    
    public func checkPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    public func promptForPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Polling to detect when user grants it
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if AXIsProcessTrusted() {
                DispatchQueue.main.async {
                    self.hasAccessibilityPermission = true
                }
                timer.invalidate()
            }
        }
    }
    
    public func snapActiveWindow(to direction: SnapDirection) {
        guard hasAccessibilityPermission else {
            promptForPermission()
            return
        }
        
        // Find the frontmost app
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            print("SnapMaster: No active app.")
            return
        }
        
        let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)
        var windowRef: CFTypeRef?
        
        // Get focused window
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef)
        guard result == .success, let window = windowRef else {
            print("SnapMaster: Could not find focused window.")
            return
        }
        
        let axWindow = window as! AXUIElement
        
        // Get the screen the window is currently on
        var windowPosRaw: CFTypeRef?
        var windowSizeRaw: CFTypeRef?
        
        AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &windowPosRaw)
        AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &windowSizeRaw)
        
        var currentPoint: CGPoint = .zero
        var currentSize: CGSize = .zero
        
        if let pRaw = windowPosRaw { AXValueGetValue(pRaw as! AXValue, .cgPoint, &currentPoint) }
        if let sRaw = windowSizeRaw { AXValueGetValue(sRaw as! AXValue, .cgSize, &currentSize) }
        
        // Find the screen containing the center of this window
        let windowCenter = CGPoint(x: currentPoint.x + currentSize.width / 2, y: currentPoint.y + currentSize.height / 2)
        
        guard let screen = NSScreen.screens.first(where: { NSPointInRect(windowCenter, $0.frame) }) ?? NSScreen.main else {
            return
        }
        
        // Visible frame excludes the menu bar and dock
        let screenFrame = screen.visibleFrame
        
        // macOS screen coordinates for Accessibility APIs are flipped (origin is top-left)
        // NSScreen returns coordinates where origin is bottom-left.
        // We must convert NSScreen coordinates to CG global coordinates (top-left).
        let screenHeight = NSScreen.screens.first?.frame.height ?? 0
        let flippedScreenY = screenHeight - screenFrame.maxY
        let axScreenFrame = CGRect(x: screenFrame.minX, y: flippedScreenY, width: screenFrame.width, height: screenFrame.height)
        
        var targetFrame = axScreenFrame
        
        switch direction {
        case .leftHalf:
            targetFrame.size.width /= 2
        case .rightHalf:
            targetFrame.size.width /= 2
            targetFrame.origin.x += targetFrame.size.width
        case .topHalf:
            targetFrame.size.height /= 2
        case .bottomHalf:
            targetFrame.size.height /= 2
            targetFrame.origin.y += targetFrame.size.height
        case .fullScreen:
            break // targetFrame is already axScreenFrame
        case .center:
            targetFrame.size.width = axScreenFrame.width * 0.7
            targetFrame.size.height = axScreenFrame.height * 0.7
            targetFrame.origin.x = axScreenFrame.origin.x + (axScreenFrame.width - targetFrame.size.width) / 2
            targetFrame.origin.y = axScreenFrame.origin.y + (axScreenFrame.height - targetFrame.size.height) / 2
        case .topLeft:
            targetFrame.size.width /= 2
            targetFrame.size.height /= 2
        case .topRight:
            targetFrame.size.width /= 2
            targetFrame.size.height /= 2
            targetFrame.origin.x += targetFrame.size.width
        case .bottomLeft:
            targetFrame.size.width /= 2
            targetFrame.size.height /= 2
            targetFrame.origin.y += targetFrame.size.height
        case .bottomRight:
            targetFrame.size.width /= 2
            targetFrame.size.height /= 2
            targetFrame.origin.x += targetFrame.size.width
            targetFrame.origin.y += targetFrame.size.height
        }
        
        // Apply the new position and size
        var newPoint = targetFrame.origin
        var newSize = targetFrame.size
        
        if let posValue = AXValueCreate(.cgPoint, &newPoint) {
            AXUIElementSetAttributeValue(axWindow, kAXPositionAttribute as CFString, posValue)
        }
        
        if let sizeValue = AXValueCreate(.cgSize, &newSize) {
            AXUIElementSetAttributeValue(axWindow, kAXSizeAttribute as CFString, sizeValue)
        }
    }
}
