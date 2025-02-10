import AppKit
import Foundation

final class DisplayManager {
    static let shared = DisplayManager()
    
    private init() {}
    
    struct DisplayInfo {
        let screen: NSScreen
        let name: String
        let frame: CGRect
    }
    
    func getExternalDisplays() -> [DisplayInfo] {
        let allScreens = NSScreen.screens

        return allScreens
            .filter { screen in
                let name = screen.localizedName.lowercased()
                return !name.contains("built-in")
            }
            .map { DisplayInfo(screen: $0, name: $0.localizedName, frame: $0.frame) }
    }
} 