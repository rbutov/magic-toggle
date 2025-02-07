//
//  Ui.swift
//  Magic Toggle
//
//  Created by Ruslan Butov on 1/19/25.
//

import Foundation
import CoreGraphics
import AppKit
import IOKit.hid
import IOBluetooth

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

// MARK: - Bluetooth Manager
final class BluetoothManager {
    static let shared = BluetoothManager()
    
    private init() {}
    
    enum BluetoothError: Error {
        case noPairedDevices
        case connectionFailed
    }
    
    func getAllPairedDevices(connected: Bool = false) throws {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            Logger.log("No paired Bluetooth devices found.", level: .warning)
            throw BluetoothError.noPairedDevices
        }
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "bluetooth.connections", attributes: .concurrent)
        
        for device in devices {
            if isMagicDevice(device: device) {
                queue.async(group: group) {
                    self.handleDeviceConnection(device, shouldBeConnected: connected)
                }
            }
        }
        
        // Optional: Wait for all connections to complete (if needed)
        group.notify(queue: .main) {
            Logger.log("All Bluetooth operations completed")
        }
    }
    
    private func handleDeviceConnection(_ device: IOBluetoothDevice, shouldBeConnected: Bool) {
        let deviceName = device.name ?? "Unknown"
        let isConnected = device.isConnected()
        
        if isConnected {
            Logger.log("Apple input device connected: \(deviceName)")
            if !shouldBeConnected {
                device.closeConnection()
                Logger.log("Disconnected: \(deviceName)")
            }
        } else {
            Logger.log("Apple input device not connected: \(deviceName)")
            if shouldBeConnected {
                if device.openConnection() != kIOReturnSuccess {
                    Logger.log("Failed to connect to: \(deviceName)", level: .error)
                } else {
                    Logger.log("Connected: \(deviceName)")
                }
            }
        }
    }
    
    private func isMagicDevice(device: IOBluetoothDevice) -> Bool {
        return device.deviceClassMajor == kBluetoothDeviceClassMajorPeripheral
    }
}

// MARK: - Display Manager
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
        let mainScreen = NSScreen.main
        return allScreens
            .filter { $0 != mainScreen }
            .map { DisplayInfo(screen: $0, name: $0.localizedName, frame: $0.frame) }
    }
}

// MARK: - App Delegate (Menu Bar App)
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var monitorObserver: Any?
    private let bluetoothManager = BluetoothManager.shared
    private let displayManager = DisplayManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
        setupMenuBar()
        startMonitorDetection()
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
        menu.addItem(NSMenuItem(title: "About Magic Toggle", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    private var aboutWindowController: AboutWindowController?
    
    @objc private func showAbout() {
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController()
        }
        aboutWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func startMonitorDetection() {
        monitorObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.detectExternalMonitors()
        }

        detectExternalMonitors() // Initial detection
    }

    @objc private func detectExternalMonitors() {
        let externalDisplays = displayManager.getExternalDisplays()
        Logger.log("Number of external displays: \(externalDisplays.count)")

        for (index, display) in externalDisplays.enumerated() {
            Logger.log("External Screen \(index + 1): \(display.frame) - \(display.name)")
        }

        // Update UI first
        if let button = statusItem?.button {
            if externalDisplays.isEmpty {
                button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "Single Monitor Icon")
            } else {
                button.image = NSImage(systemSymbolName: "display.2", accessibilityDescription: "Dual Monitor Icon")
            }
            button.image?.isTemplate = true
        }
        
        // Then handle Bluetooth devices
        DispatchQueue.main.async {
            do {
                try self.bluetoothManager.getAllPairedDevices(connected: !externalDisplays.isEmpty)
            } catch {
                Logger.log("Failed to manage Bluetooth devices: \(error)", level: .error)
            }
        }
    }

    @objc private func quitApp() {
        if let observer = monitorObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        NSApplication.shared.terminate(nil)
    }
}
