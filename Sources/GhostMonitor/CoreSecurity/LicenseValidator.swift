import Foundation
import CryptoKit

public struct LicenseDetails: Codable {
    public let key: String
    public let email: String
    public let expiresAt: Date?
    public let status: String // "active", "expired", "revoked"
}

public enum LicenseError: Error {
    case invalidKey
    case networkError(Error)
    case tamperedResponse
    case trialExpired
    case hardwareMismatch
}

@MainActor
public class LicenseValidator: ObservableObject {
    public static let shared = LicenseValidator()
    
    @Published public private(set) var isAuthorized = false
    @Published public private(set) var currentLicense: LicenseDetails?
    @Published public private(set) var trialDaysRemaining: Int = 14
    
    // In a real app, this would be an API call to Lemon Squeezy / RevenueCat
    // with the HWID appended to verify the license belongs to THIS Mac.
    public func activateLicense(key: String) async throws {
        // Simulated network request...
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        let _ = HWIDGenerator.generate()
        
        // Mock Validation Logic:
        // We simulate that any key starting with "GHOST-" is valid.
        // In production, the server returns a JWT signed with a private key.
        // The app verifies the JWT using a bundled public key.
        
        if key.hasPrefix("GHOST-") {
            let details = LicenseDetails(key: key, email: "user@example.com", expiresAt: nil, status: "active")
            
            // Save the mock JWT/Token to the Keychain enclave securely
            if let data = try? JSONEncoder().encode(details) {
                try? KeychainEnclave.save(key: "GhostMonitor_JWT", data: data)
            }
            
            self.currentLicense = details
            self.isAuthorized = true
        } else {
            throw LicenseError.invalidKey
        }
    }
    
    public func checkTrialOrLicenseOnLaunch() async {
        let _ = HWIDGenerator.generate()
        
        // 1. Check Keychain for an existing valid license
        if let storedData = try? KeychainEnclave.read(key: "GhostMonitor_JWT"),
           let details = try? JSONDecoder().decode(LicenseDetails.self, from: storedData),
           details.status == "active" {
            self.currentLicense = details
            self.isAuthorized = true
            return
        }
        
        // 2. Check Trial State via Server (Mocked)
        // Instead of UserDefaults, we'd ping the API: GET /trial?hwid=\(hwid)
        // If the server says trial started 10 days ago, we set days remaining to 4.
        
        // Mock trial logic
        self.isAuthorized = true // Allow trial access for now
        self.trialDaysRemaining = 14
    }
}
