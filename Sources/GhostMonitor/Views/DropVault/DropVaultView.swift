import SwiftUI

public struct DropVaultOverlayView: View {
    @StateObject private var vault = DropVaultService.shared
    @State private var isTargeted = false
    
    public var body: some View {
        VStack {
            HStack {
                Text("Drop Vault")
                    .font(.headline)
                Spacer()
                Button(action: {
                    vault.clearVault()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
            
            ScrollView {
                VStack(spacing: 10) {
                    if vault.stashedItems.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Drag files here to stash them")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else {
                        ForEach(Array(vault.stashedItems.enumerated()), id: \.element) { index, url in
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.blue)
                                Text(url.lastPathComponent)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button(action: {
                                    vault.removeItem(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            // Allow dragging OUT of the vault
                            .onDrag {
                                NSItemProvider(object: url as NSURL)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(isTargeted ? Color.blue : Color.secondary.opacity(0.3), lineWidth: isTargeted ? 3 : 1)
                )
        )
        .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers in
            for provider in providers {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data,
                       let urlString = String(data: data, encoding: .utf8),
                       let url = URL(string: urlString) {
                        DispatchQueue.main.async {
                            vault.addItems([url])
                        }
                    }
                }
            }
            return true
        }
    }
}

public struct DropVaultMainView: View {
    @StateObject private var vault = DropVaultService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 30) {
            Text("The Drop Vault")
                .font(.largeTitle.bold())
            
            Text("A floating temporary shelf for your files. Drag files into it, switch apps, and drag them out!")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 80))
                .foregroundColor(vault.isVaultOpen ? .blue : .secondary)
            
            Button(action: {
                vault.toggleVault()
            }) {
                Text(vault.isVaultOpen ? "Close Vault" : "Open Drop Vault")
                    .font(.title3.bold())
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .tint(vault.isVaultOpen ? .red : .blue)
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
