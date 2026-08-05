# Implementation Plan: Settings View Update

## Context
Ghost Monitor has evolved into a fully-fledged Menu Bar agent with extensive "God Mode" utilities (Firewall, Cross-Drop, Spy Catcher, Drop Vault, Battery Limiter). However, `SettingsView.swift` only currently reflects basic monitoring preferences (Refresh Interval, Chart Duration, Menu Bar Text). It needs a major update to expose detailed configurations for all the new powerful tools.

## Proposed Changes to `SettingsView.swift`

### 1. Update Existing "Menu Bar Integration" Section
- Remove the obsolete `Keep Running in Top Status Bar when Main Window is Closed` toggle, as the app is now natively an `LSUIElement` Menu Bar app.
- Keep the `Top Bar Displayed Metrics` (CPU, RAM, SSD, BAT, Temp) since we just restored this functionality to the main menu bar label.

### 2. New Section: Network & Privacy (Firewall & SpyCatcher)
- **Firewall Config**: Add a list/textfield UI to view and edit custom blocked URLs/Domains for the `NetworkFirewallService`.
- **SpyCatcher Database**: Add a button to "Update YARA Threat Database" or run a manual deep scan from settings.

### 3. New Section: God Mode Utilities
- **Drop Vault**: Add a secure field to change the Drop Vault password.
- **Cross-Drop Server**: Add a text field to change the default Port (e.g., from `8080` to custom).
- **Advanced Battery Limiter**: Add a slider or segmented picker to choose the specific charge limit (e.g., 60%, 80%, 90%) instead of a hardcoded 80%.

### 4. Implementation Details
- Update `SettingsService.swift` with the new `@Published` fields (e.g., `crossDropPort`, `batteryLimitPercentage`).
- Update the corresponding Singleton services (like `AdvancedBatteryService.shared.setLimit()`) to observe and respect these new `SettingsService` values.
- Build the UI sections in `SettingsView.swift` using the existing `sectionCard` components for a unified design.

## Sequence
1. Update `SettingsService.swift` with new properties.
2. Update `AdvancedBatteryService` and `CrossDropService` to use these properties.
3. Overhaul `SettingsView.swift` UI.
4. Build and verify.
