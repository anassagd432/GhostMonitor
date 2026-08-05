import Foundation
import AppKit
@preconcurrency import Vision

@MainActor
public class SnipperService: ObservableObject {
    public static let shared = SnipperService()
    
    @Published public var isExtracting: Bool = false
    @Published public var lastExtractedText: String = ""
    
    private init() {}
    
    public func startSnip() {
        // Run screencapture in interactive mode, saving to clipboard (-c)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-c"]
        
        do {
            try process.run()
            
            DispatchQueue.global().async {
                process.waitUntilExit()
                
                DispatchQueue.main.async {
                    if process.terminationStatus == 0 {
                        self.processClipboardImage()
                    }
                }
            }
        } catch {
            print("Failed to run screencapture: \(error)")
        }
    }
    
    private func processClipboardImage() {
        guard let pasteboardImage = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
              let cgImage = pasteboardImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }
        
        self.isExtracting = true
        self.lastExtractedText = ""
        
        // Use Vision framework for OCR
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            var extractedString = ""
            if let observations = request.results as? [VNRecognizedTextObservation] {
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                extractedString = recognizedStrings.joined(separator: "\n")
            }
            
            DispatchQueue.main.async {
                self.isExtracting = false
                self.lastExtractedText = extractedString
                
                // Save back to clipboard
                if !extractedString.isEmpty {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(extractedString, forType: .string)
                }
            }
        }
        
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform OCR: \(error)")
                DispatchQueue.main.async {
                    self.isExtracting = false
                }
            }
        }
    }
}
