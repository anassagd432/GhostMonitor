import SwiftUI

public struct SpyCatcherView: View {
    @StateObject private var scanner = SpyCatcherService.shared
    @State private var isTargeted = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(scanner.isYaraInstalled ? .green : .blue)
            
            VStack(spacing: 8) {
                Text("The Spy-Catcher")
                    .font(.title.bold())
                
                Text("Drag & Drop an app to check if it's safe or secretly spying on you.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !scanner.isYaraInstalled {
                installView
            } else {
                scanView
            }
            
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            scanner.checkInstallation()
        }
    }
    
    private var installView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Setup Required: YARA Scanner")
                    .font(.headline)
                
                Text("To deeply scan apps for hidden bad stuff, Ghost Monitor uses a free tool called **YARA**. Security experts and good hackers around the world use YARA to catch the bad guys! 🦸‍♂️")
                    .font(.subheadline)
                
                Text("When you click Install, Ghost Monitor will safely download YARA to your Mac so it can protect you.")
                    .font(.subheadline)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            if scanner.isInstalling {
                ProgressView(scanner.installProgress)
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                Button(action: {
                    scanner.installYaraEngine()
                }) {
                    Text("Install YARA Scanner")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding(.top, 20)
    }
    
    private var scanView: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(isTargeted ? Color.green : Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 3, dash: [10]))
                    .background(isTargeted ? Color.green.opacity(0.1) : Color.clear)
                    .frame(height: 150)
                
                VStack {
                    Image(systemName: "square.and.arrow.down")
                        .font(.largeTitle)
                        .foregroundColor(isTargeted ? .green : .secondary)
                    Text(scanner.scanStatus)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.top, 5)
                }
            }
            .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers in
                guard let provider = providers.first else { return false }
                
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    guard let data = item as? Data,
                          let urlString = String(data: data, encoding: .utf8),
                          let url = URL(string: urlString) else { return }
                    
                    DispatchQueue.main.async {
                        scanner.scanApp(at: url)
                    }
                }
                return true
            }
            
            if scanner.isScanning {
                ProgressView("Analyzing app behavior...")
                    .padding()
            } else if !scanner.scanResults.isEmpty {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(scanner.scanResults) { result in
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(result.title)
                                        .font(.headline)
                                        .foregroundColor(result.isThreat ? .red : .green)
                                    Text(result.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: result.isThreat ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                                    .font(.title2)
                                    .foregroundColor(result.isThreat ? .red : .green)
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(.top, 20)
    }
}
