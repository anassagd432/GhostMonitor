import Foundation

public enum TimeFormatter {
    public static func formatUptime(_ seconds: TimeInterval) -> String {
        guard seconds >= 0 else { return "0s" }
        let totalSeconds = Int(seconds)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        var result: [String] = []
        if days > 0 { result.append("\(days)d") }
        if hours > 0 || days > 0 { result.append("\(hours)h") }
        if minutes > 0 || hours > 0 || days > 0 { result.append("\(minutes)m") }
        result.append("\(secs)s")
        
        return result.joined(separator: " ")
    }
    
    public static func formatShortDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
