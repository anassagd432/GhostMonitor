import Foundation

public enum ByteFormatter {
    public static func formatBytes(_ bytes: Int64, decimalPlaces: Int = 1) -> String {
        guard bytes >= 0 else { return "0 B" }
        let doubleBytes = Double(bytes)
        
        let kilobyte: Double = 1024
        let megabyte = kilobyte * 1024
        let gigabyte = megabyte * 1024
        let terabyte = gigabyte * 1024
        
        if doubleBytes >= terabyte {
            return String(format: "%.\(decimalPlaces)f TB", doubleBytes / terabyte)
        } else if doubleBytes >= gigabyte {
            return String(format: "%.\(decimalPlaces)f GB", doubleBytes / gigabyte)
        } else if doubleBytes >= megabyte {
            return String(format: "%.\(decimalPlaces)f MB", doubleBytes / megabyte)
        } else if doubleBytes >= kilobyte {
            return String(format: "%.\(decimalPlaces)f KB", doubleBytes / kilobyte)
        } else {
            return "\(bytes) B"
        }
    }
    
    public static func formatSpeed(_ bytesPerSecond: Double, decimalPlaces: Int = 1) -> String {
        guard bytesPerSecond >= 0 else { return "0 B/s" }
        
        let kilobyte: Double = 1024
        let megabyte = kilobyte * 1024
        let gigabyte = megabyte * 1024
        
        if bytesPerSecond >= gigabyte {
            return String(format: "%.\(decimalPlaces)f GB/s", bytesPerSecond / gigabyte)
        } else if bytesPerSecond >= megabyte {
            return String(format: "%.\(decimalPlaces)f MB/s", bytesPerSecond / megabyte)
        } else if bytesPerSecond >= kilobyte {
            return String(format: "%.\(decimalPlaces)f KB/s", bytesPerSecond / kilobyte)
        } else {
            return String(format: "%.0f B/s", bytesPerSecond)
        }
    }
}
