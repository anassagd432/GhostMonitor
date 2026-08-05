import SwiftUI

public struct ConnectorsView: View {
    @StateObject private var google = GoogleOAuthService.shared
    @StateObject private var connectors = IntegrationConnectorsService.shared
    
    @State private var waPhone: String = ""
    @State private var waMessage: String = ""
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GhostTheme.cyan.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .shadow(color: GhostTheme.cyan, radius: 12)
                        
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 38))
                            .foregroundColor(GhostTheme.cyan)
                    }
                    
                    Text("API Connectors & Driver Integrations")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Connect Google OAuth 2.0 PKCE (Gmail, Calendar), WhatsApp, and Apple Native services to power JARVIS AI tasks.")
                        .font(.system(size: 13))
                        .foregroundColor(GhostTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                // Google OAuth Connection Hero Card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "g.circle.fill")
                                .foregroundColor(GhostTheme.cyan)
                            Text("GOOGLE OAUTH 2.0 PKCE DRIVER")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(GhostTheme.cyan)
                        }
                        
                        Text(google.isGmailConnected ? "Connected: \(google.connectedUserEmail ?? "Active Account")" : "Not Authenticated")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(google.isGmailConnected ? GhostTheme.mint : GhostTheme.textSecondary)
                    }
                    Spacer()
                    
                    Button(action: {
                        if google.isGmailConnected {
                            google.disconnectServices()
                        } else {
                            google.connectGoogleServices()
                        }
                        connectors.refreshStatus()
                    }) {
                        HStack(spacing: 6) {
                            if google.isAuthenticating {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: google.isGmailConnected ? "xmark.circle.fill" : "link")
                            }
                            Text(google.isGmailConnected ? "Disconnect Account" : "Connect Google Account")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(google.isGmailConnected ? Color.red.opacity(0.8) : GhostTheme.cyan)
                        .foregroundColor(google.isGmailConnected ? .white : .black)
                        .cornerRadius(8)
                        .shadow(color: GhostTheme.cyan.opacity(0.4), radius: 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .cyberCardStyle(glowing: google.isGmailConnected)
                
                // Custom Google Client ID Setting Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("CUSTOM GOOGLE DESKTOP OAUTH CLIENT ID (OPTIONAL)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.textSecondary)
                    
                    TextField("Enter custom Desktop OAuth Client ID (e.g. 123456...apps.googleusercontent.com)", text: $google.googleClientId)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                }
                .padding(16)
                .cyberCardStyle()
                
                // Connected Services Grid
                VStack(alignment: .leading, spacing: 14) {
                    Text("ACTIVE INTEGRATION CONNECTORS (\(connectors.connectors.count))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    VStack(spacing: 10) {
                        ForEach(connectors.connectors) { conn in
                            HStack(spacing: 14) {
                                Image(systemName: conn.iconName)
                                    .font(.system(size: 20))
                                    .foregroundColor(conn.isConnected ? GhostTheme.mint : GhostTheme.textSecondary)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(conn.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Provider: \(conn.provider) • \(conn.accountDetail ?? "")")
                                        .font(.system(size: 10))
                                        .foregroundColor(GhostTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text(conn.isConnected ? "CONNECTED" : "INACTIVE")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(conn.isConnected ? GhostTheme.mint.opacity(0.15) : Color.white.opacity(0.04))
                                    .foregroundColor(conn.isConnected ? GhostTheme.mint : GhostTheme.textSecondary)
                                    .cornerRadius(6)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(20)
                .cyberCardStyle()
                
                // Quick Test WhatsApp Dispatch Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("WHATSAPP DIRECT DEEP LINK DISPATCHER")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    HStack(spacing: 10) {
                        TextField("Phone Number (+14155550199)", text: $waPhone)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                        
                        TextField("Message text...", text: $waMessage)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            connectors.sendWhatsApp(phone: waPhone, text: waMessage)
                        }) {
                            Text("Dispatch")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(GhostTheme.mint)
                                .foregroundColor(.black)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .cyberCardStyle()
            }
            .padding(24)
        }
        .background(GhostTheme.bgDark)
    }
}
