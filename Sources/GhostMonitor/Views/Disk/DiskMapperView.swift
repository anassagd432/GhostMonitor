import SwiftUI

public struct DiskMapperView: View {
    @StateObject private var mapper = DiskMapperService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Visual Disk Mapper")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Deep scan directories for massive folders and identical duplicates.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if mapper.isScanning {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Button("Scan Home Directory") {
                        Task {
                            let home = FileManager.default.homeDirectoryForCurrentUser
                            await mapper.scanDisk(url: home)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            HStack(spacing: 16) {
                // Large Folders
                VStack(alignment: .leading) {
                    Text("Largest Folders")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    List {
                        if let root = mapper.rootItem, let children = root.children {
                            ForEach(children) { child in
                                HStack {
                                    Image(systemName: child.isDirectory ? "folder.fill" : "doc.fill")
                                        .foregroundColor(child.isDirectory ? .blue : .gray)
                                    Text(child.name)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(formatBytes(child.sizeBytes))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("No scan data.").foregroundColor(.secondary)
                        }
                    }
                    .cornerRadius(8)
                }
                
                // Duplicates
                VStack(alignment: .leading) {
                    Text("Identical Duplicates (>1MB)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(mapper.duplicates) { dupe in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(dupe.path.lastPathComponent)
                                        .lineLimit(1)
                                    Text(dupe.path.deletingLastPathComponent().path)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text(formatBytes(dupe.sizeBytes))
                                    .font(.system(size: 12, design: .monospaced))
                            }
                        }
                    }
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
