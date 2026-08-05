import Foundation
import AppKit
import Combine

@MainActor
public class SpyCatcherService: ObservableObject {
    public static let shared = SpyCatcherService()
    
    @Published public var isYaraInstalled: Bool = false
    @Published public var isInstalling: Bool = false
    @Published public var installProgress: String = ""
    
    @Published public var scanStatus: String = "Ready to scan!"
    @Published public var isScanning: Bool = false
    @Published public var scanResults: [ScanFinding] = []
    
    public struct ScanFinding: Identifiable {
        public let id = UUID()
        public let title: String
        public let description: String
        public let isThreat: Bool
    }
    
    private let rulesPath: String
    private var yaraPath: String = ""
    
    private init() {
        // Create YARA rules file
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("GhostMonitor")
        try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        
        self.rulesPath = appSupport.appendingPathComponent("spy_rules.yara").path
        createYaraRules()
        checkInstallation()
    }
    
    private func createYaraRules() {
        let rules = """
        rule Suspicious_Keylogger {
            meta:
                description = "Detects code used to record keyboard strokes."
            strings:
                $a = "CGEventTapCreate"
                $b = "kCGEventKeyDown"
            condition:
                $a and $b
        }

        rule Suspicious_Camera {
            meta:
                description = "Detects code that can access the Camera and Microphone."
            strings:
                $a = "AVCaptureDevice"
                $b = "AVCaptureSession"
            condition:
                all of them
        }
        
        rule Suspicious_Persistence {
            meta:
                description = "Detects code trying to run silently at startup."
            strings:
                $a = "LaunchAgents"
                $b = "LaunchDaemons"
            condition:
                any of them
        }
        
        rule Crypto_Miner {
            meta:
                description = "Detects cryptocurrency mining logic."
            strings:
                $a = "stratum+tcp"
                $b = "xmrig"
                $c = "coinhive"
            condition:
                any of them
        }
        
        rule Screen_Grabber {
            meta:
                description = "Detects rogue apps taking silent screenshots."
            strings:
                $a = "CGWindowListCreateImage"
                $b = "CGDisplayCreateImage"
            condition:
                any of them
        }
        
        rule Data_Exfiltration {
            meta:
                description = "Detects apps bundling files and sending them out."
            strings:
                $a = "NSURLSession"
                $b = "base64EncodedString"
            condition:
                all of them
        }
        """
        try? rules.write(toFile: rulesPath, atomically: true, encoding: .utf8)
    }
    
