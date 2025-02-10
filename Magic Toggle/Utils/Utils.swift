//
//  Ui.swift
//  Magic Toggle
//
//  Created by Ruslan Butov on 1/19/25.
//

import Cocoa
import Foundation
import SwiftUI

// MARK: - Logger
enum LogLevel {
    case info, warning, error
}

struct Logger {
    static func log(_ message: String, level: LogLevel = .info) {
        #if DEBUG
        let prefix = switch level {
        case .info: "ℹ️"
        case .warning: "⚠️"
        case .error: "❌"
        }
        print("\(prefix) \(message)")
        #endif
    }
}

// MARK: - Shell Command
let blueutilPath = "/opt/homebrew/bin/blueutil"

func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/bash"
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

// MARK: - App Delegate
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var monitorObserver: Any?
    private let displayManager = DisplayManager.shared
    private var previousDisplayCount = 0
    private var aboutWindowController: AboutWindowController?
    private var devicesWindowController: DevicesWindowController?
    private var blueUtilWarningController: BlueUtilWarningWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check for blueutil first
        if !checkBlueUtilInstallation() {
            blueUtilWarningController = BlueUtilWarningWindowController()
            blueUtilWarningController?.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Continue with normal app initialization
        NSApp.setActivationPolicy(.prohibited)
        setupMenuBar()
        startMonitorDetection()
        previousDisplayCount = displayManager.getExternalDisplays().count
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else {
            Logger.log("Failed to create status item button", level: .error)
            return
        }
        
        button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "Monitor Icon")
        button.image?.isTemplate = true

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Devices...", action: #selector(showDevices), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About Magic Toggle", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: ""))
        statusItem?.menu = menu
    }
    
    // MARK: - Window Management
    @objc private func showAbout() {
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController()
        }
        aboutWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showDevices() {
        if devicesWindowController == nil {
            devicesWindowController = DevicesWindowController()
        }
        devicesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        DeviceManager.shared.refreshDevices()
    }

    // MARK: - Monitor Detection
    private func startMonitorDetection() {
        monitorObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let currentDisplayCount = self.displayManager.getExternalDisplays().count
            if currentDisplayCount != self.previousDisplayCount {
                self.detectExternalMonitors()
                self.previousDisplayCount = currentDisplayCount
            }
        }
    }

    @objc private func detectExternalMonitors() {
        let externalDisplays = displayManager.getExternalDisplays()
        Logger.log("Number of external displays: \(externalDisplays.count)")

        updateStatusBarIcon(hasExternalDisplays: !externalDisplays.isEmpty)
        DeviceManager.shared.handleDisplayConnection(hasExternalDisplay: !externalDisplays.isEmpty)
    }
    
    private func updateStatusBarIcon(hasExternalDisplays: Bool) {
        guard let button = statusItem?.button else { return }
        
        let iconName = hasExternalDisplays ? "display.2" : "display"
        button.image = NSImage(systemSymbolName: iconName, 
                             accessibilityDescription: hasExternalDisplays ? "Dual Monitor Icon" : "Single Monitor Icon")
        button.image?.isTemplate = true
    }

    @objc private func quitApp() {
        if let observer = monitorObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        NSApplication.shared.terminate(nil)
    }

    private func checkBlueUtilInstallation() -> Bool {
        let process = Process()
        process.launchPath = "/usr/bin/which"
        process.arguments = [blueutilPath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

