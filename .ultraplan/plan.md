# Implementation Plan: Phase 5 - Unified Control Center

## Context
Redesign the Menu Bar Extra into a sleek, unified "Control Center" popover, replacing the dynamic text label with a single standard icon and adding quick-toggles for all God Mode features.

## Changes

### 1. Menu Bar Icon Redesign
- **File**: `Sources/GhostMonitor/App/GhostMonitorApp.swift`
- **Change**: Replace the dynamic text label (`Text(parts.joined...`) in `MenuBarExtra` with a clean, static icon (`Image(systemName: "bolt.shield.fill")` or similar) to match standard macOS menu bar icons.

### 2. Control Center Popover UI
- **File**: `Sources/GhostMonitor/App/GhostMonitorApp.swift`
- **Change**: Restructure the `MenuBarExtra` content into a grid/list of quick toggles (Control Center style) for:
  - **Insomnia (Anti-Sleep)**: Toggle on/off.
  - **Privacy Killswitch**: Instantly mute mic.
  - **Battery Limiter**: Toggle 80% charge limit.
  - **Raw Mouse Input**: Toggle mouse acceleration.
  - **Network Firewall**: Quick enable/disable.
  - **Cross-Drop**: Quick start server.
- **Reuses**: Existing singleton services (`InsomniaService.shared`, `PrivacyKillswitchService.shared`, etc.)

### 3. Settings Consolidation (Optional Cleanup)
- **File**: `Sources/GhostMonitor/Services/SettingsService.swift`
- **Change**: Remove the settings flags for `showCpuInMenuBar`, `showRamInMenuBar` since the menu bar is now just a single static icon.

## Implementation Sequence
1. Update `GhostMonitorApp.swift` to build the new `ControlCenterMenuBarView`.
2. Replace `MenuBarExtra` label with the simple icon.
3. Wire the new quick-toggles directly to their respective `shared` service publishers.
4. Build and verify.

## Edge Cases & Risks
- **Popover Height limit**: Adding too many toggles might make the popover too tall. **Mitigation**: Use a compact SwiftUI `LazyVGrid` or compact `Toggle` styles.

## Verification
`./build-release.sh && pkill -9 "Ghost Monitor" || true; open "/Applications/Ghost Monitor.app"`
