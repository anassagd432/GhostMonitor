import SwiftUI
import CoreImage.CIFilterBuiltins

public struct CrossDropView: View {
    @StateObject private var service = CrossDropService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Cross-Drop")
                    .font(.title.bold())
                
                Text("AirDrop for Windows, Linux, and Android.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            if service.isRunning {
                VStack(spacing: 8) {
                    Text("Connect on your phone or PC:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Force port to string to avoid comma/dot formatting (e.g. 8,080)
                    Text("http://\(service.ipAddress):\(String(service.port))")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                        .textSelection(.enabled)
                        .contextMenu {
                            Button("Copy Link") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString("http://\(service.ipAddress):\(service.port)", forType: .string)
                            }
                        }
                    
                    if let qrImage = generateQRCode(from: "http://\(service.ipAddress):\(String(service.port))") {
                        Image(nsImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                    
                    Text("Type this URL or scan the QR code to drop files instantly.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            service.openFolder()
                        }) {
                            HStack {
                                Image(systemName: "folder")
                                Text("Open Received Files")
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            service.stopServer()
                        }) {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Stop Server")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .transition(.opacity)
            } else {
                Button(action: {
                    service.startServer()
                }) {
                    Text("Start Cross-Drop Server")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: service.isRunning)
    }
    
    private func generateQRCode(from string: String) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        guard let outputImage = filter.outputImage?.transformed(by: transform) else {
            return nil
        }
        
        let rep = NSCIImageRep(ciImage: outputImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}
