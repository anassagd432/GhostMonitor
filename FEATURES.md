# Ghost Monitor - Supported Features

## 1. System Overview Header
- Real-time Mac Model identification (`MacBook Air (M1, 2020)`)
- Apple Silicon chip branding (`Apple M1`)
- macOS system version and localized hostname
- System uptime tracker formatted in human-readable time
- Dynamic system health status badge (`Normal`, `Attention`, `Warning`, `Critical`)
- Configurable sampling refresh selector (`1s`, `2s`, `5s`, `10s`)

## 2. All-in-One Dashboard
- **CPU Metrics**: Total usage %, P-core vs E-core load averages, 1m/5m/15m load breakdown
- **Unified Memory**: Real-time breakdown of Wired, Active, Inactive, Compressed, Free, Cached, and Swap usage
- **Storage**: Mounted APFS/physical volumes, total capacity, used/free space, live read & write throughput
- **Network**: Active interfaces (Wi-Fi, Ethernet), local IP, download/upload throughput speeds, total bytes transferred
- **Battery**: Charge percentage, power source (AC vs Battery), power draw in Watts, cycle count, max capacity %, battery condition, estimated time remaining
- **Thermal & Fanless**: `ProcessInfo` thermal pressure state (`Nominal`, `Fair`, `Serious`, `Critical`), throttling warning, "Fanless Mac" passive cooling badge

## 3. Real-Time Swift Charts
- Interactive historical time-series graphs powered by native Apple Swift Charts
- Support for 1-minute, 5-minute, 15-minute, and 1-hour time windows backed by a fixed-capacity in-memory Ring Buffer
- Automatic background throttling when window is hidden or minimized

## 4. Top Process Manager
- Real-time sortable table by CPU %, Memory, PID, or Process Name
- App icon caching and path resolution
- Search filter for filtering processes by name, PID, or user
- Process inspection modal
- Safe termination dialogs for `SIGTERM` and `SIGKILL` with PID protection safeguards

## 5. Quick Access Menu Bar Extra
- Optional macOS menu bar icon showing real-time CPU %, Memory %, or Battery %
- Quick dashboard activation and application control

## 6. Diagnostics Export
- One-click JSON diagnostic report generation saved securely via `NSSavePanel`
