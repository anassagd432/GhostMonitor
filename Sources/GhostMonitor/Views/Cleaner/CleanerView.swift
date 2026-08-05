import SwiftUI

public struct CleanerView: View {
    @StateObject private var cleaner = CleanerService()
    @State private var selectedCategories: Set<CleanCategory> = Set(CleanCategory.allCases)
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Storage Cleaner")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Reclaim wasted storage space on your Mac.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: {
                    Task {
                        await cleaner.scan()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(.degrees(cleaner.isScanning ? 360 : 0))
                            .animation(cleaner.isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: cleaner.isScanning)
                        Text(cleaner.isScanning ? "Scanning..." : "Scan System")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(cleaner.isScanning || cleaner.isCleaning)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Categories Selector
            HStack {
                ForEach(CleanCategory.allCases, id: \.self) { category in
                    Toggle(isOn: Binding(
                        get: { selectedCategories.contains(category) },
                        set: { isSelected in
                            if isSelected {
                                selectedCategories.insert(category)
                            } else {
                                selectedCategories.remove(category)
                            }
                        }
                    )) {
                        Text(category.rawValue)
                    }
                    .toggleStyle(.checkbox)
                    .padding(.trailing, 10)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            // Results List
            List {
                let filteredItems = cleaner.items.filter { selectedCategories.contains($0.category) }
                
                if cleaner.items.isEmpty {
                    if cleaner.isScanning {
                        HStack {
                            Spacer()
                            ProgressView("Scanning your system...")
                                .padding()
                            Spacer()
                        }
                    } else {
                        HStack {
                            Spacer()
                            Text("Click 'Scan System' to find cleanable files.")
                                .foregroundColor(.secondary)
                                .padding()
                            Spacer()
                        }
                    }
                } else if filteredItems.isEmpty {
                    HStack {
                        Spacer()
                        Text("No items found for the selected categories.")
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    }
                } else {
                    ForEach(filteredItems) { item in
                        HStack {
                            Image(systemName: icon(for: item.category))
                                .foregroundColor(color(for: item.category))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Text(item.category.rawValue)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(ByteFormatter.formatBytes(item.sizeBytes))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Bottom Action Bar
            HStack {
                let filteredItems = cleaner.items.filter { selectedCategories.contains($0.category) }
                let totalSize = filteredItems.reduce(0) { $0 + $1.sizeBytes }
                
                VStack(alignment: .leading) {
                    Text("Total Reclaimable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(ByteFormatter.formatBytes(totalSize))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(totalSize > 0 ? .green : .primary)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await cleaner.clean(itemsToClean: filteredItems)
                    }
                }) {
                    Text(cleaner.isCleaning ? "Cleaning..." : "Clean Selected")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(filteredItems.isEmpty || cleaner.isScanning || cleaner.isCleaning)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func icon(for category: CleanCategory) -> String {
        switch category {
        case .caches: return "cylinder.split.1x2"
        case .logs: return "doc.text"
        case .downloads: return "arrow.down.circle"
        case .trash: return "trash"
        }
    }
    
    private func color(for category: CleanCategory) -> Color {
        switch category {
        case .caches: return .blue
        case .logs: return .orange
        case .downloads: return .purple
        case .trash: return .red
        }
    }
}
