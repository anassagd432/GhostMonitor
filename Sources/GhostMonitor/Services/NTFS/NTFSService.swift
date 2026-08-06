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
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "eval $(/opt/homebrew/bin/brew shellenv); NONINTERACTIVE=1 brew install --cask macfuse gromgit/fuse/ntfs-3g-mac"]
        
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
            // Check disk partitions
            var candidates: [[String: Any]] = []
            if let partitions = disk["Partitions"] as? [[String: Any]] {
                candidates.append(contentsOf: partitions)
            }
            // Also check whole disk
            candidates.append(disk)
            
            for part in candidates {
                guard let devId = part["DeviceIdentifier"] as? String else { continue }
                
                let contentType = (part["Content"] as? String) ?? ""
                let volName = (part["VolumeName"] as? String) ?? "Untitled"
                let size = (part["Size"] as? Int64) ?? 0
                
                let isNTFSContent = contentType == "Windows_NTFS" ||
                                    contentType == "NTFS" ||
                                    contentType == "Microsoft Basic Data" ||
                                    contentType == "Basic Data" ||
                                    contentType == "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7" ||
                                    contentType == "0x07"
                
                // Deep inspection via diskutil info
                let fsType = checkFilesystemType(deviceIdentifier: devId)
                let isNTFS = isNTFSContent || fsType.contains("ntfs")
                
                if isNTFS {
                    let isRW = isMountedReadWrite(device: devId)
                    let drive = NTFSDrive(
                        id: devId,
                        name: volName.isEmpty ? "NTFS Drive (\(devId))" : volName,
                        sizeBytes: size,
                        deviceIdentifier: devId,
                        isMountedRW: isRW,
                        volumeName: volName.isEmpty ? "NTFS_Drive" : volName
                    )
                    if !foundDrives.contains(where: { $0.deviceIdentifier == devId }) {
                        foundDrives.append(drive)
                    }
                }
            }
        }
        
        return foundDrives
    }
    
    private nonisolated static func checkFilesystemType(deviceIdentifier: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        process.arguments = ["info", "-plist", deviceIdentifier]
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                let fsType = (plist["FilesystemType"] as? String) ?? (plist["FilesystemName"] as? String) ?? ""
                return fsType.lowercased()
            }
        } catch {}
        return ""
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
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("/dev/\(device)") {
                        if line.contains("macfuse") || line.contains("ntfs-3g") || (line.contains("read-write") || line.contains("rw,")) {
                            return true
                        }
                    }
                }
            }
        } catch {}
        return false
    }
    
    public func mountReadWrite(drive: NTFSDrive) async {
        let ntfsBinary = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/ntfs-3g") ? "/opt/homebrew/bin/ntfs-3g" : "/usr/local/bin/ntfs-3g"
        let hasNTFS3G = FileManager.default.fileExists(atPath: ntfsBinary)
        let volName = drive.volumeName.isEmpty ? "NTFS_Drive" : drive.volumeName
        
        // 1. Unmount existing read-only mount
        let unmountProc = Process()
        unmountProc.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        unmountProc.arguments = ["unmount", drive.deviceIdentifier]
        try? unmountProc.run()
        unmountProc.waitUntilExit()
        
        // 2. Mount command (use ntfs-3g if installed, or native mount_ntfs fallback)
        let mountCommand: String
        if hasNTFS3G {
            mountCommand = "mkdir -p /Volumes/\(volName) && \(ntfsBinary) /dev/\(drive.deviceIdentifier) /Volumes/\(volName) -o local,allow_other,auto_xattr,volname=\(volName)"
        } else {
            mountCommand = "mkdir -p /Volumes/\(volName) && mount_ntfs -o rw /dev/\(drive.deviceIdentifier) /Volumes/\(volName) || mount -t ntfs -o rw /dev/\(drive.deviceIdentifier) /Volumes/\(volName)"
        }
        
        do {
            try await PrivilegeService.shared.executeAsRoot(mountCommand)
            scanDrives()
        } catch {
            print("Failed to mount NTFS drive RW: \(error)")
        }
    }
}
