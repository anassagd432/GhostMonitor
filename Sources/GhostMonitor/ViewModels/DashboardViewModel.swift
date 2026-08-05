import Foundation
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var coordinator: MonitoringCoordinator
    @Published public var selectedHistoryWindow: HistoryWindow = .fifteenMinutes
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(coordinator: MonitoringCoordinator? = nil) {
        let coord = coordinator ?? MonitoringCoordinator.shared
        self.coordinator = coord
        
        // Forward coordinator objectWillChange so SwiftUI views update in real-time
        coord.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    public var cpuHistoryPoints: [TimeSeriesPoint] {
        filterPoints(coordinator.cpuHistory.values())
    }
    
    public var memoryHistoryPoints: [TimeSeriesPoint] {
        filterPoints(coordinator.memoryHistory.values())
    }
    
    public var networkDlHistoryPoints: [TimeSeriesPoint] {
        filterPoints(coordinator.networkDlHistory.values())
    }
    
    public var networkUlHistoryPoints: [TimeSeriesPoint] {
        filterPoints(coordinator.networkUlHistory.values())
    }
    
    public var diskReadHistoryPoints: [TimeSeriesPoint] {
        filterPoints(coordinator.diskReadHistory.values())
    }
    
    public var diskWriteHistoryPoints: [TimeSeriesPoint] {
        filterPoints(coordinator.diskWriteHistory.values())
    }
    
    private func filterPoints(_ points: [TimeSeriesPoint]) -> [TimeSeriesPoint] {
        let cutoff = Date().addingTimeInterval(-selectedHistoryWindow.rawValue)
        return points.filter { $0.timestamp >= cutoff }
    }
}
