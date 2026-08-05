import Foundation
import Combine
import AppKit

@MainActor
public final class ProcessListViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var sortField: ProcessSortField = .cpu
    @Published public var isAscending: Bool = false
    @Published public var selectedProcess: ProcessItem? = nil
    
    // Process Termination Confirmation Modal State
    @Published public var processToTerminate: ProcessItem? = nil
    @Published public var isForceQuitConfirmation: Bool = false
    @Published public var showQuitDialog: Bool = false
    
    private let coordinator: MonitoringCoordinator
    
    public init(coordinator: MonitoringCoordinator? = nil) {
        self.coordinator = coordinator ?? MonitoringCoordinator.shared
    }
    
    public var filteredProcesses: [ProcessItem] {
        let showSystem = SettingsService.shared.showSystemProcesses
        var list = coordinator.processes
        
        if !showSystem {
            list = list.filter { !$0.isSystemProcess }
        }
        
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(query) ||
                "\($0.pid)".contains(query) ||
                $0.user.lowercased().contains(query)
            }
        }
        
        list.sort { a, b in
            let result: Bool
            switch sortField {
            case .cpu:
                result = a.cpuUsagePercentage < b.cpuUsagePercentage
            case .memory:
                result = a.memoryBytes < b.memoryBytes
            case .pid:
                result = a.pid < b.pid
            case .name:
                result = a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            return isAscending ? result : !result
        }
        
        return list
    }
    
    public func promptQuit(process: ProcessItem, force: Bool) {
        processToTerminate = process
        isForceQuitConfirmation = force
        showQuitDialog = true
    }
    
    public func confirmQuit() {
        guard let proc = processToTerminate else { return }
        _ = ProcessMetricProvider.terminateProcess(pid: proc.pid, force: isForceQuitConfirmation)
        processToTerminate = nil
        showQuitDialog = false
    }
    
    public func revealInFinder(process: ProcessItem) {
        if let path = process.iconPath, !path.isEmpty {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }
    }
    
    public func copyPID(process: ProcessItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("\(process.pid)", forType: .string)
    }
}
