import Foundation
import SwiftUI
import Combine

public struct JarvisCallLog: Identifiable, Sendable {
    public let id = UUID()
    public let contactName: String
    public let phoneNumber: String
    public let duration: String
    public let transcriptSummary: String
    public let status: String // "Completed", "In Progress", "Scheduled"
    public let date: Date
    
    public init(contactName: String, phoneNumber: String, duration: String, transcriptSummary: String, status: String, date: Date = Date()) {
        self.contactName = contactName
        self.phoneNumber = phoneNumber
        self.duration = duration
        self.transcriptSummary = transcriptSummary
        self.status = status
        self.date = date
    }
}

public struct JarvisEmailTask: Identifiable, Sendable {
    public let id = UUID()
    public let recipient: String
    public let subject: String
    public let summary: String
    public let isDispatched: Bool
    
    public init(recipient: String, subject: String, summary: String, isDispatched: Bool = false) {
        self.recipient = recipient
        self.subject = subject
        self.summary = summary
        self.isDispatched = isDispatched
    }
}

@MainActor
public final class JarvisService: ObservableObject {
    public static let shared = JarvisService()
    
    @Published public var isListening: Bool = true
    @Published public var wakeWord: String = "Hey Jarvis"
    @Published public var vapiApiKey: String = "" {
        didSet { UserDefaults.standard.set(vapiApiKey, forKey: "jarvis_vapiApiKey") }
    }
    @Published public var retellApiKey: String = "" {
        didSet { UserDefaults.standard.set(retellApiKey, forKey: "jarvis_retellApiKey") }
    }
    @Published public var phoneNumber: String = "+1 (800) 555-0199" {
        didSet { UserDefaults.standard.set(phoneNumber, forKey: "jarvis_phoneNumber") }
    }
    
    @Published public var callLogs: [JarvisCallLog] = [
        JarvisCallLog(contactName: "Client: Marcus Vance", phoneNumber: "+1 415-555-0142", duration: "2m 14s", transcriptSummary: "Confirmed Q3 strategy meeting for tomorrow at 2:00 PM.", status: "Completed"),
        JarvisCallLog(contactName: "Supplier: Apex Logistics", phoneNumber: "+1 212-555-0188", duration: "1m 45s", transcriptSummary: "Rescheduled hardware delivery to Friday morning.", status: "Completed"),
        JarvisCallLog(contactName: "Lead: Sarah Jenkins", phoneNumber: "+1 650-555-0129", duration: "0m 30s", transcriptSummary: "Outbound call queued for 5:00 PM today.", status: "Scheduled")
    ]
    
    @Published public var pendingEmailTasks: [JarvisEmailTask] = [
        JarvisEmailTask(recipient: "marcus@vancecapital.com", subject: "Follow-up: Q3 Strategy Meeting Confirmation", summary: "Auto-drafted email confirming tomorrow's meeting at 2:00 PM PST."),
        JarvisEmailTask(recipient: "team@ghostmonitor.com", subject: "Weekly Performance Metrics Summary", summary: "Summary of weekly app cleanups and active firewall blocks.")
    ]
    
    private init() {
        self.vapiApiKey = UserDefaults.standard.string(forKey: "jarvis_vapiApiKey") ?? ""
        self.retellApiKey = UserDefaults.standard.string(forKey: "jarvis_retellApiKey") ?? ""
        self.phoneNumber = UserDefaults.standard.string(forKey: "jarvis_phoneNumber") ?? "+1 (800) 555-0199"
    }
    
    public func toggleListening() {
        isListening.toggle()
    }
    
    public func triggerCall(to contact: String, number: String, prompt: String) {
        let newLog = JarvisCallLog(
            contactName: contact,
            phoneNumber: number,
            duration: "In Progress",
            transcriptSummary: "Calling... Prompt: '\(prompt)'",
            status: "In Progress"
        )
        callLogs.insert(newLog, at: 0)
    }
    
    public func dispatchEmail(id: UUID) {
        pendingEmailTasks.removeAll(where: { $0.id == id })
    }
}
