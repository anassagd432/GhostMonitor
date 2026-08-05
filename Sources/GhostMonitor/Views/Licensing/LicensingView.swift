import SwiftUI

public struct LicensingView: View {
    @StateObject private var validator = LicenseValidator.shared
    @State private var licenseKey: String = ""
    @State private var isActivating = false
    @State private var errorMessage: String? = nil
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Badge
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(validator.isAuthorized && validator.currentLicense != nil ? GhostTheme.mint.opacity(0.15) : GhostTheme.purple.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .shadow(color: validator.isAuthorized && validator.currentLicense != nil ? GhostTheme.mint : GhostTheme.purple, radius: 12)
                        
                        Image(systemName: validator.isAuthorized && validator.currentLicense != nil ? "checkmark.seal.fill" : "key.fill")
                            .font(.system(size: 40))
                            .foregroundColor(validator.isAuthorized && validator.currentLicense != nil ? GhostTheme.mint : GhostTheme.purple)
                    }
                    
                    Text(validator.isAuthorized && validator.currentLicense != nil ? "Ghost Monitor Pro Unlocked" : "Activate Pro License")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Secure machine-tied license protected by Secure Enclave hardware binding.")
                        .font(.system(size: 13))
                        .foregroundColor(GhostTheme.textSecondary)
                }
                .padding(.top, 20)
                
                // Hardware Enclave Info Box
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HARDWARE ID (HWID)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        Text(HWIDGenerator.generate())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(HWIDGenerator.generate(), forType: .string)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GhostTheme.cyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(GhostTheme.cyan.opacity(0.12))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .cyberCardStyle()
                
                if let license = validator.currentLicense {
                    // Active Pro License Details
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("LICENSE OWNER")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(GhostTheme.textSecondary)
                                Text(license.email)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            HStack(spacing: 6) {
                                Circle().fill(GhostTheme.mint).frame(width: 8, height: 8)
                                Text("LIFETIME")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(GhostTheme.mint)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(GhostTheme.mint.opacity(0.12))
                            .cornerRadius(8)
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(GhostTheme.cyan)
                            Text("Tamper-Proof License Key Validated")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(GhostTheme.textSecondary)
                            Spacer()
                        }
                    }
                    .padding(20)
                    .cyberCardStyle(glowing: true)
                } else {
                    // Trial & License Key Activation Form
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TRIAL STATUS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(GhostTheme.textSecondary)
                                Text("\(validator.trialDaysRemaining) Days Remaining")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(GhostTheme.cyan)
                            }
                            Spacer()
                            Button(action: {
                                if let url = URL(string: "http://localhost:3000/#pricing") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Text("Buy Pro License")
                                    Image(systemName: "arrow.up.right")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(GhostTheme.cyberGradient)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ENTER LICENSE KEY")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(GhostTheme.textSecondary)
                            
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(GhostTheme.textSecondary)
                                TextField("GHOST-XXXX-XXXX-XXXX", text: $licenseKey)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(GhostTheme.cardBorder, lineWidth: 1)
                            )
                            
                            if let err = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(err)
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(GhostTheme.magenta)
                            }
                            
                            Button(action: activate) {
                                HStack {
                                    if isActivating {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Activate License Key")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(licenseKey.isEmpty ? Color.white.opacity(0.08) : GhostTheme.purple)
                                .foregroundColor(licenseKey.isEmpty ? GhostTheme.textSecondary : .white)
                                .cornerRadius(10)
                                .shadow(color: licenseKey.isEmpty ? Color.clear : GhostTheme.purple.opacity(0.5), radius: 8)
                            }
                            .buttonStyle(.plain)
                            .disabled(licenseKey.isEmpty || isActivating)
                        }
                    }
                    .padding(20)
                    .cyberCardStyle()
                }
                
                Spacer()
            }
            .padding(24)
        }
        .background(GhostTheme.bgDark)
    }
    
    private func activate() {
        isActivating = true
        errorMessage = nil
        
        Task {
            do {
                try await validator.activateLicense(key: licenseKey)
                isActivating = false
            } catch LicenseError.invalidKey {
                errorMessage = "Invalid license key. Please check your purchase."
                isActivating = false
            } catch {
                errorMessage = "Activation failed. Please check your network connection."
                isActivating = false
            }
        }
    }
}
