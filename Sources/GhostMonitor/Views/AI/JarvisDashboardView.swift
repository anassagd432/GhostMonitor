import SwiftUI

public struct JarvisDashboardView: View {
    @StateObject private var jarvis = OpenAIJarvisEngine.shared
    @StateObject private var voiceWake = JarvisVoiceWakeService.shared
    @StateObject private var monitor = MonitoringCoordinator.shared
    
    @State private var inputPrompt: String = ""
    @State private var arcRotation: Double = 0
    @State private var radarRotation: Double = 0
    @State private var audioLevel: CGFloat = 0.45
    @State private var isShowingApiKeyModal: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Dark Cyber Grid Background
            Color(red: 0.02, green: 0.04, blue: 0.08)
                .ignoresSafeArea()
            
            // Subtle Cyber HUD Background Grid overlay
            CyberBackgroundGrid()
                .opacity(0.15)
            
            VStack(spacing: 0) {
                // Top Telemetry Header Bar
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                
                // Main 3-Column Cyber Dashboard Layout
                GeometryReader { geo in
                    HStack(alignment: .top, spacing: 16) {
                        // Left Column: Telemetry & Markets
                        leftTelemetryColumn
                            .frame(width: max(220, geo.size.width * 0.22))
                        
                        // Center Column: Arc Reactor Core & Response Engine
                        centerArcReactorColumn
                            .frame(maxWidth: .infinity)
                        
                        // Right Column: Controls, Radar & Defense
                        rightControlsColumn
                            .frame(width: max(240, geo.size.width * 0.24))
                    }
                    .padding(16)
                }
                
                // Bottom Status Footer & Command Line Input
                bottomCommandFooter
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                arcRotation = 360
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                radarRotation = 360
            }
        }
        .sheet(isPresented: $isShowingApiKeyModal) {
            apiKeyModalView
        }
    }
    
    // MARK: - 1. Top Header Bar
    private var topHeaderBar: some View {
        HStack {
            Spacer()
            
            // Digital Clock Pill
            HStack(spacing: 10) {
                Text(Date().formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(GhostTheme.cyan)
                
                Text(Date().formatted(date: .complete, time: .omitted).uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(GhostTheme.cyan.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color(red: 0.03, green: 0.12, blue: 0.22).opacity(0.8))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(GhostTheme.cyan.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: GhostTheme.cyan.opacity(0.3), radius: 8)
            
            Spacer()
        }
    }
    
    // MARK: - 2. Left Column: Telemetry & Markets
    private var leftTelemetryColumn: some View {
        VStack(spacing: 12) {
            // Location Telemetry
            cyberBox(title: "LOCATION TELEMETRY") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SANT ANTONI DE PORTMANY / SPAIN")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                    
                    HStack {
                        Text("+28°C")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("FETCHING TELEMETRY")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(GhostTheme.textSecondary)
                    }
                }
            }
            
            // Asset Markets Live Feed
            cyberBox(title: "ASSET MARKETS // LIVE FEED") {
                VStack(spacing: 6) {
                    marketRow(symbol: "BTC", price: "$64,623", delta: "+0.7%", isPositive: true)
                    marketRow(symbol: "ETH", price: "$1,906", delta: "+2.0%", isPositive: true)
                    marketRow(symbol: "SOL", price: "$74.01", delta: "-0.0%", isPositive: false)
                }
            }
            
            // Orbital Target Times
            cyberBox(title: "ORBITAL TARGET TIMES") {
                VStack(spacing: 4) {
                    timezoneRow(city: "DUBAI [UAE]", time: "02:07")
                    timezoneRow(city: "MADRID [ESP]", time: "00:07")
                    timezoneRow(city: "CASABLANCA [MAR]", time: "23:07")
                }
            }
            
            // Audio Level DB Gauge
            cyberBox(title: "AUDIO INPUT LEVEL") {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<18, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(i < 12 ? GhostTheme.cyan : GhostTheme.magenta)
                            .frame(height: CGFloat(i * 3 + 4))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 50)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 3. Center Column: Arc Reactor Core & Response Engine
    private var centerArcReactorColumn: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Giant Rotating J.A.R.V.I.S Arc Reactor Core
            ZStack {
                // Outer Radial Ticks
                Circle()
                    .stroke(GhostTheme.cyan.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 8]))
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-arcRotation * 0.5))
                
                // Segmented Rotating Ring
                Circle()
                    .stroke(GhostTheme.cyan, style: StrokeStyle(lineWidth: 3, dash: [16, 12]))
                    .frame(width: 190, height: 190)
                    .rotationEffect(.degrees(arcRotation))
                    .shadow(color: GhostTheme.cyan, radius: 10)
                
                // Inner Dotted Circle
                Circle()
                    .stroke(GhostTheme.cyan.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [2, 6]))
                    .frame(width: 160, height: 160)
                
                // Central Glowing Core Text
                VStack(spacing: 2) {
                    Text("J.A.R.V.I.S.")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: GhostTheme.cyan, radius: 12)
                    
                    Text("OPENAI WHISPER & GPT-4o ENGINE")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan.opacity(0.8))
                }
            }
            
            // Status Mode Pills
            HStack(spacing: 8) {
                statusPill(title: "HERMES AGENT", isActive: true)
                statusPill(title: "OPENAI VOICE", isActive: true)
                statusPill(title: "LISTENING", isActive: voiceWake.isListening)
                statusPill(title: "SPEAKING", isActive: jarvis.isProcessing)
            }
            
            // Main Response Box
            VStack(spacing: 8) {
                Text("J.A.R.V.I.S.")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(GhostTheme.cyan)
                
                let lastMessage = jarvis.messages.last?.text ?? "\"Yes, sir? What do you need?\""
                Text(lastMessage.hasPrefix("\"") ? lastMessage : "\"\(lastMessage)\"")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.03, green: 0.09, blue: 0.16).opacity(0.9))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(GhostTheme.cyan.opacity(0.4), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            
            // Event Stream Terminal Log
            VStack(alignment: .leading, spacing: 4) {
                Text("SYS_LOG // EVENT STREAM")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(GhostTheme.cyan.opacity(0.7))
                
                Text("> [SYS] Apple Silicon Voice Isolation Mounted (26dB)")
                    .font(.system(size: 9, design: .monospaced)).foregroundColor(GhostTheme.textSecondary)
                Text("> [AI] OpenAI GPT-4o Realtime Gateway Online")
                    .font(.system(size: 9, design: .monospaced)).foregroundColor(GhostTheme.cyan)
                Text("> [AUDIO] Whisper Speech Engine Initialized")
                    .font(.system(size: 9, design: .monospaced)).foregroundColor(GhostTheme.mint)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.5))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - 4. Right Column: Controls, Radar & Defense
    private var rightControlsColumn: some View {
        VStack(spacing: 12) {
            // Settings / Refresh Actions
            cyberBox(title: "SETTINGS / REFRESH") {
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "mic.fill").foregroundColor(GhostTheme.cyan)
                        Text("VOICE STREAM").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $voiceWake.isVoiceWakeEnabled).toggleStyle(CyberToggleStyle()).frame(width: 36)
                    }
                    
                    Button(action: { isShowingApiKeyModal.toggle() }) {
                        HStack {
                            Image(systemName: "brain.head.profile").foregroundColor(GhostTheme.magenta)
                            Text("HERMES / OPENAI KEY").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Global Positioning Radar Scanner
            cyberBox(title: "GLOBAL POSITIONING") {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(GhostTheme.cyan.opacity(0.3), lineWidth: 1)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .stroke(GhostTheme.cyan.opacity(0.1), lineWidth: 1)
                            .frame(width: 40, height: 40)
                        
                        // Radar Sweep Line
                        Rectangle()
                            .fill(GhostTheme.cyan.opacity(0.5))
                            .frame(width: 35, height: 2)
                            .offset(x: 17.5)
                            .rotationEffect(.degrees(radarRotation))
                    }
                    
                    Text("38.9791° N, 1.3047° E")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(GhostTheme.cyan)
                }
            }
            
            // Active Missions
            cyberBox(title: "AGDI ACTIVE MISSIONS") {
                VStack(spacing: 4) {
                    missionRow(title: "AGDI CORE v2.4", status: "NOMINAL", color: GhostTheme.mint)
                    missionRow(title: "AGDI-DEV BUILDER", status: "ACTIVE", color: GhostTheme.cyan)
                    missionRow(title: "AGENCY M5 [SMB]", status: "DEPLOYED", color: GhostTheme.purple)
                }
            }
            
            // Cyber Defense & Traffic
            cyberBox(title: "CYBER DEFENSE & TRAFFIC") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEFCON 5 // SECURED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(GhostTheme.mint)
                    
                    HStack {
                        Text("↓ 4.8 MB/s").font(.system(size: 9, design: .monospaced)).foregroundColor(GhostTheme.textSecondary)
                        Spacer()
                        Text("↑ 1.4 MB/s").font(.system(size: 9, design: .monospaced)).foregroundColor(GhostTheme.textSecondary)
                    }
                    
                    // Traffic Bars
                    HStack(spacing: 2) {
                        ForEach(0..<10, id: \.self) { i in
                            Rectangle()
                                .fill(GhostTheme.cyan)
                                .frame(height: CGFloat([8, 12, 6, 14, 18, 10, 16, 12, 8, 15][i]))
                        }
                    }
                }
            }
            
            // Human Power Body System
            cyberBox(title: "SYSTEM NOMINAL") {
                HStack(spacing: 12) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 24))
                        .foregroundColor(GhostTheme.cyan)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("POWER 100%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(GhostTheme.mint)
                        Text("SYSTEM NOMINAL")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(GhostTheme.textSecondary)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - 5. Bottom Status Footer & Command Line Input
    private var bottomCommandFooter: some View {
        VStack(spacing: 6) {
            // Live Hardware Status Ticker Bar
            HStack(spacing: 20) {
                statusMetric(label: "CPU LOAD", value: "\(Int(monitor.cpu?.totalUsagePercentage ?? 19))%")
                statusMetric(label: "RAM USED", value: "\(Int(monitor.memory?.usedPercentage ?? 29))%")
                statusMetric(label: "CPU TEMP", value: "\(Int(monitor.battery?.temperatureCelsius ?? 39))°C")
                Spacer()
                statusMetric(label: "MIC HARDWARE", value: voiceWake.isListening ? "ONLINE" : "STANDBY", isMint: voiceWake.isListening)
            }
            .padding(.horizontal, 20)
            
            // Cyber Command Input Line
            HStack(spacing: 10) {
                Text(">_")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(GhostTheme.cyan)
                
                TextField("Ask Jarvis or invoke Hermes Agent command...", text: $inputPrompt)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white)
                    .onSubmit {
                        executePrompt()
                    }
                
                Button(action: { executePrompt() }) {
                    Text("EXECUTE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(GhostTheme.cyan)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(Color(red: 0.02, green: 0.06, blue: 0.12))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(GhostTheme.cyan.opacity(0.4), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    // MARK: - Helper Views
    private func executePrompt() {
        let trimmed = inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        inputPrompt = ""
        jarvis.sendMessage(trimmed)
    }
    
    private func cyberBox<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(GhostTheme.cyan.opacity(0.7))
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.03, green: 0.07, blue: 0.13).opacity(0.8))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(GhostTheme.cyan.opacity(0.2), lineWidth: 1))
    }
    
    private func marketRow(symbol: String, price: String, delta: String, isPositive: Bool) -> some View {
        HStack {
            Text(symbol).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.white)
            Spacer()
            Text(price).font(.system(size: 9, design: .monospaced)).foregroundColor(GhostTheme.textSecondary)
            Text(delta).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(isPositive ? GhostTheme.mint : Color.red)
        }
    }
    
    private func timezoneRow(city: String, time: String) -> some View {
        HStack {
            Text(city).font(.system(size: 8, design: .monospaced)).foregroundColor(GhostTheme.textSecondary)
            Spacer()
            Text(time).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(GhostTheme.mint)
        }
    }
    
    private func missionRow(title: String, status: String, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 4, height: 4)
            Text(title).font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundColor(.white)
            Spacer()
            Text(status).font(.system(size: 8, design: .monospaced)).foregroundColor(color)
        }
    }
    
    private func statusPill(title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? GhostTheme.cyan.opacity(0.2) : Color.white.opacity(0.04))
            .foregroundColor(isActive ? GhostTheme.cyan : GhostTheme.textSecondary)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isActive ? GhostTheme.cyan.opacity(0.5) : Color.clear, lineWidth: 1))
    }
    
    private func statusMetric(label: String, value: String, isMint: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 8, design: .monospaced)).foregroundColor(GhostTheme.textSecondary)
            Text(value).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(isMint ? GhostTheme.mint : GhostTheme.cyan)
        }
    }
    
    private var apiKeyModalView: some View {
        VStack(spacing: 16) {
            Text("JARVIS OpenAI API Key Configuration")
                .font(.headline)
            
            SecureField("sk-proj-...", text: $jarvis.openAIApiKey)
                .textFieldStyle(.roundedBorder)
            
            Picker("Model", selection: $jarvis.selectedModel) {
                Text("gpt-4o-mini").tag("gpt-4o-mini")
                Text("gpt-4o").tag("gpt-4o")
            }
            .pickerStyle(.segmented)
            
            Button("Save Configuration") {
                isShowingApiKeyModal = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(width: 380)
    }
}

struct CyberBackgroundGrid: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let step: CGFloat = 30
                for x in stride(from: 0, to: geo.size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for y in stride(from: 0, to: geo.size.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(GhostTheme.cyan, lineWidth: 0.5)
        }
    }
}
