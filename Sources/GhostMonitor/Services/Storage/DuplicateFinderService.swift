import Foundation
import CryptoKit
import SwiftUI

public struct DuplicateFileGroup: Identifiable, Sendable {
    public let id = UUID()
    public let fileHash: String
    public let fileSize: Int64
    public var files: [URL]
    
    public var reclaimableBytes: Int64 {
        guard files.count > 1 else { return 0 }
        return Int64(files.count - 1) * fileSize
    }
}

@MainActor
public final class DuplicateFinderService: ObservableObject {
    public static let shared = DuplicateFinderService()
    
    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var progressText: String = ""
    @Published public private(set) var duplicateGroups: [DuplicateFileGroup] = []
    
    public var totalReclaimableBytes: Int64 {
        duplicateGroups.reduce(0) { $0 + $1.reclaimableBytes }
    }
    
    private init() {}
    
    public func startScan() {
        guard !isScanning else { return }
        isScanning = true
        progressText = "Analyzing file trees in Downloads, Desktop & Documents..."
        
        Task.detached(priority: .userInitiated) {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let scanDirs = [
                home.appendingPathComponent("Downloads"),
                home.appendingPathComponent("Desktop"),
                home.appendingPathComponent("Documents"),
                home.appendingPathComponent("Pictures")
            ]
            
            var sizeMap: [Int64: [URL]] = [:]
            let fm = FileManager.default
            
            for dir in scanDirs {
                guard let enumerator = fm.enumerator(at: dir, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
                
                for case let fileURL as URL in enumerator {
                    if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                       values.isRegularFile == true,
                       let size = values.fileSize, size > 100_000 { // Only scan files > 100KB
                        sizeMap[Int64(size), default: []].append(fileURL)
                    }
                }
            }
            
            // Filter sizes that have 2+ files
            let candidates = sizeMap.filter { $0.value.count >= 2 }
            var hashMap: [String: (size: Int64, urls: [URL])] = [:]
            
            for (size, urls) in candidates {
                for url in urls {
                    if let data = try? Data(contentsOf: url, options: .mappedIfSafe) {
                        let hash = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
                        if hashMap[hash] == nil {
                            hashMap[hash] = (size, [url])
                        } else {
                            hashMap[hash]?.urls.append(url)
                        }
                    }
                }
            }
            
            let finalGroups = hashMap.compactMap { (hash, tuple) -> DuplicateFileGroup? in
                guard tuple.urls.count >= 2 else { return nil }
                return DuplicateFileGroup(fileHash: hash, fileSize: tuple.size, files: tuple.urls)
            }
            
            await MainActor.run {
                self.duplicateGroups = finalGroups.sorted(by: { $0.reclaimableBytes > $1.reclaimableBytes })
                self.isScanning = false
                self.progressText = finalGroups.isEmpty ? "Scan complete. No duplicates found." : "Scan complete. Found \(finalGroups.count) duplicate groups."
            }
        }
    }
    
    public func deleteFile(url: URL, from groupID: UUID) {
        try? FileManager.default.removeItem(at: url)
        if let idx = duplicateGroups.firstIndex(where: { $0.id == groupID }) {
            duplicateGroups[idx].files.removeAll(where: { $0 == url })
            if duplicateGroups[idx].files.count < 2 {
                duplicateGroups.remove(at: idx)
            }
        }
    }
}
