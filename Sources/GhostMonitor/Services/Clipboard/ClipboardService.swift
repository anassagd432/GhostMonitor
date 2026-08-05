import Foundation
import AppKit
import Combine

public enum SensitiveDataType: String, Sendable {
    case password  = "Password"
    case apiKey    = "API Key"
    case creditCard = "Credit Card"
    case privateKey = "Private Key"
    
    var icon: String {
        switch self {
        case .password:   return "key.fill"
        case .apiKey:     return "terminal.fill"
        case .creditCard: return "creditcard.fill"
        case .privateKey: return "lock.fill"
        }
    }
    var color: String { "red" }
}

public struct ClipboardItem: Identifiable, Equatable {
    public let id = UUID()
    public let content: String
    public let timestamp: Date
    public var sensitiveType: SensitiveDataType? = nil
    public var expiresAt: Date? = nil
}

@MainActor
public class ClipboardService: ObservableObject {
    public static let shared = ClipboardService()
    
    @Published public var history: [ClipboardItem] = []
    @Published public var autoWipeEnabled: Bool = true
    @Published public var wipeAfterSeconds: Int = 60
    
    private var pollTimer: Timer?
    private var wipeTimer: Timer?
    private var lastChangeCount: Int = 0
    private let maxItems = 50
    
    private init() {
        startListening()
        startWipeTimer()
    }
    
    // MARK: - Listening
    
    public func startListening() {
        lastChangeCount = NSPasteboard.general.changeCount
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkForChanges() }
        }
    }
    
    public func stopListening() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
    
    private func checkForChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        if let newString = NSPasteboard.general.string(forType: .string) {
            let trimmed = newString.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { addSnippet(trimmed) }
        }
    }
    
    private func addSnippet(_ text: String) {
        if let first = history.first, first.content == text { return }
        
        let sensitive = detectSensitiveData(in: text)
        let expiry: Date? = (autoWipeEnabled && sensitive != nil) ? Date().addingTimeInterval(Double(wipeAfterSeconds)) : nil
        
        var item = ClipboardItem(content: text, timestamp: Date())
        item.sensitiveType = sensitive
        item.expiresAt = expiry
        
        history.insert(item, at: 0)
        if history.count > maxItems { history.removeLast() }
    }
    
    // MARK: - Sensitive Detection
    
    private func detectSensitiveData(in text: String) -> SensitiveDataType? {
        // Private key
        if text.contains("BEGIN RSA PRIVATE KEY") || text.contains("BEGIN EC PRIVATE KEY") || text.contains("BEGIN PRIVATE KEY") {
            return .privateKey
        }
        // API key patterns
        let apiPatterns = ["sk-", "pk_live_", "pk_test_", "Bearer ", "ghp_", "gho_", "AKIA", "eyJhbGci"]
        if apiPatterns.contains(where: { text.hasPrefix($0) || text.contains($0) }) {
            return .apiKey
        }
        // Password pattern: key=value style
        let passwordKeywords = ["password=", "passwd=", "secret=", "token=", "api_key=", "apikey="]
        if passwordKeywords.contains(where: { text.lowercased().contains($0) }) {
            return .password
        }
        // Credit card: 16 digits possibly with spaces/dashes
        let stripped = text.filter { $0.isNumber }
        if stripped.count == 16 && isLuhnValid(stripped) {
            return .creditCard
        }
        return nil
    }
    
    private func isLuhnValid(_ number: String) -> Bool {
        var sum = 0
        let digits = number.reversed().compactMap { $0.wholeNumberValue }
        for (i, digit) in digits.enumerated() {
            if i % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        return sum % 10 == 0
    }
    
    // MARK: - Auto-Wipe Timer
    
    private func startWipeTimer() {
        wipeTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.wipeExpiredItems() }
        }
    }
    
    private func wipeExpiredItems() {
        guard autoWipeEnabled else { return }
        let now = Date()
        let expiredIDs = history.filter { item in
            guard let expiry = item.expiresAt else { return false }
            return now >= expiry
        }.map { $0.id }
        
        guard !expiredIDs.isEmpty else { return }
        
        // If the top item is what's currently in the pasteboard and it's expired — clear it
        if let topExpired = history.first(where: { expiredIDs.contains($0.id) }),
           NSPasteboard.general.string(forType: .string) == topExpired.content {
            NSPasteboard.general.clearContents()
            lastChangeCount = NSPasteboard.general.changeCount
        }
        
        history.removeAll { expiredIDs.contains($0.id) }
    }
    
    // MARK: - Public Actions
    
    public func copyToClipboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        lastChangeCount = pasteboard.changeCount
        
        if let idx = history.firstIndex(where: { $0.id == item.id }) {
            let removed = history.remove(at: idx)
            history.insert(removed, at: 0)
        }
    }
    
    public func clearHistory() {
        history.removeAll()
        NSPasteboard.general.clearContents()
        lastChangeCount = NSPasteboard.general.changeCount
    }
    
    public func deleteItem(_ item: ClipboardItem) {
        history.removeAll { $0.id == item.id }
    }
}
