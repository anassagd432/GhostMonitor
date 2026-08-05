import Foundation
import AppKit

public struct AppInstall: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let name: String
    public let path: URL
    public let bundleIdentifier: String
    public let appSizeBytes: Int64
    public let relatedFilesBytes: Int64
    public let icon: NSImage?
    
    public var totalSizeBytes: Int64 {
        appSizeBytes + relatedFilesBytes
    }
    
    public static func == (lhs: AppInstall, rhs: AppInstall) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
public final class UninstallerService: ObservableObject {
    @Published public var apps: [AppInstall] = []
    @Published public var isScanning: Bool = false
    @Published public var isUninstalling: Bool = false
    
    private let systemAppPaths = [
        "/System/Applications",
        "/System/Library",
        "/Library/Apple",
        "/Applications/Safari.app"
    ]
    
    public init() {}
    
    public func scan() async {
        isScanning = true
        apps = []
        
        let foundApps = await performScan()
        
        self.apps = foundApps
        self.isScanning = false
    }
    
    public func uninstall(app: AppInstall) async {
        isUninstalling = true
        
        let pathsToRemove = await findRelatedFiles(forBundleID: app.bundleIdentifier) + [app.path]
        
        do {
            try await PrivilegeService.shared.deletePaths(pathsToRemove)
        } catch {
            print("Uninstall failed: \(error)")
        }
        
        await scan()
        isUninstalling = false
    }
    
    private func performScan() async -> [AppInstall] {
        var results: [AppInstall] = []
        let fileManager = FileManager.default
        let appsDir = URL(fileURLWithPath: "/Applications")
        
        guard let enumerator = fileManager.enumerator(at: appsDir, includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey], options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) else {
            return results
        }
        
        while let fileURL = enumerator.nextObject() as? URL {
            if fileURL.pathExtension == "app" {
                if systemAppPaths.contains(where: { fileURL.path.hasPrefix($0) }) {
                    continue // Skip system apps
                }
                
                guard let bundle = Bundle(url: fileURL),
                      let bundleIdentifier = bundle.bundleIdentifier else {
                    continue
                }
                
                let appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? fileURL.deletingPathExtension().lastPathComponent
                
                let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
                let appSize = folderSize(at: fileURL)
                let relatedSize = await calculateRelatedFilesSize(forBundleID: bundleIdentifier)
                
                results.append(AppInstall(
                    name: appName,
                    path: fileURL,
                    bundleIdentifier: bundleIdentifier,
                    appSizeBytes: appSize,
                    relatedFilesBytes: relatedSize,
                    icon: icon
                ))
            }
        }
        
        return results.sorted { $0.totalSizeBytes > $1.totalSizeBytes }
    }
    
    private func calculateRelatedFilesSize(forBundleID bundleID: String) async -> Int64 {
        let paths = await findRelatedFiles(forBundleID: bundleID)
        return paths.reduce(0) { $0 + folderSize(at: $1) }
    }
    
    private func findRelatedFiles(forBundleID bundleID: String) async -> [URL] {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        let searchPaths = [
            "Library/Application Support/\(bundleID)",
            "Library/Caches/\(bundleID)",
            "Library/Preferences/\(bundleID).plist",
            "Library/Saved Application State/\(bundleID).savedState",
            "Library/Containers/\(bundleID)",
            "Library/HTTPStorages/\(bundleID)",
            "Library/Logs/\(bundleID)"
        ]
        
        var foundPaths: [URL] = []
        
        for path in searchPaths {
            let url = homeDir.appendingPathComponent(path)
            if fileManager.fileExists(atPath: url.path) {
                foundPaths.append(url)
            }
        }
        
        return foundPaths
    }
    
    private func folderSize(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDir) {
            if isDir.boolValue {
                guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
                for case let fileURL as URL in enumerator {
                    if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += Int64(size)
                    }
                }
            } else {
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        return totalSize
    }
}
