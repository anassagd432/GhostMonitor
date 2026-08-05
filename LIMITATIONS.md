# Ghost Monitor - Technical Limitations & GPU/Sensor Policy

## 1. GPU Utilization Policy
Apple Silicon integrated GPUs do not expose public, stable user-space C/Swift APIs for active utilization percentages without relying on private IOKit/IOAccelerator frameworks or elevated entitlements.

To strictly adhere to Apple guidelines and system stability rules:
- Ghost Monitor checks for public Metal and IOKit capabilities.
- When reliable public percentage data is unavailable, Ghost Monitor explicitly displays:
  `"GPU utilization unavailable through public macOS APIs."`
- The application architecture abstracts GPU data behind `GPUMetricProvider`, allowing optional future extensions without modifying dashboard UI components.

## 2. Temperature & Fan Sensor Restrictions
- **Fanless Hardware**: The primary target (MacBook Air M1 2020) has no internal fans. Mechanical fan speeds are disabled and marked as "Fanless Hardware".
- **SMC Temperature Keys**: Individual SoC diode temperatures require internal Apple SMC keys or helper daemons. Ghost Monitor defaults to `ProcessInfo.processInfo.thermalState` (`Nominal`, `Fair`, `Serious`, `Critical`) for safe, unprivileged App Store compliance.
- Battery temperature is retrieved natively from AppleSmartBattery IOKit registry.

## 3. Permissions & System Safeguards
- Ghost Monitor operates entirely as an unprivileged macOS user app.
- Full Disk Access is not required for standard monitoring.
- Root privileges are not required to launch or run the app.
