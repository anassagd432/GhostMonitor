import Foundation
import AppKit

@MainActor
public final class PrivacyService: ObservableObject {
    public static let shared = PrivacyService()
    
    @Published public private(set) var isWiping = false
    
    public init() {}
    
    public func wipeBrowsers() async {
        isWiping = true
        
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        
        let pathsToWipe = [
            // Safari
            "\(home)/Library/Safari/History.db",
            "\(home)/Library/Safari/History.db-wal",
            "\(home)/Library/Safari/History.db-shm",
            "\(home)/Library/Safari/Downloads.plist",
            // Chrome
            "\(home)/Library/Application Support/Google/Chrome/Default/History",
            "\(home)/Library/Application Support/Google/Chrome/Default/History-journal",
            "\(home)/Library/Application Support/Google/Chrome/Default/Cookies",
            // Arc
            "\(home)/Library/Application Support/Arc/User Data/Default/History"
        ]
        
        for p in pathsToWipe {
            if fm.fileExists(atPath: p) {
                do {
                    try fm.removeItem(atPath: p)
                } catch {
                    print("PrivacyService failed to remove \(p): \(error)")
                }
            }
        }
        
        // Slight delay for UI UX
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isWiping = false
    }
    
    public func flushDNSCache() async {
        isWiping = true
        do {
            try await PrivilegeService.shared.executeAsRoot("dscacheutil -flushcache && killall -HUP mDNSResponder")
        } catch {
            print("PrivacyService failed to flush DNS: \(error)")
        }
        isWiping = false
    }
    
    public func wipeRecentDocuments() async {
        isWiping = true
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["delete", "-g", "NSRecentDocumentsLimit"]
        try? process.run()
        process.waitUntilExit()
        
        let fm = FileManager.default
        let sflPath = "\(fm.homeDirectoryForCurrentUser.path)/Library/Application Support/com.apple.sharedfilelist/"
        if fm.fileExists(atPath: sflPath) {
            try? await PrivilegeService.shared.executeAsRoot("rm -rf \"\(sflPath)\"*")
        }
        
        isWiping = false
    }
    
    public func secureEmptyTrash() async {
        isWiping = true
        do {
            try await PrivilegeService.shared.executeAsRoot("rm -Prf ~/.Trash/*")
        } catch {
            print("PrivacyService failed to secure empty trash: \(error)")
        }
        isWiping = false
    }
}
