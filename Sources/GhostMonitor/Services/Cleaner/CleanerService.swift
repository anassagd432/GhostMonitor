import Foundation

public struct CleanableItem: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let path: URL
    public let sizeBytes: Int64
    public let category: CleanCategory
}

public enum CleanCategory: String, CaseIterable, Sendable {
    case caches = "Application Caches"
    case logs = "System Logs"
    case downloads = "Downloads"
    case trash = "Trash"
}

@MainActor
public final class CleanerService: ObservableObject {
    @Published public var items: [CleanableItem] = []
    @Published public var isScanning: Bool = false
    @Published public var isCleaning: Bool = false
    @Published public var totalSizeScanned: Int64 = 0
    
    public init() {}
    
    public func scan() async {
        isScanning = true
        items = []
        totalSizeScanned = 0
        
        let foundItems = await performScan()
        
        self.items = foundItems
        self.totalSizeScanned = foundItems.reduce(0) { $0 + $1.sizeBytes }
        self.isScanning = false
    }
    
    public func clean(itemsToClean: [CleanableItem]) async {
        isCleaning = true
        
        let pathsToRemove = itemsToClean.map { $0.path }
        
        do {
            try await PrivilegeService.shared.deletePaths(pathsToRemove)
        } catch {
            print("Cleaning failed: \(error)")
        }
        
        await scan()
        isCleaning = false
    }
    
    private func performScan() async -> [CleanableItem] {
        var results: [CleanableItem] = []
        let fileManager = FileManager.default
        
        // Caches
        if let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let cacheItems = getDirectoryContents(at: cacheURL, category: .caches)
            results.append(contentsOf: cacheItems)
        }
        
        // Logs
        let userLogsURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs")
        let logItems = getDirectoryContents(at: userLogsURL, category: .logs)
        results.append(contentsOf: logItems)
        
        // Trash
        if let trashURL = fileManager.urls(for: .trashDirectory, in: .userDomainMask).first {
            let trashItems = getDirectoryContents(at: trashURL, category: .trash)
            results.append(contentsOf: trashItems)
        }
        
        // Downloads (Files larger than 50MB and older than 30 days)
        if let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let oldDownloads = getOldLargeFiles(at: downloadsURL, category: .downloads, minSize: 50 * 1024 * 1024, maxDays: 30)
            results.append(contentsOf: oldDownloads)
        }
        
        return results
    }
    
    private func getDirectoryContents(at url: URL, category: CleanCategory) -> [CleanableItem] {
        var items: [CleanableItem] = []
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return items
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                _ = resourceValues.isDirectory ?? false
                
                // We only count top-level directories within these folders, or just delete the contents.
                // To be safe, we list the immediate children of the cache folder and calculate their total size.
            } catch {
                continue
            }
        }
        
        // Refined approach: Instead of listing every file, list the immediate subdirectories of the Caches/Logs folder
        // so the user sees "com.apple.Safari", etc.
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])
            for itemURL in contents {
                let size = folderSize(at: itemURL)
                if size > 0 {
                    items.append(CleanableItem(name: itemURL.lastPathComponent, path: itemURL, sizeBytes: size, category: category))
                }
            }
        } catch {
            print("Error reading directory \(url): \(error)")
        }
        
        return items.sorted(by: { $0.sizeBytes > $1.sizeBytes })
    }
    
    private func getOldLargeFiles(at url: URL, category: CleanCategory, minSize: Int64, maxDays: Int) -> [CleanableItem] {
        var items: [CleanableItem] = []
        let fileManager = FileManager.default
        let timeThreshold = Date().addingTimeInterval(TimeInterval(-maxDays * 24 * 60 * 60))
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
            for itemURL in contents {
                let resources = try itemURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
                if let size = resources.fileSize, Int64(size) > minSize,
                   let creationDate = resources.creationDate, creationDate < timeThreshold {
                    items.append(CleanableItem(name: itemURL.lastPathComponent, path: itemURL, sizeBytes: Int64(size), category: category))
                }
            }
        } catch {
            print("Error reading downloads: \(error)")
        }
        
        return items
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
