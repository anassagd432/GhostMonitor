import SwiftUI

public struct SnipperView: View {
    @StateObject private var service = SnipperService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Smart Snipper")
                    .font(.title2.bold())
                
                Text("Take a screenshot and instantly extract any text inside it using Apple's Vision AI.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                service.startSnip()
            }) {
                HStack {
                    if service.isExtracting {
                        ProgressView().controlSize(.small)
                            .padding(.trailing, 8)
                        Text("Extracting Text...")
                    } else {
                        Image(systemName: "camera.viewfinder")
                        Text("Trigger Smart Snip")
                    }
                }
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(service.isExtracting)
            
            if !service.lastExtractedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Extracted Text (Copied to Clipboard):")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    ScrollView {
                        Text(service.lastExtractedText)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: service.lastExtractedText.isEmpty)
        .animation(.easeInOut, value: service.isExtracting)
    }
}
