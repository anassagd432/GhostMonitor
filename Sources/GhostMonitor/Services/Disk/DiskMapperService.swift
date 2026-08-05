import Foundation
import CryptoKit

public struct DiskFolderItem: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let path: URL
    public let sizeBytes: Int64
    public let isDirectory: Bool
    public var children: [DiskFolderItem]?
}

public struct DuplicateFileItem: Identifiable, Sendable {
    public let id = UUID()
    public let path: URL
    public let sizeBytes: Int64
    public let hash: String
}

@MainActor
public final class DiskMapperService: ObservableObject {
    public static let shared = DiskMapperService()
    
    @Published public private(set) var isScanning = false
    @Published public private(set) var rootItem: DiskFolderItem?
    @Published public private(set) var duplicates: [DuplicateFileItem] = []
    
    public init() {}
    
    public func scanDisk(url: URL) async {
        isScanning = true
        
        let root = await calculateSizes(at: url, depth: 3)
        let dupes = await findDuplicates(in: url)
        
        rootItem = root
        duplicates = dupes
        isScanning = false
    }
    
    private func calculateSizes(at url: URL, depth: Int) async -> DiskFolderItem? {
        guard depth > 0 else {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return DiskFolderItem(name: url.lastPathComponent, path: url, sizeBytes: Int64(size), isDirectory: false, children: nil)
        }
        
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey], options: [.skipsSubdirectoryDescendants]) else {
            return nil
        }
        
        var children: [DiskFolderItem] = []
        var totalSize: Int64 = 0
        
        while let childURL = enumerator.nextObject() as? URL {
            let isDir = (try? childURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                if let childItem = await calculateSizes(at: childURL, depth: depth - 1) {
                    children.append(childItem)
                    totalSize += childItem.sizeBytes
                }
            } else {
                let size = (try? childURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                totalSize += Int64(size)
                children.append(DiskFolderItem(name: childURL.lastPathComponent, path: childURL, sizeBytes: Int64(size), isDirectory: false, children: nil))
            }
        }
        
        children.sort(by: { $0.sizeBytes > $1.sizeBytes })
        
        return DiskFolderItem(name: url.lastPathComponent, path: url, sizeBytes: totalSize, isDirectory: true, children: children)
    }
    
    private func findDuplicates(in url: URL) async -> [DuplicateFileItem] {
        var sizeMap: [Int: [URL]] = [:]
        let fm = FileManager.default
        
        // Find files grouped by exact size
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        
        while let fileURL = enumerator.nextObject() as? URL {
            if let isDir = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory, !isDir {
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 1_000_000 { // Only files > 1MB
                    sizeMap[size, default: []].append(fileURL)
                }
            }
        }
        
        var dupes: [DuplicateFileItem] = []
        
        // Hash files that share the exact same size
        for (size, urls) in sizeMap where urls.count > 1 {
            var hashMap: [String: [URL]] = [:]
            for u in urls {
                if let hash = hashFile(url: u) {
                    hashMap[hash, default: []].append(u)
                }
            }
            
            for (hash, identicalUrls) in hashMap where identicalUrls.count > 1 {
                for u in identicalUrls {
                    dupes.append(DuplicateFileItem(path: u, sizeBytes: Int64(size), hash: hash))
                }
            }
        }
        
        return dupes.sorted(by: { $0.sizeBytes > $1.sizeBytes })
    }
    
    private func hashFile(url: URL) -> String? {
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        } catch {
            return nil
        }
    }
}
