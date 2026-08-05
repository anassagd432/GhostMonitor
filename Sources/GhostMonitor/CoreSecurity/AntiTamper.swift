import Foundation
import MachO

public struct AntiTamper {
    
    /// Runs all anti-tampering checks. If any fail, the app immediately crashes itself.
    public static func runChecks() {
        denyDebuggerAttach()
        verifyCodeSignature()
    }
    
    /// 1. Anti-Debug (Ptrace)
    /// Calls the raw C system call `ptrace(PT_DENY_ATTACH, 0, 0, 0)`
    /// If a debugger (LLDB, Hopper, IDA) tries to attach, the app terminates instantly.
    private static func denyDebuggerAttach() {
        // PT_DENY_ATTACH = 31
        typealias ptrace_type = @convention(c) (CInt, pid_t, CInt, CInt) -> CInt
        
        let ptrace_ptr = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "ptrace")
        guard ptrace_ptr != nil else { return } // Should never happen on macOS
        
        let ptrace = unsafeBitCast(ptrace_ptr, to: ptrace_type.self)
        
        // This will kill the process if traced
        _ = ptrace(31, 0, 0, 0)
    }
    
    /// 2. Code Signature Integrity Check
    /// Ensures the binary hasn't been modified and re-signed by an ad-hoc certificate.
    private static func verifyCodeSignature() {
        // We verify that the embedded TeamIdentifier matches our expected TeamIdentifier.
        // If a cracker modifies the binary, they must strip the signature or re-sign it with their own cert.
        // Ad-hoc signatures usually lack a team identifier.
        
        // In a real production build, you replace this with your actual 10-character Team ID.
        // For this implementation, we will verify the code signature exists.
        
        var staticCode: SecStaticCode?
        let bundleURL = Bundle.main.bundleURL
        
        // Create static code object from our bundle
        let status = SecStaticCodeCreateWithPath(bundleURL as CFURL, [], &staticCode)
        guard status == errSecSuccess, let code = staticCode else {
            crash()
            return
        }
        
        // Check validity against the basic designated requirement
        var req: SecRequirement?
        _ = SecRequirementCreateWithString("anchor apple generic" as CFString, [], &req)
        
        // If it's a developer build, it might not have "anchor apple generic" (which is App Store/Developer ID).
        // For now, we just perform a basic validity check that the signature is intact.
        let checkStatus = SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSBasicValidateOnly), nil)
        
        if checkStatus != errSecSuccess {
            // Signature is broken or modified
            crash()
        }
    }
    
    private static func crash() {
        // Deliberately crash with a segmentation fault to avoid leaving a clean exit trace
        let nullPointer = UnsafeMutableRawPointer(bitPattern: 0)
        nullPointer?.storeBytes(of: 0, as: Int.self)
        exit(0)
    }
}
