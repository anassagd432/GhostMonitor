import Foundation
import Combine

public enum MenuBarMetric: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "All Metrics"
    case cpu = "CPU Usage"
    case memory = "Memory Usage"
    case battery = "Battery Level"
    
    public var id: String { rawValue }
}

public final class SettingsService: ObservableObject, @unchecked Sendable {
    public static let shared = SettingsService()
    
    @Published public var refreshIntervalSeconds: Double {
        didSet { UserDefaults.standard.set(refreshIntervalSeconds, forKey: "refreshIntervalSeconds") }
    }
    
    @Published public var historyWindow: HistoryWindow {
        didSet { UserDefaults.standard.set(historyWindow.rawValue, forKey: "historyWindow") }
    }
    
    @Published public var enableMenuBarExtra: Bool {
        didSet { UserDefaults.standard.set(enableMenuBarExtra, forKey: "enableMenuBarExtra") }
    }
    
    @Published public var crossDropPort: Int {
        didSet { UserDefaults.standard.set(crossDropPort, forKey: "crossDropPort") }
    }
    
    @Published public var batteryLimitPercentage: Int {
        didSet { UserDefaults.standard.set(batteryLimitPercentage, forKey: "batteryLimitPercentage") }
    }
    
    @Published public var showCpuInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showCpuInMenuBar, forKey: "showCpuInMenuBar") }
    }
    
    @Published public var showRamInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showRamInMenuBar, forKey: "showRamInMenuBar") }
    }
    
    @Published public var showSsdInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showSsdInMenuBar, forKey: "showSsdInMenuBar") }
    }
    
    @Published public var showBatteryInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showBatteryInMenuBar, forKey: "showBatteryInMenuBar") }
    }
    
    @Published public var showThermalInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showThermalInMenuBar, forKey: "showThermalInMenuBar") }
    }
    
    @Published public var menuBarMetric: MenuBarMetric {
        didSet { UserDefaults.standard.set(menuBarMetric.rawValue, forKey: "menuBarMetric") }
    }
    
    @Published public var thresholds: MetricThresholds {
        didSet {
            if let data = try? JSONEncoder().encode(thresholds) {
                UserDefaults.standard.set(data, forKey: "metricThresholds")
            }
        }
    }
    
    @Published public var includeLoopback: Bool {
        didSet { UserDefaults.standard.set(includeLoopback, forKey: "includeLoopback") }
    }
    
    @Published public var showSystemProcesses: Bool {
        didSet { UserDefaults.standard.set(showSystemProcesses, forKey: "showSystemProcesses") }
    }
    
    @Published public var reduceMotion: Bool {
        didSet { UserDefaults.standard.set(reduceMotion, forKey: "reduceMotion") }
    }
    
    @Published public var advancedSensorMode: Bool {
        didSet { UserDefaults.standard.set(advancedSensorMode, forKey: "advancedSensorMode") }
    }
    
    @Published public var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    
    private init() {
        let interval = UserDefaults.standard.double(forKey: "refreshIntervalSeconds")
        let validIntervals: Set<Double> = [1.0, 2.0, 5.0, 10.0]
        self.refreshIntervalSeconds = validIntervals.contains(interval) ? interval : 2.0
        
        let windowRaw = UserDefaults.standard.double(forKey: "historyWindow")
        self.historyWindow = HistoryWindow(rawValue: windowRaw) ?? .fifteenMinutes
        
        self.enableMenuBarExtra = UserDefaults.standard.object(forKey: "enableMenuBarExtra") as? Bool ?? true
        
        if UserDefaults.standard.object(forKey: "crossDropPort") == nil {
            self.crossDropPort = 8080
        } else {
            self.crossDropPort = UserDefaults.standard.integer(forKey: "crossDropPort")
        }
        
        if UserDefaults.standard.object(forKey: "batteryLimitPercentage") == nil {
            self.batteryLimitPercentage = 80
        } else {
            self.batteryLimitPercentage = UserDefaults.standard.integer(forKey: "batteryLimitPercentage")
        }
        
        self.showCpuInMenuBar = UserDefaults.standard.object(forKey: "showCpuInMenuBar") as? Bool ?? true
        self.showRamInMenuBar = UserDefaults.standard.object(forKey: "showRamInMenuBar") as? Bool ?? true
        self.showSsdInMenuBar = UserDefaults.standard.object(forKey: "showSsdInMenuBar") as? Bool ?? true
        self.showBatteryInMenuBar = UserDefaults.standard.object(forKey: "showBatteryInMenuBar") as? Bool ?? true
        self.showThermalInMenuBar = UserDefaults.standard.object(forKey: "showThermalInMenuBar") as? Bool ?? true
        
        if let metricRaw = UserDefaults.standard.string(forKey: "menuBarMetric"),
           let metric = MenuBarMetric(rawValue: metricRaw) {
            self.menuBarMetric = metric
        } else {
            self.menuBarMetric = .all
        }
        
        if let data = UserDefaults.standard.data(forKey: "metricThresholds"),
           let decoded = try? JSONDecoder().decode(MetricThresholds.self, from: data) {
            self.thresholds = decoded
        } else {
            self.thresholds = MetricThresholds()
        }
        
        self.includeLoopback = UserDefaults.standard.bool(forKey: "includeLoopback")
        self.showSystemProcesses = UserDefaults.standard.object(forKey: "showSystemProcesses") as? Bool ?? true
        self.reduceMotion = UserDefaults.standard.bool(forKey: "reduceMotion")
        self.advancedSensorMode = UserDefaults.standard.bool(forKey: "advancedSensorMode")
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    }
    
    public func resetToDefaults() {
        refreshIntervalSeconds = 3.0
        historyWindow = .fifteenMinutes
        enableMenuBarExtra = true
        crossDropPort = 8080
        batteryLimitPercentage = 80
        showCpuInMenuBar = true
        showRamInMenuBar = true
        showSsdInMenuBar = true
        showBatteryInMenuBar = true
        showThermalInMenuBar = true
        menuBarMetric = .all
        thresholds = MetricThresholds()
        includeLoopback = false
        showSystemProcesses = true
        reduceMotion = false
        advancedSensorMode = false
        launchAtLogin = false
    }
}
