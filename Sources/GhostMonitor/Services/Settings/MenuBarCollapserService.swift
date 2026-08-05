import Foundation
import AppKit
import SwiftUI

public enum MenuBarItemVisibility: String, Codable, CaseIterable, Sendable {
    case alwaysVisible = "Always Visible"
    case hiddenInOverflow = "Hidden in Overflow"
    case alwaysHidden = "Always Hidden"
}

public struct MenuBarItemConfig: Identifiable, Codable, Sendable {
    public var id: String { name }
    public let name: String
    public var visibility: MenuBarItemVisibility
}

@MainActor
public final class MenuBarCollapserService: ObservableObject {
    public static let shared = MenuBarCollapserService()
    
    @Published public var isCollapserEnabled: Bool = true {
        didSet { UserDefaults.standard.set(isCollapserEnabled, forKey: "collapser_enabled") }
    }
    @Published public var isOverflowExpanded: Bool = false
    
    @Published public var itemConfigs: [MenuBarItemConfig] = [
        MenuBarItemConfig(name: "Ghost Monitor", visibility: .alwaysVisible),
        MenuBarItemConfig(name: "Wi-Fi & Network", visibility: .alwaysVisible),
        MenuBarItemConfig(name: "Battery Status", visibility: .alwaysVisible),
        MenuBarItemConfig(name: "Spotlight & Siri", visibility: .alwaysVisible),
        MenuBarItemConfig(name: "Clock & Date", visibility: .alwaysVisible),
        MenuBarItemConfig(name: "Bluetooth Devices", visibility: .hiddenInOverflow),
        MenuBarItemConfig(name: "Focus & Do Not Disturb", visibility: .hiddenInOverflow),
        MenuBarItemConfig(name: "Time Machine Backup", visibility: .hiddenInOverflow),
        MenuBarItemConfig(name: "Third-Party Utilities", visibility: .alwaysHidden)
    ]
    
    private init() {
        self.isCollapserEnabled = UserDefaults.standard.object(forKey: "collapser_enabled") as? Bool ?? true
    }
    
    public func toggleOverflow() {
        isOverflowExpanded.toggle()
    }
    
    public func updateVisibility(forName name: String, to visibility: MenuBarItemVisibility) {
        if let idx = itemConfigs.firstIndex(where: { $0.name == name }) {
            itemConfigs[idx].visibility = visibility
        }
    }
}
