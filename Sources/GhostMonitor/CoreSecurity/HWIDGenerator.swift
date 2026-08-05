import Foundation
import IOKit
import CryptoKit

public struct HWIDGenerator {
    
    /// Generates a unique, immutable Hardware ID (HWID) for the current Mac.
    /// Combines the Logic Board Serial Number and a salt, then hashes it.
    public static func generate() -> String {
        let serial = getMacSerialNumber() ?? "UNKNOWN_SERIAL"
        let salt = "GhostM_DRM_Salt_99_!@"
        
        let rawString = "\(serial)-\(salt)"
        
        // Hash it so the raw serial is never stored or transmitted directly
        let hash = SHA256.hash(data: Data(rawString.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Format it nicely: GHOST-XXXX-XXXX-XXXX-XXXX
        let prefix = "GHOST-"
        let index = hashString.index(hashString.startIndex, offsetBy: 16)
        let shortHash = String(hashString[..<index]).uppercased()
        
        let chunked = shortHash.enumerated().reduce(into: "") { result, pair in
            if pair.offset > 0 && pair.offset % 4 == 0 { result += "-" }
            result += String(pair.element)
        }
        
        return prefix + chunked
    }
    
    /// Fetches the hardware serial number using IOKit
    private static func getMacSerialNumber() -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard platformExpert != 0 else { return nil }
        
        defer { IOObjectRelease(platformExpert) }
        
        guard let serialNumberAsCFString = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformSerialNumberKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeUnretainedValue() as? String else {
            return nil
        }
        
        return serialNumberAsCFString
    }
}
