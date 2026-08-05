import Foundation
import NaturalLanguage
import AppKit

public struct AIAction: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let icon: String
    public let execute: @MainActor @Sendable () async -> Void
}

public struct AIMessage: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let text: String
    public let isUser: Bool
    
    public static func == (lhs: AIMessage, rhs: AIMessage) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
public final class GhostAIService: ObservableObject {
    public static let shared = GhostAIService()
    
    @Published public private(set) var messages: [AIMessage] = [
        AIMessage(text: "Hello. I am Ghost AI. I can optimize your Mac for gaming, secure your privacy, or manage your battery. What do you need?", isUser: false)
    ]
    @Published public private(set) var pendingActions: [AIAction] = []
    @Published public var isProcessing: Bool = false
    
    private init() {}
    
    public func processInput(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // 1. Add user message
        messages.append(AIMessage(text: text, isUser: true))
        pendingActions.removeAll()
        isProcessing = true
        
        // 2. Simulate "thinking" delay for premium feel
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // 3. Analyze intent natively
        let intent = analyzeIntent(text)
        
        // 4. Generate response and actions based on intent
        let (response, actions) = generateResponse(for: intent)
        
        messages.append(AIMessage(text: response, isUser: false))
        pendingActions = actions
        isProcessing = false
    }
    
    private enum Intent {
        case privacy
        case gaming
        case battery
        case sleep
        case unknown
    }
    
    private func analyzeIntent(_ text: String) -> Intent {
        let lower = text.lowercased()
        
        // Basic heuristic keyword matching (fast, native, offline)
        let privacyKeywords = ["privacy", "spy", "mic", "camera", "track", "meeting", "secure"]
        let gamingKeywords = ["game", "play", "lag", "fps", "boost", "slow", "heavy"]
        let batteryKeywords = ["battery", "charge", "power", "limit"]
        let sleepKeywords = ["sleep", "awake", "download", "insomnia"]
        
        if privacyKeywords.contains(where: lower.contains) { return .privacy }
        if gamingKeywords.contains(where: lower.contains) { return .gaming }
        if batteryKeywords.contains(where: lower.contains) { return .battery }
        if sleepKeywords.contains(where: lower.contains) { return .sleep }
        
        return .unknown
    }
    
    private func generateResponse(for intent: Intent) -> (String, [AIAction]) {
        switch intent {
        case .privacy:
            let action = AIAction(title: "Engage Privacy Shield", icon: "shield.fill") {
                await PrivacyKillswitchService.shared.toggleMicBlock()
                // Assuming Firewall service is active, could toggle it too
            }
            return ("I detected a privacy concern. I can instantly block your microphone and secure your network. Shall I engage the Privacy Shield?", [action])
            
        case .gaming:
            let action = AIAction(title: "Boost Performance", icon: "gamecontroller.fill") {
                await GamingBoosterService.shared.boost()
            }
            return ("It sounds like you need maximum performance. I can suspend background apps, pause Spotlight indexing, and boost CPU priority. Ready?", [action])
            
        case .battery:
            let action = AIAction(title: "Enable Battery Limit", icon: "battery.100.bolt") {
                await AdvancedBatteryService.shared.toggleChargeLimit(true)
            }
            return ("I can help preserve your Mac's battery health by preventing it from overcharging past 80%. Would you like me to enable the limit?", [action])
            
        case .sleep:
            let action = AIAction(title: "Activate Insomnia", icon: "cup.and.saucer.fill") {
                InsomniaService.shared.toggleInsomnia()
            }
            return ("Need to keep your Mac awake for a long download or task? I can inject a caffeinate command to prevent sleep.", [action])
            
        case .unknown:
            return ("I'm not quite sure how to help with that yet. Try asking me to optimize your games, secure your privacy, or manage your battery.", [])
        }
    }
}
