import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = SettingsService.shared
    @ObservedObject var coordinator: MonitoringCoordinator = .shared
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 20) {
                
                // Section 1: Monitoring & Performance Preferences
                sectionCard(title: "Monitoring & Sampling", systemImage: "timer") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Refresh Interval:")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Menu {
                                Button("1 second") { settings.refreshIntervalSeconds = 1.0 }
                                Button("2 seconds (Recommended)") { settings.refreshIntervalSeconds = 2.0 }
                                Button("5 seconds") { settings.refreshIntervalSeconds = 5.0 }
                                Button("10 seconds") { settings.refreshIntervalSeconds = 10.0 }
                            } label: {
                                Text("\(Int(settings.refreshIntervalSeconds)) seconds")
                            }
                            .menuStyle(.borderlessButton)
                            .frame(width: 200)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Chart History Duration:")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Picker("", selection: $settings.historyWindow) {
                                ForEach(HistoryWindow.allCases) { win in
                                    Text(win.label).tag(win)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        
                        Divider()
                        
                        Toggle("Include Loopback Traffic in Network Totals", isOn: $settings.includeLoopback)
                            .font(.system(size: 12))
                        
                        Toggle("Show System Processes in Process List", isOn: $settings.showSystemProcesses)
                            .font(.system(size: 12))
                        
                        Toggle("Reduce Interface Motion & Animations", isOn: $settings.reduceMotion)
                            .font(.system(size: 12))
                    }
                }
                
                // Section 2: Menu Bar Integration
                sectionCard(title: "Menu Bar Integration", systemImage: "menubar.arrow.up.rectangle") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable Menu Bar Top Status Display", isOn: $settings.enableMenuBarExtra)
                            .font(.system(size: 12, weight: .semibold))
                        
                        if settings.enableMenuBarExtra {
                            Divider()
                            
                            Text("Top Bar Displayed Metrics:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 16) {
                                Toggle("CPU %", isOn: $settings.showCpuInMenuBar)
                                Toggle("RAM %", isOn: $settings.showRamInMenuBar)
                                Toggle("SSD %", isOn: $settings.showSsdInMenuBar)
                                Toggle("Battery %", isOn: $settings.showBatteryInMenuBar)
                                Toggle("Temp", isOn: $settings.showThermalInMenuBar)
                            }
                            .font(.system(size: 11))
                        }
                        
                        Divider()
                        
                        Button("Toggle Floating Performance HUD") {
                            HUDWindowController.shared.toggleHUD()
                        }
                    }
                }
                
                // Section 3: Warning Thresholds
                sectionCard(title: "Warning Thresholds", systemImage: "exclamationmark.triangle") {
                    VStack(alignment: .leading, spacing: 12) {
                        thresholdSlider(
                            label: "CPU Warning Threshold",
                            value: $settings.thresholds.cpuWarningPercentage,
                            range: 50...95,
                            unit: "%"
                        )
                        thresholdSlider(
                            label: "Memory Warning Threshold",
                            value: $settings.thresholds.memoryWarningPercentage,
                            range: 60...98,
                            unit: "%"
                        )
                        thresholdSlider(
                            label: "Storage Warning Threshold",
                            value: $settings.thresholds.storageWarningPercentage,
                            range: 70...98,
                            unit: "%"
                        )
                    }
                }
                
                // Section 4: Advanced Sensors Mode
                sectionCard(title: "Advanced Sensor Mode", systemImage: "cpu") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable Advanced Sensor Mode (Disabled by default)", isOn: $settings.advancedSensorMode)
                            .font(.system(size: 12, weight: .semibold))
                        
                        Text("App Store-safe mode is currently active. Advanced sensor mode operates without root privileges and fails safely if proprietary SMC temperature keys are restricted.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section: God Mode Utilities
                sectionCard(title: "God Mode Utilities", systemImage: "bolt.shield.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("CrossDrop Server Port:")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            TextField("8080", value: $settings.crossDropPort, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Battery Charge Limit:")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Picker("", selection: $settings.batteryLimitPercentage) {
                                Text("60%").tag(60)
                                Text("80%").tag(80)
                                Text("90%").tag(90)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        }
                    }
                }
                
                // Section 5: Diagnostics & System Export
                sectionCard(title: "Diagnostics & System Export", systemImage: "square.and.arrow.up") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export System Diagnostics Report")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Generate a JSON diagnostic report of local hardware stats and recent warnings.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Export JSON...") {
                            DiagnosticsExporter.exportReport(coordinator: coordinator)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // Section 6: Privacy Guarantee & Reset
                sectionCard(title: "Privacy & Reset", systemImage: "lock.shield") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("100% On-Device Privacy Guarantee")
                                    .font(.system(size: 12, weight: .bold))
                                Text("All system monitoring data remains on this Mac. No telemetry, cloud backends, analytics, or external API calls.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Button("Reset All Settings to Defaults") {
                                settings.resetToDefaults()
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func sectionCard<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.cyan)
            
            content()
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
    
    private func thresholdSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("\(Int(value.wrappedValue))\(unit)")
                    .font(.system(size: 12, weight: .bold))
            }
            Slider(value: value, in: range, step: 1.0)
        }
    }
}
