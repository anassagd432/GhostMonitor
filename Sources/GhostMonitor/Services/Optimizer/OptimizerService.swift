import Foundation

public struct StartupItem: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let path: URL
    public let type: ItemType
    public var isEnabled: Bool
    
    public enum ItemType: String, Sendable {
        case userAgent = "User Launch Agent"
        case systemAgent = "System Launch Agent"
        case systemDaemon = "System Launch Daemon"
    }
}

@MainActor
public final class OptimizerService: ObservableObject {
    @Published public var items: [StartupItem] = []
    @Published public var isScanning: Bool = false
    
    public init() {}
    
    public func scan() async {
        isScanning = true
        items = []
        
        let foundItems = await performScan()
        
        self.items = foundItems
        self.isScanning = false
    }
    
    public func toggleItem(_ item: StartupItem) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        let targetState = !item.isEnabled
        let requiresRoot = item.type == .systemAgent || item.type == .systemDaemon
        
        do {
            try await PrivilegeService.shared.toggleLaunchItem(path: item.path.path, enable: targetState, requiresRoot: requiresRoot)
            items[index].isEnabled = targetState
        } catch {
            print("Failed to toggle \(item.name): \(error)")
        }
    }
    
    public func freeMemory() async {
        do {
            try await PrivilegeService.shared.freeMemory()
        } catch {
            print("Failed to free memory: \(error)")
        }
    }
    
    private func performScan() async -> [StartupItem] {
        var results: [StartupItem] = []
        let fileManager = FileManager.default
        
        let directories: [(String, StartupItem.ItemType)] = [
            ("~/Library/LaunchAgents", .userAgent),
            ("/Library/LaunchAgents", .systemAgent),
            ("/Library/LaunchDaemons", .systemDaemon)
        ]
        
        for (dir, type) in directories {
            let expandedPath = NSString(string: dir).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            
            do {
                let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                for fileURL in contents where fileURL.pathExtension == "plist" {
                    // Check if it's currently loaded
                    let isLoaded = checkIfLoaded(plistPath: fileURL.path)
                    
                    results.append(StartupItem(
                        name: fileURL.deletingPathExtension().lastPathComponent,
                        path: fileURL,
                        type: type,
                        isEnabled: isLoaded
                    ))
                }
            } catch {
                print("Error reading \(dir): \(error)")
            }
        }
        
        return results.sorted { $0.name < $1.name }
    }
    
    private func checkIfLoaded(plistPath: String) -> Bool {
        // A simple heuristic for now. Real implementation needs parsing `launchctl list`
        // We will assume enabled for now, or we could run `launchctl list` and grep for the label.
        
        guard let dict = NSDictionary(contentsOfFile: plistPath),
              let label = dict["Label"] as? String else {
            return true // Default to true if we can't parse
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list"]
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.contains(label)
        } catch {
            return true
        }
    }
}
