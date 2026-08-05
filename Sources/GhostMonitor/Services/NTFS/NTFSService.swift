import Foundation
import Combine

public struct NTFSDrive: Identifiable, Equatable, Sendable {
    public let id: String // e.g., disk2s1
    public let name: String
    public let sizeBytes: Int64
    public let deviceIdentifier: String
    public let isMountedRW: Bool
    public let volumeName: String
}

@MainActor
public final class NTFSService: ObservableObject {
    public static let shared = NTFSService()
    
    @Published public private(set) var drives: [NTFSDrive] = []
    @Published public private(set) var isScanning = false
    @Published public private(set) var isDriverInstalled = false
    @Published public private(set) var isInstallingDriver = false
    
    private var timer: Timer?
    
    public init() {
        checkDriverStatus()
    }
    
    public func startScanning() {
        scanDrives()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.scanDrives()
            }
        }
    }
    
    public func stopScanning() {
        timer?.invalidate()
        timer = nil
    }
    
    public func checkDriverStatus() {
        let fm = FileManager.default
        let homebrewPath = "/opt/homebrew/bin/ntfs-3g"
        let intelBrewPath = "/usr/local/bin/ntfs-3g"
        
        isDriverInstalled = fm.fileExists(atPath: homebrewPath) || fm.fileExists(atPath: intelBrewPath)
    }
    
    public func installDrivers() async {
        isInstallingDriver = true
        
        // This command runs brew to install macfuse and ntfs-3g-mac
        // Note: brew shouldn't normally be run as root, so we run it as the current user.
        // However, installing casks like macfuse may prompt for password in the terminal.
        // Since we are invoking it via Process, we'll try standard brew install.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "eval $(/opt/homebrew/bin/brew shellenv); brew install gromgit/fuse/ntfs-3g-mac macfuse"]
        
        do {
            try process.run()
            process.waitUntilExit()
            checkDriverStatus()
        } catch {
            print("Failed to install NTFS drivers: \(error)")
        }
        
        isInstallingDriver = false
    }
    
    public func scanDrives() {
        isScanning = true
        
        Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
            process.arguments = ["list", "-plist"]
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let drives = Self.parseDiskutil(data)
                
                Task { @MainActor in
                    self.drives = drives
                    self.isScanning = false
                }
            } catch {
                print("Failed to run diskutil: \(error)")
                Task { @MainActor in self.isScanning = false }
            }
        }
    }
    
    private nonisolated static func parseDiskutil(_ data: Data) -> [NTFSDrive] {
        var foundDrives: [NTFSDrive] = []
        
        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let allDisksAndPartitions = plist["AllDisksAndPartitions"] as? [[String: Any]] else {
            return []
        }
        
        for disk in allDisksAndPartitions {
            if let partitions = disk["Partitions"] as? [[String: Any]] {
                for part in partitions {
                    if let type = part["Content"] as? String, type == "Windows_NTFS" || type == "NTFS",
                       let devId = part["DeviceIdentifier"] as? String {
                        
                        let volName = (part["VolumeName"] as? String) ?? "Untitled"
                        let size = (part["Size"] as? Int64) ?? 0
                        
                        // Check if it's currently mounted natively (which implies Read-Only for NTFS)
                        // Or if it's mounted via macfuse (Read-Write)
                        // A quick heuristic: if it's mounted, we check mount output
                        let isRW = isMountedReadWrite(device: devId)
                        
                        let drive = NTFSDrive(
                            id: devId,
                            name: volName,
                            sizeBytes: size,
                            deviceIdentifier: devId,
                            isMountedRW: isRW,
                            volumeName: volName
                        )
                        foundDrives.append(drive)
                    }
                }
            }
        }
        
        return foundDrives
    }
    
    private nonisolated static func isMountedReadWrite(device: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/mount")
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Look for "/dev/diskXsY on /Volumes/Name (macfuse" or something indicating rw
                // Or simply check if ntfs-3g / macfuse is in the mount line for this device
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("/dev/\(device)") {
                        if line.contains("macfuse") || line.contains("ntfs-3g") {
                            return true // It's mounted by our 3rd party driver!
                        }
                    }
                }
            }
        } catch {}
        return false
    }
    
    public func mountReadWrite(drive: NTFSDrive) async {
        let ntfsBinary = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/ntfs-3g") ? "/opt/homebrew/bin/ntfs-3g" : "/usr/local/bin/ntfs-3g"
        let volName = drive.volumeName.isEmpty ? "NTFS_Drive" : drive.volumeName
        
        // 1. Unmount the Apple Read-Only mount
        let unmountProc = Process()
        unmountProc.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        unmountProc.arguments = ["unmount", drive.deviceIdentifier]
        try? unmountProc.run()
        unmountProc.waitUntilExit()
        
        // 2. Create the mount directory and run ntfs-3g via root
        let mountCommand = "mkdir -p /Volumes/\(volName) && \(ntfsBinary) /dev/\(drive.deviceIdentifier) /Volumes/\(volName) -o local,allow_other,auto_xattr,volname=\(volName)"
        
        do {
            try await PrivilegeService.shared.executeAsRoot(mountCommand)
            scanDrives() // refresh
        } catch {
            print("Failed to mount NTFS drive RW: \(error)")
        }
    }
}
