import SwiftUI

struct AboutView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSImage(systemSymbolName: "display.2", accessibilityDescription: "App Icon") ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
                
            Text("Magic Toggle")
                .font(.title)
                .bold()
            
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.caption)
            
            Text("Automatically manages Magic Devices connections based on external display status.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("© 2025 Ruslan Butov")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 300, height: 250)
        .padding()
    }
}

class AboutWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 250),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "About Magic Toggle"
        window.contentView = NSHostingView(rootView: AboutView())
        window.isReleasedWhenClosed = false
        
        self.init(window: window)
    }
} 