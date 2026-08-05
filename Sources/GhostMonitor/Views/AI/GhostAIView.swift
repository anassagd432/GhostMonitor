import SwiftUI

public struct GhostAIView: View {
    @StateObject private var ai = GhostAIService.shared
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("Ghost AI Assistant")
                    .font(.title2.bold())
                Spacer()
                Text("Local • Secure")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Chat Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(ai.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if ai.isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Ghost AI is thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.leading, 16)
                            .id("processing")
                        }
                        
                        if !ai.pendingActions.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(ai.pendingActions) { action in
                                    Button(action: {
                                        Task {
                                            await action.execute()
                                            // Optional: add a success message
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: action.icon)
                                            Text(action.title).fontWeight(.semibold)
                                            Spacer()
                                            Image(systemName: "arrow.right.circle.fill")
                                        }
                                        .padding()
                                        .background(
                                            LinearGradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.purple.opacity(0.4), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .id("actions")
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: ai.messages) { _ in
                    withAnimation {
                        if !ai.pendingActions.isEmpty {
                            proxy.scrollTo("actions", anchor: .bottom)
                        } else {
                            proxy.scrollTo(ai.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: ai.pendingActions.count) { _ in
                    withAnimation {
                        proxy.scrollTo("actions", anchor: .bottom)
                    }
                }
            }
            
            Divider()
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Ask Ghost to optimize or secure your Mac...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    .focused($isInputFocused)
                    .onSubmit {
                        submit()
                    }
                
                Button(action: submit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(inputText.isEmpty ? .secondary : .purple)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty || ai.isProcessing)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func submit() {
        let text = inputText
        inputText = ""
        Task {
            await ai.processInput(text)
        }
    }
}

fileprivate struct MessageBubble: View {
    let message: AIMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .cornerRadius(0, corners: [.bottomRight])
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .padding(8)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text(message.text)
                        .padding(12)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                        .cornerRadius(0, corners: [.bottomLeft])
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
}

// Helper to round specific corners in SwiftUI
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = NSBezierPath()
        
        let tr = corners.contains(.topRight) ? radius : 0
        let tl = corners.contains(.topLeft) ? radius : 0
        let br = corners.contains(.bottomRight) ? radius : 0
        let bl = corners.contains(.bottomLeft) ? radius : 0
        
        path.move(to: NSPoint(x: rect.minX + tl, y: rect.minY))
        path.line(to: NSPoint(x: rect.maxX - tr, y: rect.minY))
        path.appendArc(withCenter: NSPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: 270, endAngle: 360, clockwise: false)
        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY - br))
        path.appendArc(withCenter: NSPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: 0, endAngle: 90, clockwise: false)
        path.line(to: NSPoint(x: rect.minX + bl, y: rect.maxY))
        path.appendArc(withCenter: NSPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: 90, endAngle: 180, clockwise: false)
        path.line(to: NSPoint(x: rect.minX, y: rect.minY + tl))
        path.appendArc(withCenter: NSPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: 180, endAngle: 270, clockwise: false)
        path.close()
        
        return Path(path.cgPath)
    }
}
