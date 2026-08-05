import Foundation
import Darwin

public final class NetworkMetricProvider: MetricProvider, @unchecked Sendable {
    private struct InterfaceState {
        let name: String
        let bytesIn: UInt64
        let bytesOut: UInt64
        let ipAddress: String
        let isWifi: Bool
        let isEthernet: Bool
    }
    
    private var prevInterfaces: [String: (bytesIn: UInt64, bytesOut: UInt64)] = [:]
    private var prevTime: Date?
    private let lock = NSLock()
    
    public init() {}
    
    public func collect(includeLoopback: Bool = false) async throws -> NetworkSnapshot {
        return lock.withLock {
            let now = Date()
        var ifap: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifap) == 0, let first = ifap else {
            return NetworkSnapshot(
                primaryInterfaceName: "None",
                activeInterfaces: [],
                totalDownloadSpeed: 0,
                totalUploadSpeed: 0,
                totalBytesReceived: 0,
                totalBytesSent: 0,
                isConnected: false
            )
        }
        defer { freeifaddrs(ifap) }
        
        var currentStates: [String: InterfaceState] = [:]
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        
        while let curr = ptr {
            let name = String(cString: curr.pointee.ifa_name)
            let flags = Int32(curr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            
            if isUp && (includeLoopback || !isLoopback) {
                var ipAddress = ""
                if let addr = curr.pointee.ifa_addr {
                    let family = addr.pointee.sa_family
                    if family == UInt8(AF_INET) {
                        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                        addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { sin in
                            var addr4 = sin.pointee.sin_addr
                            if inet_ntop(AF_INET, &addr4, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil {
                                ipAddress = String(cString: buffer)
                            }
                        }
                    }
                }
                
                if let data = curr.pointee.ifa_data {
                    let ifData = data.assumingMemoryBound(to: if_data.self).pointee
                    let bytesIn = UInt64(ifData.ifi_ibytes)
                    let bytesOut = UInt64(ifData.ifi_obytes)
                    
                    if bytesIn > 0 || bytesOut > 0 || !ipAddress.isEmpty {
                        let isWifi = name.hasPrefix("en") && (name == "en0" || name == "en1")
                        let isEthernet = name.hasPrefix("en") && !isWifi
                        
                        let existing = currentStates[name]
                        let finalIP = !ipAddress.isEmpty ? ipAddress : (existing?.ipAddress ?? "")
                        
                        currentStates[name] = InterfaceState(
                            name: name,
                            bytesIn: bytesIn,
                            bytesOut: bytesOut,
                            ipAddress: finalIP,
                            isWifi: isWifi,
                            isEthernet: isEthernet
                        )
                    }
                }
            }
            ptr = curr.pointee.ifa_next
        }
        
        var snapshots: [NetworkInterfaceSnapshot] = []
        var totalDlSpeed: Double = 0
        var totalUlSpeed: Double = 0
        var totalRxBytes: UInt64 = 0
        var totalTxBytes: UInt64 = 0
        var primaryName = "en0"
        
        let deltaTime = prevTime != nil ? now.timeIntervalSince(prevTime!) : 0.0
        
        for (name, state) in currentStates {
            let prev = prevInterfaces[name]
            var dlSpeed: Double = 0
            var ulSpeed: Double = 0
            
            if let prev = prev, deltaTime > 0 {
                let dlDelta = Double(state.bytesIn >= prev.bytesIn ? state.bytesIn - prev.bytesIn : 0)
                let ulDelta = Double(state.bytesOut >= prev.bytesOut ? state.bytesOut - prev.bytesOut : 0)
                dlSpeed = dlDelta / deltaTime
                ulSpeed = ulDelta / deltaTime
            }
            
            totalRxBytes += state.bytesIn
            totalTxBytes += state.bytesOut
            totalDlSpeed += dlSpeed
            totalUlSpeed += ulSpeed
            
            if !state.ipAddress.isEmpty && state.ipAddress != "127.0.0.1" {
                primaryName = name
            }
            
            snapshots.append(
                NetworkInterfaceSnapshot(
                    interfaceName: name,
                    ipAddress: state.ipAddress,
                    isWifi: state.isWifi,
                    isEthernet: state.isEthernet,
                    downloadSpeedBytesPerSec: dlSpeed,
                    uploadSpeedBytesPerSec: ulSpeed,
                    totalBytesReceived: state.bytesIn,
                    totalBytesSent: state.bytesOut
                )
            )
            
            prevInterfaces[name] = (bytesIn: state.bytesIn, bytesOut: state.bytesOut)
        }
        
        prevTime = now
        
        snapshots.sort { $0.downloadSpeedBytesPerSec + $0.uploadSpeedBytesPerSec > $1.downloadSpeedBytesPerSec + $1.uploadSpeedBytesPerSec }
        
        return NetworkSnapshot(
            timestamp: now,
            primaryInterfaceName: primaryName,
            activeInterfaces: snapshots,
            totalDownloadSpeed: totalDlSpeed,
            totalUploadSpeed: totalUlSpeed,
            totalBytesReceived: totalRxBytes,
            totalBytesSent: totalTxBytes,
            isConnected: !snapshots.isEmpty
        )
        }
    }
    
    public func collect() async throws -> NetworkSnapshot {
        return try await collect(includeLoopback: false)
    }
}
