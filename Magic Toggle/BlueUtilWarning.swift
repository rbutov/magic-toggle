import SwiftUI

struct BlueUtilWarningView: View {
    @State private var isCopied = false
    private let installCommand = "brew install blueutil"
    
    var body: some View {
        VStack(spacing: 16) {
            Text("blueutil Not Found")
                .font(.headline)
            
            Text("Magic Toggle requires blueutil to function. Please install it using Homebrew:")
                .multilineTextAlignment(.center)
            
            HStack {
                Text(installCommand)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(installCommand, forType: .string)
                    isCopied = true
                    
                    // Reset copy indicator after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                }) {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundColor(isCopied ? .green : .blue)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }
            
            Link("Learn More", destination: URL(string: "https://github.com/toy/blueutil")!)
                .padding(.top)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 

class BlueUtilWarningWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "Missing Dependency"
        window.contentView = NSHostingView(rootView: BlueUtilWarningView())
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        self.init(window: window)
    }
}