    public func checkInstallation() {
        // Check standard homebrew paths
        let paths = ["/opt/homebrew/bin/yara", "/usr/local/bin/yara"]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                self.yaraPath = path
                self.isYaraInstalled = true
                return
            }
        }
        self.isYaraInstalled = false
    }
    
    public func installYaraEngine() {
        guard !isInstalling else { return }
        isInstalling = true
        installProgress = "Opening Terminal for installation..."
        
        Task.detached {
            let script = """
            #!/bin/bash
            clear
            echo "================================================="
            echo " Ghost Monitor: Installing YARA Security Scanner "
            echo "================================================="
            echo ""
            echo "You may be asked for your Mac password to install Homebrew."
            echo "(Note: As you type your password, characters won't appear on screen. This is normal.)"
            echo ""
            
            if ! command -v brew &> /dev/null; then
                echo "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            echo ""
            echo "Installing YARA..."
            if [ -x "/opt/homebrew/bin/brew" ]; then
                /opt/homebrew/bin/brew install yara
            elif [ -x "/usr/local/bin/brew" ]; then
                /usr/local/bin/brew install yara
            else
                echo "Homebrew not found! Please install manually."
            fi
            
            echo ""
            echo "================================================="
            echo " Installation Complete! You can close this window."
            echo "================================================="
            """
            
            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("GhostMonitor")
            let commandFile = appSupport.appendingPathComponent("Install_YARA.command")
            
            try? script.write(to: commandFile, atomically: true, encoding: .utf8)
            try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: commandFile.path)
            
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [commandFile.path]
            try? task.run()
            
            await MainActor.run {
                self.installProgress = "Waiting for Terminal installation to finish..."
            }
            
            // Poll for up to 5 minutes (150 * 2 seconds = 300 seconds)
            var foundYara = false
            for _ in 0..<150 {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                
                foundYara = await MainActor.run {
                    self.checkInstallation()
                    return self.isYaraInstalled
                }
                
                if foundYara {
                    break
                }
            }
            
            await MainActor.run {
                self.isInstalling = false
                if self.isYaraInstalled {
                    self.installProgress = "Installation successful!"
                } else {
                    self.installProgress = "Installation timed out."
                }
            }
        }
    }
    
    public func scanApp(at url: URL) {
        guard isYaraInstalled, !yaraPath.isEmpty else { return }
        guard url.pathExtension == "app" else {
            self.scanStatus = "Please drop an .app file!"
            return
        }
        
        self.isScanning = true
        self.scanStatus = "Scanning \(url.lastPathComponent)..."
        self.scanResults.removeAll()
        
        let currentYaraPath = self.yaraPath
        let currentRulesPath = self.rulesPath
        
        Task.detached {
            var findings: [ScanFinding] = []
            
            // 1. Check Quarantine (Download Source)
            let qTask = Process()
            qTask.launchPath = "/usr/bin/xattr"
            qTask.arguments = ["-p", "com.apple.quarantine", url.path]
            let qPipe = Pipe()
            qTask.standardOutput = qPipe
            try? qTask.run()
            let qData = qPipe.fileHandleForReading.readDataToEndOfFile()
            if let qString = String(data: qData, encoding: .utf8), !qString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // Parse the quarantine string (usually contains the download URL)
                let parts = qString.components(separatedBy: ";")
                if parts.count >= 3 {
                    findings.append(ScanFinding(
                        title: "Download Source Tracker",
                        description: "This app was downloaded from the internet. macOS marked it with quarantine tags.",
                        isThreat: false
                    ))
                }
            }
            
            // 2. Check Signature (codesign)
            let csTask = Process()
            csTask.launchPath = "/usr/bin/codesign"
            csTask.arguments = ["-dv", url.path]
            let csPipe = Pipe()
            csTask.standardError = csPipe // codesign outputs to stderr
            try? csTask.run()
            let csData = csPipe.fileHandleForReading.readDataToEndOfFile()
            let csString = String(data: csData, encoding: .utf8) ?? ""
            
            if csString.contains("invalid") || csString.contains("unsigned") || csString.contains("code object is not signed") {
                findings.append(ScanFinding(
                    title: "Broken Signature ⚠️",
                    description: "This app is either cracked or modified. The original Apple Developer signature is missing or broken.",
                    isThreat: true
                ))
            } else if csString.contains("Authority") {
                findings.append(ScanFinding(
                    title: "Valid Apple Signature 🍏",
                    description: "This app has a valid developer certificate.",
                    isThreat: false
                ))
            }
            
            // 3. YARA Scan on binary
            let binaryFolder = url.appendingPathComponent("Contents/MacOS").path
            
            let yTask = Process()
            yTask.launchPath = currentYaraPath
            yTask.arguments = ["-r", currentRulesPath, binaryFolder]
            let yPipe = Pipe()
            yTask.standardOutput = yPipe
            try? yTask.run()
            let yData = yPipe.fileHandleForReading.readDataToEndOfFile()
            let yString = String(data: yData, encoding: .utf8) ?? ""
            
            if yString.contains("Suspicious_Keylogger") {
                findings.append(ScanFinding(
                    title: "Keylogger Code Detected 🚨",
                    description: "Warning: We found code inside this app that can secretly record your keyboard strokes!",
                    isThreat: true
                ))
            }
            if yString.contains("Suspicious_Camera") {
                findings.append(ScanFinding(
                    title: "Camera/Mic Access 📸",
                    description: "This app has hidden code capable of turning on your camera or microphone.",
                    isThreat: true
                ))
            }
            if yString.contains("Suspicious_Persistence") {
                findings.append(ScanFinding(
                    title: "Sneaky Startup Scripts 🦠",
                    description: "This app tries to install hidden scripts so it runs invisibly every time you start your Mac.",
                    isThreat: true
                ))
            }
            
            if findings.isEmpty {
                findings.append(ScanFinding(
                    title: "App Looks Clean ✨",
                    description: "No known spyware or broken signatures found.",
                    isThreat: false
                ))
            }
            
            let finalFindings = findings
            await MainActor.run {
                self.scanResults = finalFindings
                self.isScanning = false
                self.scanStatus = "Scan Complete!"
            }
        }
    }
}
