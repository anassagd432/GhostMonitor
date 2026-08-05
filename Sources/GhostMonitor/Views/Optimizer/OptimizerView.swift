import SwiftUI

public struct OptimizerView: View {
    @StateObject private var optimizer = OptimizerService()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PC Optimizer")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Manage startup items and reclaim system memory.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: {
                    Task {
                        await optimizer.freeMemory()
                    }
                }) {
                    HStack {
                        Image(systemName: "memorychip")
                        Text("Free RAM")
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    Task {
                        await optimizer.scan()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(.degrees(optimizer.isScanning ? 360 : 0))
                            .animation(optimizer.isScanning ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: optimizer.isScanning)
                        Text(optimizer.isScanning ? "Scanning..." : "Scan Startup")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(optimizer.isScanning)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // App List
            List {
                if optimizer.items.isEmpty {
                    if optimizer.isScanning {
                        HStack {
                            Spacer()
                            ProgressView("Scanning Startup Items...")
                                .padding()
                            Spacer()
                        }
                    } else {
                        HStack {
                            Spacer()
                            Text("Click 'Scan Startup' to find background services.")
                                .foregroundColor(.secondary)
                                .padding()
                            Spacer()
                        }
                    }
                } else {
                    let grouped = Dictionary(grouping: optimizer.items, by: { $0.type })
                    
                    ForEach(StartupItem.ItemType.allCases, id: \.self) { type in
                        if let typeItems = grouped[type] {
                            Section(header: Text(type.rawValue).font(.subheadline).fontWeight(.semibold)) {
                                ForEach(typeItems) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.system(size: 13, weight: .medium))
                                            Text(item.path.path)
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: Binding(
                                            get: { item.isEnabled },
                                            set: { _ in
                                                Task {
                                                    await optimizer.toggleItem(item)
                                                }
                                            }
                                        ))
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension StartupItem.ItemType: CaseIterable {
    public static var allCases: [StartupItem.ItemType] = [.userAgent, .systemAgent, .systemDaemon]
}
