import Foundation
import AppKit
import Combine

@MainActor
public class InsomniaService: ObservableObject {
    public static let shared = InsomniaService()
    
    public enum InsomniaMode: String, CaseIterable, Identifiable {
        case displayAndIdle = "Display & Idle"
        case displayOnly    = "Display Only"
        case idleOnly       = "Idle Only"
        
        public var id: String { rawValue }
        
        var arguments: [String] {
            switch self {
            case .displayAndIdle: return ["-di"]
            case .displayOnly:    return ["-d"]
            case .idleOnly:       return ["-i"]
            }
        }
        
        var icon: String {
            switch self {
            case .displayAndIdle: return "display.and.arrow.down"
            case .displayOnly:    return "display"
            case .idleOnly:       return "clock.arrow.circlepath"
            }
        }
    }
    
    @Published public var isAwake: Bool = false
    @Published public var mode: InsomniaMode = .displayAndIdle
    @Published public var durationString: String = ""
    
    private var caffeinateProcess: Process?
    private var activeStartTime: Date?
    private var durationTimer: Timer?
    
    private init() {}
    
    public func toggleInsomnia() {
        if isAwake { stopInsomnia() } else { startInsomnia() }
    }
    
    private func startInsomnia() {
        guard caffeinateProcess == nil else { return }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = mode.arguments
        
        do {
            try process.run()
            caffeinateProcess = process
            isAwake = true
            activeStartTime = Date()
            startDurationTimer()
        } catch {
            print("Failed to start Insomnia Mode: \(error)")
            isAwake = false
        }
    }
    
    private func stopInsomnia() {
        caffeinateProcess?.terminate()
        caffeinateProcess = nil
        isAwake = false
        activeStartTime = nil
        durationString = ""
        stopDurationTimer()
    }
    
    private func startDurationTimer() {
        updateDurationString()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateDurationString() }
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    private func updateDurationString() {
        guard let start = activeStartTime else { return }
        let elapsed = Int(Date().timeIntervalSince(start))
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        if hours > 0 {
            durationString = "Active for \(hours)h \(minutes)m"
        } else if minutes > 0 {
            durationString = "Active for \(minutes)m"
        } else {
            durationString = "Active for < 1m"
        }
    }
    
    deinit {
        caffeinateProcess?.terminate()
    }
}
