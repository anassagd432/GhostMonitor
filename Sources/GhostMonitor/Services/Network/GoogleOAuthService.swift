import Foundation
import AuthenticationServices
import CryptoKit
import SwiftUI

@MainActor
public final class GoogleOAuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    public static let shared = GoogleOAuthService()
    
    @Published public private(set) var isGmailConnected: Bool = false
    @Published public private(set) var isCalendarConnected: Bool = false
    @Published public private(set) var connectedUserEmail: String? = nil
    @Published public private(set) var isAuthenticating: Bool = false
    
    private var accessToken: String?
    private var refreshToken: String?
    private var codeVerifier: String?
    
    // Google OAuth Config (Users can supply Client ID in Settings or use default)
    @Published public var googleClientId: String = "" {
        didSet { UserDefaults.standard.set(googleClientId, forKey: "google_client_id") }
    }
    
    private override init() {
        super.init()
        self.googleClientId = UserDefaults.standard.string(forKey: "google_client_id") ?? ""
        loadSavedTokens()
    }
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first ?? NSWindow()
    }
    
    public func connectGoogleServices() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        
        let verifier = generateCodeVerifier()
        self.codeVerifier = verifier
        let challenge = generateCodeChallenge(from: verifier)
        
        let clientID = googleClientId.isEmpty ? "YOUR_DESKTOP_CLIENT_ID.apps.googleusercontent.com" : googleClientId
        let redirectURI = "ghostmonitor://oauth-callback"
        let scopes = "https://www.googleapis.com/auth/gmail.modify https://www.googleapis.com/auth/calendar.readonly https://www.googleapis.com/auth/userinfo.email"
        
        guard let encodedRedirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedScope = scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let authURL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=\(clientID)&redirect_uri=\(encodedRedirect)&scope=\(encodedScope)&code_challenge=\(challenge)&code_challenge_method=S256") else {
            isAuthenticating = false
            return
        }
        
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "ghostmonitor") { [weak self] callbackURL, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.isAuthenticating = false
                
                if let callbackURL = callbackURL, let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value {
                    self.exchangeCodeForTokens(code: code)
                }
            }
        }
        
        session.presentationContextProvider = self
        session.start()
    }
    
    private func exchangeCodeForTokens(code: String) {
        guard let verifier = codeVerifier else { return }
        let clientID = googleClientId.isEmpty ? "YOUR_DESKTOP_CLIENT_ID.apps.googleusercontent.com" : googleClientId
        
        Task.detached(priority: .userInitiated) {
            let url = URL(string: "https://oauth2.googleapis.com/token")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            let body = "code=\(code)&client_id=\(clientID)&redirect_uri=ghostmonitor://oauth-callback&grant_type=authorization_code&code_verifier=\(verifier)"
            req.httpBody = body.data(using: .utf8)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accToken = json["access_token"] as? String {
                    
                    let refToken = json["refresh_token"] as? String
                    
                    await MainActor.run {
                        self.accessToken = accToken
                        self.refreshToken = refToken
                        self.isGmailConnected = true
                        self.isCalendarConnected = true
                        self.saveTokensToKeychain(accToken: accToken, refToken: refToken)
                        self.fetchUserInfo()
                    }
                }
            } catch {
                print("Failed token exchange: \(error)")
            }
        }
    }
    
    public func fetchUserInfo() {
        guard let token = accessToken else { return }
        Task.detached(priority: .userInitiated) {
            let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
            var req = URLRequest(url: url)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            if let (data, _) = try? await URLSession.shared.data(for: req),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let email = json["email"] as? String {
                await MainActor.run {
                    self.connectedUserEmail = email
                }
            }
        }
    }
    
    public func disconnectServices() {
        accessToken = nil
        refreshToken = nil
        isGmailConnected = false
        isCalendarConnected = false
        connectedUserEmail = nil
        UserDefaults.standard.removeObject(forKey: "google_access_token")
    }
    
    private func saveTokensToKeychain(accToken: String, refToken: String?) {
        UserDefaults.standard.set(accToken, forKey: "google_access_token")
    }
    
    private func loadSavedTokens() {
        if let token = UserDefaults.standard.string(forKey: "google_access_token") {
            self.accessToken = token
            self.isGmailConnected = true
            self.isCalendarConnected = true
            fetchUserInfo()
        }
    }
    
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
