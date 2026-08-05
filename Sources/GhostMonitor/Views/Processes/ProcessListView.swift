import SwiftUI
import AppKit

public struct ProcessListView: View {
    @StateObject var viewModel: ProcessListViewModel
    
    public init(viewModel: ProcessListViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? ProcessListViewModel())
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Search & Filter Bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search processes or PID...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: 320)
                
                Spacer()
                
                // Sort Field Picker
                HStack(spacing: 6) {
                    Text("Sort:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.sortField.rawValue)
                        .frame(width: 110)
                    
                    Button {
                        viewModel.isAscending.toggle()
                    } label: {
                        Image(systemName: viewModel.isAscending ? "arrow.up" : "arrow.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Process Table
            Table(viewModel.filteredProcesses) {
                TableColumn("Process Name") { proc in
                    HStack(spacing: 8) {
                        if let path = proc.iconPath, !path.isEmpty {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                                .resizable()
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(proc.name)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                    }
                }
                .width(min: 180, ideal: 240)
                
                TableColumn("PID") { proc in
                    Text("\(proc.pid)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .width(60)
                
                TableColumn("CPU %") { proc in
                    Text(String(format: "%.1f%%", proc.cpuUsagePercentage))
                        .font(.system(size: 11, weight: proc.cpuUsagePercentage > 20 ? .bold : .regular, design: .monospaced))
                        .foregroundColor(proc.cpuUsagePercentage > 50 ? .red : (proc.cpuUsagePercentage > 20 ? .orange : .primary))
                }
                .width(80)
                
                TableColumn("Memory") { proc in
                    Text(ByteFormatter.formatBytes(proc.memoryBytes))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .width(90)
                
                TableColumn("User") { proc in
                    Text(proc.user)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .width(80)
                
                TableColumn("Runtime") { proc in
                    Text(TimeFormatter.formatShortDuration(proc.runtimeSeconds))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .width(80)
                
                TableColumn("Actions") { proc in
                    HStack(spacing: 6) {
                        Button {
                            viewModel.selectedProcess = proc
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .buttonStyle(.plain)
                        .help("Inspect Process")
                        
                        Button {
                            viewModel.promptQuit(process: proc, force: false)
                        } label: {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                        .help("Quit Process (SIGTERM)")
                        
                        Button {
                            viewModel.promptQuit(process: proc, force: true)
                        } label: {
                            Image(systemName: "xmark.octagon.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Force Quit Process (SIGKILL)")
                    }
                }
                .width(90)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
        }
        .sheet(item: $viewModel.selectedProcess) { proc in
            ProcessDetailModal(process: proc, viewModel: viewModel)
        }
        .confirmationDialog(
            "Confirm Process Termination",
            isPresented: $viewModel.showQuitDialog,
            titleVisibility: .visible
        ) {
            if viewModel.processToTerminate != nil {
                Button(viewModel.isForceQuitConfirmation ? "Force Quit (SIGKILL)" : "Quit (SIGTERM)", role: .destructive) {
                    viewModel.confirmQuit()
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.processToTerminate = nil
            }
        } message: {
            if let proc = viewModel.processToTerminate {
                Text("Are you sure you want to \(viewModel.isForceQuitConfirmation ? "force quit" : "quit") '\(proc.name)' (PID: \(proc.pid))?\nUnsaved changes in this application may be lost.")
            }
        }
    }
}
