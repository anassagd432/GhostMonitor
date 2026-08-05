import Foundation
import IOKit
import IOKit.usb
import AppKit
import UserNotifications

public struct USBDevice: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let vendorID: String
    public let productID: String
    public let deviceClass: String
    public let connectedAt: Date
    public var isTrusted: Bool
}

@MainActor
public class USBGuardService: ObservableObject {
    public static let shared = USBGuardService()
    
    @Published public private(set) var connectedDevices: [USBDevice] = []
    @Published public private(set) var alertHistory: [USBDevice] = []
    @Published public var isGuardActive: Bool = false {
        didSet { isGuardActive ? startWatching() : stopWatching() }
    }
    
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    private var notifyPort: IONotificationPortRef?
    private var trustedIDs: Set<String> = []
    private let defaultsKey = "GhostMonitor_TrustedUSBDevices"
    
    private init() {
        trustedIDs = Set(UserDefaults.standard.stringArray(forKey: defaultsKey) ?? [])
        scanCurrentDevices()
    }
    
    // MARK: - Scan existing devices on launch
    
    private func scanCurrentDevices() {
        Task.detached {
            let devices = Self.fetchConnectedDevices()
            await MainActor.run { self.connectedDevices = devices }
        }
    }
    
    nonisolated static func fetchConnectedDevices() -> [USBDevice] {
        var devices: [USBDevice] = []
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iter) == KERN_SUCCESS else {
            return []
        }
        defer { IOObjectRelease(iter) }
        
        var service = IOIteratorNext(iter)
        while service != 0 {
            if let device = extractDevice(from: service) {
                devices.append(device)
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iter)
        }
        return devices
    }
    
    nonisolated private static func extractDevice(from service: io_object_t) -> USBDevice? {
        func prop(_ key: String) -> String {
            let val = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)
            if let n = val?.takeRetainedValue() as? Int { return String(format: "0x%04X", n) }
            if let s = val?.takeRetainedValue() as? String { return s }
            return "Unknown"
        }
        
        let name = prop(kUSBProductString)
        let vendor = prop(kUSBVendorID)
        let product = prop(kUSBProductID)
        let classCode = prop("bDeviceClass")
        
        guard name != "Unknown" || vendor != "Unknown" else { return nil }
        
        let deviceClass: String
        if let code = Int(classCode, radix: 16) {
            switch code {
            case 0x00: deviceClass = "Composite"
            case 0x03: deviceClass = "HID / Input Device"
            case 0x08: deviceClass = "Storage"
            case 0x09: deviceClass = "Hub"
            case 0x0E: deviceClass = "Video"
            case 0x02, 0x0A: deviceClass = "Network"
            case 0xE0: deviceClass = "Wireless"
            default: deviceClass = "Other (0x\(String(format: "%02X", code)))"
            }
        } else {
            deviceClass = "Unknown"
        }
        
        let deviceID = "\(vendor):\(product)"
        return USBDevice(
            id: deviceID + UUID().uuidString,
            name: name,
            vendorID: vendor,
            productID: product,
            deviceClass: deviceClass,
            connectedAt: Date(),
            isTrusted: false
        )
    }
    
    // MARK: - IOKit Watching
    
    public func startWatching() {
        notifyPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let port = notifyPort else { return }
        IONotificationPortSetDispatchQueue(port, DispatchQueue.global(qos: .background))
        
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
        
        // Device connected
        var selfPtr = Unmanaged.passUnretained(self).toOpaque()
        IOServiceAddMatchingNotification(
            port,
            kIOMatchedNotification,
            matchingDict.copy() as! CFDictionary,
            { context, iterator in
                guard let ctx = context else { return }
                let service = Unmanaged<USBGuardService>.fromOpaque(ctx).takeUnretainedValue()
                Task { @MainActor in service.handleDeviceConnected(iterator: iterator) }
            },
            &selfPtr,
            &addedIterator
        )
        drainIterator(addedIterator)
        
        // Device disconnected
        IOServiceAddMatchingNotification(
            port,
            kIOTerminatedNotification,
            matchingDict.copy() as! CFDictionary,
            { context, iterator in
                guard let ctx = context else { return }
                let service = Unmanaged<USBGuardService>.fromOpaque(ctx).takeUnretainedValue()
                Task { @MainActor in service.handleDeviceRemoved(iterator: iterator) }
            },
            &selfPtr,
            &removedIterator
        )
        drainIterator(removedIterator)
    }
    
    public func stopWatching() {
        if addedIterator != 0 { IOObjectRelease(addedIterator); addedIterator = 0 }
        if removedIterator != 0 { IOObjectRelease(removedIterator); removedIterator = 0 }
        if let port = notifyPort { IONotificationPortDestroy(port); notifyPort = nil }
    }
    
    private func drainIterator(_ iterator: io_iterator_t) {
        var service = IOIteratorNext(iterator)
        while service != 0 { IOObjectRelease(service); service = IOIteratorNext(iterator) }
    }
    
    private func handleDeviceConnected(iterator: io_iterator_t) {
        var service = IOIteratorNext(iterator)
        while service != 0 {
            if let device = Self.extractDevice(from: service) {
                var d = device
                d = USBDevice(id: d.id, name: d.name, vendorID: d.vendorID,
                              productID: d.productID, deviceClass: d.deviceClass,
                              connectedAt: d.connectedAt, isTrusted: trustedIDs.contains("\(d.vendorID):\(d.productID)"))
                connectedDevices.append(d)
                if !d.isTrusted {
                    alertHistory.insert(d, at: 0)
                    sendNotification(for: d)
                }
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
    }
    
    private func handleDeviceRemoved(iterator: io_iterator_t) {
        drainIterator(iterator)
        Task.detached {
            let current = Self.fetchConnectedDevices()
            await MainActor.run { self.connectedDevices = current }
        }
    }
    
    // MARK: - Trust
    
    public func trustDevice(_ device: USBDevice) {
        let key = "\(device.vendorID):\(device.productID)"
        trustedIDs.insert(key)
        UserDefaults.standard.set(Array(trustedIDs), forKey: defaultsKey)
        if let idx = connectedDevices.firstIndex(where: { $0.id == device.id }) {
            connectedDevices[idx] = USBDevice(
                id: device.id, name: device.name, vendorID: device.vendorID,
                productID: device.productID, deviceClass: device.deviceClass,
                connectedAt: device.connectedAt, isTrusted: true
            )
        }
    }
    
    // MARK: - Notification
    
    public func clearAlertHistory() {
        alertHistory.removeAll()
    }
    
    private func sendNotification(for device: USBDevice) {
        let content = UNMutableNotificationContent()
        content.title = "New USB Device Connected"
        content.body = "\(device.name) (\(device.deviceClass)) — Tap to review in Ghost Monitor."
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }
}
