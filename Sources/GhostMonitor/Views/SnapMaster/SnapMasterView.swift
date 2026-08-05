import SwiftUI

public struct SnapMasterView: View {
    @StateObject private var snapper = SnapMasterService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "uiwindow.split.2x1")
                .font(.system(size: 80))
                .foregroundColor(snapper.hasAccessibilityPermission ? .blue : .orange)
            
            VStack(spacing: 8) {
                Text("The Snap-Master")
                    .font(.title.bold())
                
                Text("Instantly organize your windows into halves, quarters, or fullscreen.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !snapper.hasAccessibilityPermission {
                VStack(spacing: 15) {
                    Text("Accessibility Permission Required")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Ghost Monitor needs permission to move other apps' windows on your screen. Click below to grant access in System Settings.")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                    
                    Button("Grant Permission") {
                        snapper.promptForPermission()
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(spacing: 15) {
                    Text("Snapping Controls")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        snapButton(icon: "arrow.up.left.and.arrow.down.right", title: "Top L", direction: .topLeft)
                        snapButton(icon: "arrow.up", title: "Top", direction: .topHalf)
                        snapButton(icon: "arrow.up.right.and.arrow.down.left", title: "Top R", direction: .topRight)
                    }
                    
                    HStack(spacing: 10) {
                        snapButton(icon: "arrow.left", title: "Left", direction: .leftHalf)
                        snapButton(icon: "rectangle.inset.filled", title: "Center", direction: .center)
                        snapButton(icon: "arrow.right", title: "Right", direction: .rightHalf)
                    }
                    
                    HStack(spacing: 10) {
                        snapButton(icon: "arrow.down.left.and.arrow.up.right", title: "Bot L", direction: .bottomLeft)
                        snapButton(icon: "arrow.down", title: "Bottom", direction: .bottomHalf)
                        snapButton(icon: "arrow.down.right.and.arrow.up.left", title: "Bot R", direction: .bottomRight)
                    }
                    
                    Button(action: {
                        snapper.snapActiveWindow(to: .fullScreen)
                    }) {
                        HStack {
                            Image(systemName: "rectangle.fill")
                            Text("Full Screen")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .padding(.top, 10)
                    
                    Text("Tip: Click a button here to snap the app that is currently in front!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func snapButton(icon: String, title: String, direction: SnapMasterService.SnapDirection) -> some View {
        Button(action: {
            snapper.snapActiveWindow(to: direction)
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(width: 60, height: 60)
        }
        .buttonStyle(.bordered)
    }
}
