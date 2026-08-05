import Foundation
import Combine

@MainActor
public final class MonitoringCoordinator: ObservableObject {
    public static let shared = MonitoringCoordinator()
    
    // Published Snapshots for UI initialized with immediate default values
    @Published public private(set) var hardware: HardwareSnapshot? = nil
    @Published public private(set) var cpu: CPUSnapshot? = CPUSnapshot(totalUsagePercentage: 0, pCoreUsagePercentage: 0, eCoreUsagePercentage: 0, perCoreUsages: [], loadAvg1m: 0, loadAvg5m: 0, loadAvg15m: 0)
    @Published public private(set) var memory: MemorySnapshot? = MemorySnapshot(totalBytes: 16 * 1024 * 1024 * 1024, usedBytes: 0, freeBytes: 16 * 1024 * 1024 * 1024, activeBytes: 0, inactiveBytes: 0, wiredBytes: 0, compressedBytes: 0, cachedBytes: 0, swapUsedBytes: 0, pressurePercentage: 0, pressureStatus: .normal)
    @Published public private(set) var gpu: GPUSnapshot? = GPUSnapshot()
    @Published public private(set) var storage: StorageSnapshot? = StorageSnapshot(volumes: [], totalCapacityBytes: 500 * 1024 * 1024 * 1024, totalUsedBytes: 200 * 1024 * 1024 * 1024, totalFreeBytes: 300 * 1024 * 1024 * 1024, aggregateReadSpeed: 0, aggregateWriteSpeed: 0)
    @Published public private(set) var network: NetworkSnapshot? = NetworkSnapshot(primaryInterfaceName: "en0", activeInterfaces: [], totalDownloadSpeed: 0, totalUploadSpeed: 0, totalBytesReceived: 0, totalBytesSent: 0, isConnected: true)
    @Published public private(set) var battery: BatterySnapshot? = BatterySnapshot(isPresent: true, percentage: 100, isCharging: false, powerSource: "AC Power")
    @Published public private(set) var thermal: ThermalSnapshot? = ThermalSnapshot(rawThermalState: 0, thermalStateLabel: "Nominal", isFanless: true, isThrottling: false, statusLevel: .normal)
    @Published public private(set) var processes: [ProcessItem] = []
    
    // System Status
    @Published public private(set) var overallStatus: StatusLevel = .normal
    @Published public private(set) var activeWarnings: [String] = []
    @Published public private(set) var isMonitoringActive: Bool = false
    @Published public private(set) var lastUpdated: Date = Date()
    
    // Window / App Visibility State
    @Published public var isWindowVisible: Bool = true {
        didSet {
            if isWindowVisible != oldValue {
                restartCollectionLoop()
            }
        }
    }
    
    // Ring Buffers (Capacity 3600 = 1 hour at 1s intervals)
    public let cpuHistory = RingBuffer<TimeSeriesPoint>(capacity: 3600)
    public let memoryHistory = RingBuffer<TimeSeriesPoint>(capacity: 3600)
    public let networkDlHistory = RingBuffer<TimeSeriesPoint>(capacity: 3600)
    public let networkUlHistory = RingBuffer<TimeSeriesPoint>(capacity: 3600)
    public let diskReadHistory = RingBuffer<TimeSeriesPoint>(capacity: 3600)
    public let diskWriteHistory = RingBuffer<TimeSeriesPoint>(capacity: 3600)
    public let batteryHistory = RingBuffer<TimeSeriesPoint>(capacity: 3600)
    public let thermalHistory = RingBuffer<TimeSeriesPoint>(capacity: 3600)
    
    // Providers
    private let hardwareProvider = HardwareInfoProvider()
    private let cpuProvider = CPUMetricProvider()
    private let memoryProvider = MemoryMetricProvider()
    private let gpuProvider = GPUMetricProvider()
    private let storageProvider = StorageMetricProvider()
    private let networkProvider = NetworkMetricProvider()
    private let batteryProvider = BatteryMetricProvider()
    private let thermalProvider = ThermalMetricProvider()
    private let processProvider = ProcessMetricProvider()
    
    private var collectionTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var passCount: UInt64 = 0
    
    private init() {
        setupSettingsObserver()
        populateInitialHardware()
    }
    
    private func populateInitialHardware() {
        self.hardware = hardwareProvider.collectSync()
    }
    
