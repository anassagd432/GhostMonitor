import Foundation
import Combine
import AppKit
import Network
import UserNotifications

@MainActor
public class CrossDropService: ObservableObject {
    public static let shared = CrossDropService()
    
    @Published public var isRunning = false
    @Published public var ipAddress: String = "Unknown"
    @Published public var port: Int = 8080
    nonisolated public let sharedFilesFolder: URL
    
    private var listener: NWListener?
    private var activeConnections: [NWConnection] = []
    
    private init() {
        let downloadsFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        sharedFilesFolder = downloadsFolder.appendingPathComponent("GhostMonitor_CrossDrop")
        try? FileManager.default.createDirectory(at: sharedFilesFolder, withIntermediateDirectories: true)
        
        self.port = SettingsService.shared.crossDropPort
        
        // Setup initial ip address
        self.ipAddress = getLocalIPAddress() ?? "Unknown"
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    public func startServer() {
        if isRunning { return }
        startListener(on: self.port)
    }
    
    private func startListener(on currentPort: Int) {
        do {
            let nwPort = NWEndpoint.Port(integerLiteral: UInt16(currentPort))
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: nwPort)
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready:
                        self?.port = currentPort
                        self?.isRunning = true
                        print("Native CrossDrop server started on port \(currentPort)")
                    case .failed(let error):
                        print("Server failed on port \(currentPort): \(error)")
                        self?.listener?.cancel()
                        self?.listener = nil
                        // Try next port if failed (e.g. address in use)
                        if currentPort < 8100 {
                            self?.startListener(on: currentPort + 1)
                        } else {
                            self?.stopServer()
                        }
                    default:
                        break
                    }
                }
            }
            
            listener?.start(queue: .global())
        } catch {
            print("Failed to start listener: \(error)")
            if currentPort < 8100 {
                startListener(on: currentPort + 1)
            }
        }
    }
    
    public func stopServer() {
        listener?.cancel()
        listener = nil
        for conn in activeConnections {
            conn.cancel()
        }
        activeConnections.removeAll()
        isRunning = false
    }
    
    public func openFolder() {
        NSWorkspace.shared.open(sharedFilesFolder)
    }
    
    nonisolated private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())
        // Since we are nonisolated, we can't easily append to activeConnections without locking, but for this local server it's fine to just ignore tracking it exactly.
        receiveRequest(on: connection)
    }
    
    nonisolated private func receiveRequest(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let self = self, let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }
            
            // Very basic HTTP parsing, robust for binary bodies
            let headerEndMarker = Data("\r\n\r\n".utf8)
            guard let headerRange = data.range(of: headerEndMarker) else {
                connection.cancel()
                return
            }
            
            let headerData = data.subdata(in: 0..<headerRange.lowerBound)
            let headerString = String(data: headerData, encoding: .utf8) ?? ""
            let lines = headerString.components(separatedBy: "\r\n")
            
            guard let requestLine = lines.first else {
                connection.cancel()
                return
            }
            
            let parts = requestLine.components(separatedBy: " ")
            guard parts.count >= 2 else {
                connection.cancel()
                return
            }
            
            let method = parts[0]
            let path = parts[1]
            
            if method == "GET" && path == "/" {
                self.sendHTMLResponse(to: connection)
            } else if method == "POST" && path.starts(with: "/notify") {
                if let url = URL(string: path), let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let textItem = components.queryItems?.first(where: { $0.name == "text" }), let text = textItem.value {
                    self.showNotification(title: "Cross-Drop Received", body: text)
                }
                self.sendSuccessResponse(to: connection)
            } else if method == "POST" && path.starts(with: "/upload") {
                // Parse filename and path
                var filename = "upload_\(UUID().uuidString)"
                if let url = URL(string: path), let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let nameItem = components.queryItems?.first(where: { $0.name == "name" }), let name = nameItem.value {
                    filename = name
                }
                
                // Parse Content-Length
                var contentLength = 0
                for line in lines {
                    if line.lowercased().starts(with: "content-length:") {
                        let val = line.dropFirst(15).trimmingCharacters(in: .whitespaces)
                        contentLength = Int(val) ?? 0
                    }
                }
                
                let initialBodyData = data.subdata(in: headerRange.upperBound..<data.count)
                let fileURL = self.sharedFilesFolder.appendingPathComponent(filename)
                let directoryURL = fileURL.deletingLastPathComponent()
                
                // Create folder structure if it doesn't exist
                try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                FileManager.default.createFile(atPath: fileURL.path, contents: initialBodyData, attributes: nil)
                
                let remainingBytes = contentLength - initialBodyData.count
                if remainingBytes > 0 {
                    self.receiveRemainingBody(on: connection, fileURL: fileURL, remaining: remainingBytes)
                } else {
                    self.sendSuccessResponse(to: connection)
                }
            } else {
                connection.cancel()
            }
        }
    }
    
    nonisolated private func receiveRemainingBody(on connection: NWConnection, fileURL: URL, remaining: Int) {
        let chunkToRead = min(remaining, 65536) // Prevent memory crash on big files
        connection.receive(minimumIncompleteLength: 1, maximumLength: chunkToRead) { [weak self] data, context, isComplete, error in
            if let data = data, !data.isEmpty {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
                
                let stillRemaining = remaining - data.count
                if stillRemaining > 0 {
                    self?.receiveRemainingBody(on: connection, fileURL: fileURL, remaining: stillRemaining)
                } else {
                    self?.sendSuccessResponse(to: connection)
                }
            } else {
                connection.cancel()
            }
        }
    }
    
    nonisolated private func sendHTMLResponse(to connection: NWConnection) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Ghost Monitor Cross-Drop</title>
            <style>
                body { font-family: -apple-system, system-ui; background: #111; color: white; text-align: center; padding: 40px; }
                .card { background: #222; border-radius: 16px; padding: 30px; max-width: 500px; margin: 0 auto; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
                input[type=file] { display: none; }
                .btn { background: #007AFF; color: white; padding: 15px 30px; border-radius: 10px; font-size: 16px; font-weight: bold; cursor: pointer; display: inline-block; margin: 10px; }
                .btn-secondary { background: #FF9500; }
                h2 { margin-top: 0; }
                #status { margin-top: 20px; color: #4cd964; font-weight: bold; word-break: break-all; }
            </style>
        </head>
        <body>
            <div class="card">
                <h2>Drop to Mac</h2>
                
                <label for="fileInput" class="btn">Select Files</label>
                <input type="file" id="fileInput" multiple>
                
                <label for="folderInput" class="btn btn-secondary">Select Folder</label>
                <input type="file" id="folderInput" webkitdirectory directory multiple>
                
                <p style="margin-top: 20px; color: #888;">Selected files or entire folders will instantly transfer to the Mac's Downloads folder.</p>
                <div id="status"></div>
            </div>
            
            <script>
                async function handleUpload(e) {
                    const status = document.getElementById('status');
                    status.innerText = 'Sending...';
                    
                    for (let file of e.target.files) {
                        // Use webkitRelativePath for folders, fallback to name for single files
                        const filePath = file.webkitRelativePath || file.name;
                        status.innerText = 'Sending ' + filePath + '...';
                        
                        try {
                            await fetch('/upload?name=' + encodeURIComponent(filePath), {
                                method: 'POST',
                                body: file
                            });
                        } catch (err) {
                            console.error(err);
                        }
                    }
                    
                    status.innerText = 'All files transferred successfully!';
                    e.target.value = '';
                    
                    // Tell Mac to show notification
                    const count = e.target.files.length;
                    const topLevel = e.target.files[0].webkitRelativePath ? e.target.files[0].webkitRelativePath.split('/')[0] : (count > 1 ? count + " files" : e.target.files[0].name);
                    fetch('/notify?text=' + encodeURIComponent(topLevel), { method: 'POST' });
                }
                
                document.getElementById('fileInput').addEventListener('change', handleUpload);
                document.getElementById('folderInput').addEventListener('change', handleUpload);
            </script>
        </body>
        </html>
        """
        
        let response = "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/html\r\nContent-Length: \(html.utf8.count)\r\n\r\n\(html)"
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
    
    nonisolated private func sendSuccessResponse(to connection: NWConnection) {
        let response = "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Length: 2\r\n\r\nOK"
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // Usually Wi-Fi on Mac
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
    
    nonisolated private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
