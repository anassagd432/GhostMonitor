import Foundation
import AppKit
import SwiftUI

public struct IntegrationServiceStatus: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let provider: String // "Google", "WhatsApp", "Apple", "Microsoft"
    public var isConnected: Bool
    public var accountDetail: String?
    public let iconName: String
    
    public init(name: String, provider: String, isConnected: Bool, accountDetail: String? = nil, iconName: String) {
        self.name = name
        self.provider = provider
        self.isConnected = isConnected
        self.accountDetail = accountDetail
        self.iconName = iconName
    }
}

@MainActor
public final class IntegrationConnectorsService: ObservableObject {
    public static let shared = IntegrationConnectorsService()
    
    @Published public private(set) var connectors: [IntegrationServiceStatus] = []
    
    private init() {
        refreshStatus()
    }
    
    public func refreshStatus() {
        let google = GoogleOAuthService.shared
        
        connectors = [
            IntegrationServiceStatus(
                name: "Gmail API",
                provider: "Google",
                isConnected: google.isGmailConnected,
                accountDetail: google.connectedUserEmail ?? "Not Authenticated",
                iconName: "envelope.badge.shield.half.filled"
            ),
            IntegrationServiceStatus(
                name: "Google Calendar",
                provider: "Google",
                isConnected: google.isCalendarConnected,
                accountDetail: google.connectedUserEmail ?? "Not Authenticated",
                iconName: "calendar.badge.clock"
            ),
            IntegrationServiceStatus(
                name: "WhatsApp Cloud",
                provider: "Meta",
                isConnected: true,
                accountDetail: "Native URL Scheme Activated",
                iconName: "message.fill"
            ),
            IntegrationServiceStatus(
                name: "Apple Mail & Calendar",
                provider: "Apple Native",
                isConnected: true,
                accountDetail: "macOS System EventKit",
                iconName: "applelogo"
            )
        ]
    }
    
    public func sendWhatsApp(phone: String, text: String) {
        let cleanPhone = phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: "")
        if let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "whatsapp://send?phone=\(cleanPhone)&text=\(encodedText)") {
            NSWorkspace.shared.open(url)
        }
    }
}
