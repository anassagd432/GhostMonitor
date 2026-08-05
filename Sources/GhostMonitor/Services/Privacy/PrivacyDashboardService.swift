import Foundation
import AppKit

public enum PermissionType: String, CaseIterable, Sendable {
    case camera = "Camera"
    case microphone = "Microphone"
    case location = "Location"
    case screenRecording = "Screen Recording"
    case accessibility = "Accessibility"
    
    var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .microphone: return "mic.fill"
        case .location: return "location.fill"
        case .screenRecording: return "rectangle.dashed.badge.record"
        case .accessibility: return "figure.arms.open"
        }
    }
    
    var tccServiceString: String {
        switch self {
        case .camera: return "kTCCServiceCamera"
        case .microphone: return "kTCCServiceMicrophone"
        case .location: return "kTCCServiceLocation"
        case .screenRecording: return "kTCCServiceScreenCapture"
        case .accessibility: return "kTCCServiceAccessibility"
        }
    }
}

public struct AppPermission: Identifiable, Sendable {
    public let id = UUID()
    public let bundleID: String
    public let appName: String
    public let permission: PermissionType
    public let isGranted: Bool
}

@MainActor
public class PrivacyDashboardService: ObservableObject {
    public static let shared = PrivacyDashboardService()
    
    @Published public private(set) var permissions: [AppPermission] = []
    @Published public private(set) var isScanning = false
    
    private init() {}
    
    public func scan() {
        guard !isScanning else { return }
        isScanning = true
        permissions = []
        
        Task.detached {
            // We use sqlite3 via PrivilegeService to read the system TCC.db
            // since macOS 14 blocks normal access.
            let dbPath = "/Library/Application Support/com.apple.TCC/TCC.db"
            let query = "SELECT client, service, auth_value FROM access;"
            let cmd = "sqlite3 \"\(dbPath)\" \"\(query)\""
            
            var results: [AppPermission] = []
            
            if let output = try? await PrivilegeService.shared.executeAndReturnOutputAsRoot(cmd) {
                let lines = output.components(separatedBy: "\n")
                
                for line in lines {
                    let parts = line.components(separatedBy: "|")
                    guard parts.count >= 3 else { continue }
                    
                    let client = parts[0]
                    let serviceStr = parts[1]
                    let authValue = parts[2]
                    
                    // Filter out system binaries and apple services to reduce noise
                    if client.hasPrefix("com.apple.") && !client.contains("safari") { continue }
                    if !client.contains(".") { continue } // likely a unix binary like 'sshd'
                    
                    var pType: PermissionType? = nil
                    for t in PermissionType.allCases {
                        if t.tccServiceString == serviceStr {
                            pType = t
                            break
                        }
                    }
                    
                    guard let type = pType else { continue }
                    
                    // auth_value = 2 means granted. (0 is denied, 1 is unknown/prompt)
                    let granted = (authValue == "2")
                    
                    let appName = client.components(separatedBy: ".").last?.capitalized ?? client
                    
                    results.append(AppPermission(
                        bundleID: client,
                        appName: appName,
                        permission: type,
                        isGranted: granted
                    ))
                }
            }
            
            await MainActor.run {
                // Sort by app name
                self.permissions = results.sorted { $0.appName < $1.appName }
                self.isScanning = false
            }
        }
    }
    
    public func revoke(permission: AppPermission) {
        Task.detached {
            // macOS allows you to reset specific TCC permissions via tccutil
            let service: String
            switch permission.permission {
            case .camera: service = "Camera"
            case .microphone: service = "Microphone"
            case .location: service = "Location"
            case .screenRecording: service = "ScreenCapture"
            case .accessibility: service = "Accessibility"
            }
            
            let cmd = "tccutil reset \(service) \(permission.bundleID)"
            try? await PrivilegeService.shared.executeAsRoot(cmd)
            
            await MainActor.run {
                self.scan()
            }
        }
    }
}
