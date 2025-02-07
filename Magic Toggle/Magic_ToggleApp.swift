//
//  Magic_ToggleApp.swift
//  Magic Toggle
//
//  Created by Ruslan Butov on 1/19/25.
//

import SwiftUI
import AppKit

@main
struct Magic_ToggleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No window, only settings (optional)
        Settings {
            EmptyView()
        }
    }
}
