# Implementation Plan: Phase 4 - The "God Mode" Update

## Context
Add 6 highly advanced system tools to Ghost Monitor to make it the absolute ultimate utility app, including a brand new cross-platform file transfer tool.

## Features & Changes

### 1. Cross-Drop (Windows <-> Mac AirDrop)
- **File**: `Sources/GhostMonitor/Services/CrossDrop/CrossDropService.swift`
- **Change**: A local Wi-Fi file server. We will write a lightweight HTTP server using Swift's `Network` framework that hosts a web page. Windows users just type `http://[Mac-IP]:8080` in their browser to drag-and-drop files directly to the Mac, and download files the Mac has shared.
- **File**: `Sources/GhostMonitor/Views/CrossDrop/CrossDropView.swift`
- **Change**: UI showing the IP address, a QR code for mobile phones, and a list of received files.

### 2. Window Snapper (Rectangle Alternative)
- **File**: `Sources/GhostMonitor/Services/Snapper/WindowSnapperService.swift`
- **Change**: Uses macOS Accessibility API (`AXUIElement`) and `NSEvent.addGlobalMonitorForEvents` to detect keyboard shortcuts (e.g., Control+Option+Arrow Keys) and instantly resize/move the currently focused window to half-screens or fullscreen.
- **File**: `Sources/GhostMonitor/Views/Snapper/SnapperView.swift`
- **Change**: UI to view shortcuts and request Accessibility Permissions.

### 3. The Drop Vault (Floating Dropzone)
- **File**: `Sources/GhostMonitor/Views/DropVault/DropVaultWindowController.swift`
- **Change**: A borderless, floating SwiftUI `NSPanel` that stays on top of all windows. 
- **File**: `Sources/GhostMonitor/Views/DropVault/DropVaultView.swift`
- **Change**: UI that accepts `onDrop` file URLs, holds them in a visual dock, and allows the user to drag them out into other apps (using `NSItemProvider`).

### 4. Privacy Killswitch
- **File**: `Sources/GhostMonitor/Services/Privacy/KillswitchService.swift`
- **Change**: Uses `AudioObjectSetPropertyData` to globally hard-mute the system microphone hardware. Also provides a kill-command to terminate any known video-conferencing or camera-using apps instantly.
- **File**: `Sources/GhostMonitor/Views/Privacy/KillswitchView.swift`
- **Change**: A massive red button UI.

### 5. App Network Firewall (Little Snitch Alternative)
- **File**: `Sources/GhostMonitor/Services/Firewall/FirewallService.swift`
- **Change**: Without requiring complex Apple Network Extension certificates, we will use the native macOS `pf` (Packet Filter) firewall. The service will execute `pfctl` commands as root to block internet access for specific app binaries/ports.

### 6. Per-App Volume Mixer
- **File**: `Sources/GhostMonitor/Services/Audio/VolumeMixerService.swift`
- *(Note: Native macOS does not allow per-app volume without installing a complex Kernel Extension/Audio HAL plug-in like BlackHole. We will build a process-level audio-muter that forcefully pauses background apps making noise, or use AppleScript to tell specific apps to lower their volume).*

## Implementation Sequence
1. Build **Cross-Drop** (Highest wow-factor, high utility).
2. Build **Window Snapper**.
3. Build **Drop Vault**.
4. Build **Privacy Killswitch**.
5. Build **Firewall & Volume Mixer** (Most complex, requires system hooks).

## Edge Cases & Risks
- **Risk**: Window Snapper requires explicit Accessibility permissions. **Mitigation**: Add a prompt in the UI that opens System Settings directly.
- **Risk**: Native Swift HTTP server is tricky. **Mitigation**: We will build a pure `NWListener` TCP socket that handles raw HTTP GET/POST for maximum zero-dependency portability.

## Verification
`pkill -9 "Ghost Monitor" || true; ./build-release.sh && ./open-app.sh`
