import SwiftUI

public struct SystemMaintenanceView: View {
    @StateObject private var tuneup = SystemMaintenanceService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GhostTheme.mint.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .shadow(color: GhostTheme.mint, radius: 12)
                        
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 38))
                            .foregroundColor(GhostTheme.mint)
                    }
                    
                    Text("macOS System Deep Tuneup")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("1-Click execution of Apple internal maintenance scripts, DNS cache flushes, LaunchServices rebuilds, and RAM purges.")
                        .font(.system(size: 13))
                        .foregroundColor(GhostTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                
                // Master Action Card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SYSTEM MAINTENANCE STATUS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.cyan)
                        Text(tuneup.statusMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    
                    Button(action: { tuneup.runFullTuneup() }) {
                        HStack(spacing: 6) {
                            if tuneup.isRunning {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "play.fill")
                            }
                            Text(tuneup.isRunning ? "Tuning Up..." : "RUN FULL TUNEUP NOW")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(tuneup.isRunning ? Color.white.opacity(0.1) : GhostTheme.mint)
                        .foregroundColor(tuneup.isRunning ? .white : .black)
                        .cornerRadius(10)
                        .shadow(color: GhostTheme.mint.opacity(0.5), radius: 8)
                    }
                    .buttonStyle(.plain)
                    .disabled(tuneup.isRunning)
                }
                .padding(20)
                .cyberCardStyle(glowing: true)
                
                // Maintenance Tasks Log List
                VStack(alignment: .leading, spacing: 14) {
                    Text("SYSTEM MAINTENANCE TASKS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    VStack(spacing: 10) {
                        taskRow(title: "Flush DNS Resolver Cache", desc: "Fixes sluggish browsing and domain lookup issues", icon: "network")
                        taskRow(title: "Purge System RAM & Inactive Memory", desc: "Frees up swapped memory back to system pool", icon: "memorychip")
                        taskRow(title: "Rebuild LaunchServices Database", desc: "Fixes broken 'Open With' menus and duplicate app icons", icon: "gearshape.2.fill")
                        taskRow(title: "Run Apple Periodic Maintenance", desc: "Executes native macOS daily, weekly, & monthly system scripts", icon: "terminal.fill")
                    }
                }
                .padding(20)
                .cyberCardStyle()
            }
            .padding(24)
        }
        .background(GhostTheme.bgDark)
    }
    
    private func taskRow(title: String, desc: String, icon: String) -> some View {
        let status = tuneup.taskLogs.first(where: { $0.name == title })?.status ?? "Ready"
        
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(GhostTheme.mint)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundColor(GhostTheme.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                if status == "Running" {
                    ProgressView().controlSize(.small)
                } else if status == "Completed" {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(GhostTheme.mint)
                }
                Text(status)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(status == "Completed" ? GhostTheme.mint : GhostTheme.textSecondary)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}