    private func setupSettingsObserver() {
        SettingsService.shared.$refreshIntervalSeconds
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.restartCollectionLoop()
            }
            .store(in: &cancellables)
    }
    
    public func startMonitoring() {
        guard !isMonitoringActive else { return }
        isMonitoringActive = true
        
        Task { @MainActor [weak self] in
            if let hw = try? await self?.hardwareProvider.collect() {
                self?.hardware = hw
            }
            await self?.performCollectionPass()
        }
        
        restartCollectionLoop()
    }
    
    public func stopMonitoring() {
        isMonitoringActive = false
        collectionTask?.cancel()
        collectionTask = nil
    }
    
    private func restartCollectionLoop() {
        collectionTask?.cancel()
        
        guard isMonitoringActive else { return }
        
        let effectiveInterval: Double
        if isWindowVisible {
            effectiveInterval = SettingsService.shared.refreshIntervalSeconds
        } else {
            effectiveInterval = max(10.0, SettingsService.shared.refreshIntervalSeconds * 3.0)
        }
        
        collectionTask = Task.detached(priority: .utility) { [weak self] in
            while !Task.isCancelled {
                await self?.performCollectionPass()
                
                do {
                    try await Task.sleep(for: .seconds(effectiveInterval))
                } catch {
                    break
                }
            }
        }
    }
    
    public func performCollectionPass() async {
        passCount += 1
        let currentPass = passCount
        let now = Date()
        let includeLoopback = SettingsService.shared.includeLoopback
        
        let currentCpu = (try? await cpuProvider.collect()) ?? CPUSnapshot(totalUsagePercentage: 0, pCoreUsagePercentage: 0, eCoreUsagePercentage: 0, perCoreUsages: [], loadAvg1m: 0, loadAvg5m: 0, loadAvg15m: 0)
        let currentMem = (try? await memoryProvider.collect()) ?? MemorySnapshot(totalBytes: 16 * 1024 * 1024 * 1024, usedBytes: 0, freeBytes: 16 * 1024 * 1024 * 1024, activeBytes: 0, inactiveBytes: 0, wiredBytes: 0, compressedBytes: 0, cachedBytes: 0, swapUsedBytes: 0, pressurePercentage: 0, pressureStatus: .normal)
        let currentGpu = (try? await gpuProvider.collect()) ?? GPUSnapshot()
        let currentNet = (try? await networkProvider.collect(includeLoopback: includeLoopback)) ?? NetworkSnapshot(primaryInterfaceName: "en0", activeInterfaces: [], totalDownloadSpeed: 0, totalUploadSpeed: 0, totalBytesReceived: 0, totalBytesSent: 0, isConnected: true)
        let currentTherm = (try? await thermalProvider.collect()) ?? ThermalSnapshot(rawThermalState: 0, thermalStateLabel: "Nominal", isFanless: true, isThrottling: false, statusLevel: .normal)
        
        var fetchedStorage: StorageSnapshot? = nil
        var fetchedBat: BatterySnapshot? = nil
        var fetchedProc: [ProcessItem]? = nil
        
        if storage == nil || currentPass % 10 == 0 || currentPass == 1 {
            fetchedStorage = try? await storageProvider.collect()
        }
        
        if battery == nil || currentPass % 10 == 0 || currentPass == 1 {
            fetchedBat = try? await batteryProvider.collect()
        }
        
        if processes.isEmpty || currentPass % 4 == 0 || currentPass == 1 {
            fetchedProc = try? await processProvider.collect()
        }
        
        cpuHistory.append(TimeSeriesPoint(timestamp: now, value: currentCpu.totalUsagePercentage))
        memoryHistory.append(TimeSeriesPoint(timestamp: now, value: currentMem.usedPercentage))
        networkDlHistory.append(TimeSeriesPoint(timestamp: now, value: currentNet.totalDownloadSpeed))
        networkUlHistory.append(TimeSeriesPoint(timestamp: now, value: currentNet.totalUploadSpeed))
        thermalHistory.append(TimeSeriesPoint(timestamp: now, value: Double(currentTherm.rawThermalState)))
        
        if let st = fetchedStorage {
            diskReadHistory.append(TimeSeriesPoint(timestamp: now, value: st.aggregateReadSpeed))
            diskWriteHistory.append(TimeSeriesPoint(timestamp: now, value: st.aggregateWriteSpeed))
        }
        if let bt = fetchedBat {
            batteryHistory.append(TimeSeriesPoint(timestamp: now, value: bt.percentage))
        }
        
        let thresholds = SettingsService.shared.thresholds
        var warnings: [String] = []
        var highestStatus: StatusLevel = .normal
        
        let cpuStatus = thresholds.evaluateCPU(currentCpu.totalUsagePercentage)
        if cpuStatus == .warning || cpuStatus == .critical {
            warnings.append("High CPU usage: \(String(format: "%.1f%%", currentCpu.totalUsagePercentage))")
            if cpuStatus.rawValue > highestStatus.rawValue { highestStatus = cpuStatus }
        }
        
        let memStatus = thresholds.evaluateMemory(currentMem.usedPercentage)
        if memStatus == .warning || memStatus == .critical {
            warnings.append("High Memory pressure: \(String(format: "%.1f%%", currentMem.usedPercentage))")
            if memStatus.rawValue > highestStatus.rawValue { highestStatus = memStatus }
        }
        
        let currentStoragePercentage = fetchedStorage?.primaryUsagePercentage ?? storage?.primaryUsagePercentage ?? 0
        let storageStatus = thresholds.evaluateStorage(currentStoragePercentage)
        if storageStatus == .warning || storageStatus == .critical {
            warnings.append("Low disk space: \(String(format: "%.1f%% used", currentStoragePercentage))")
            if storageStatus.rawValue > highestStatus.rawValue { highestStatus = storageStatus }
        }
        
        if currentTherm.statusLevel == .warning || currentTherm.statusLevel == .critical {
            warnings.append("Thermal throttling active (\(currentTherm.thermalStateLabel))")
            highestStatus = .critical
        }
        
        await MainActor.run {
            self.cpu = currentCpu
            self.memory = currentMem
            self.gpu = currentGpu
            self.network = currentNet
            self.thermal = currentTherm
            
            if let st = fetchedStorage { self.storage = st }
            if let bt = fetchedBat { self.battery = bt }
            if let pr = fetchedProc { self.processes = pr }
            
            self.overallStatus = highestStatus
            self.activeWarnings = warnings
            self.lastUpdated = now
        }
    }
}
