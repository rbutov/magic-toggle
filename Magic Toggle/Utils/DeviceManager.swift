import Foundation
import IOBluetooth

private extension NSNotification.Name {
    static let bluetoothDeviceConnected = NSNotification.Name(rawValue: "IOBluetoothDeviceDidConnectNotification")
    static let bluetoothDeviceDisconnected = NSNotification.Name(rawValue: "IOBluetoothDeviceDidDisconnectNotification")
    static let bluetoothDevicePaired = NSNotification.Name(rawValue: "IOBluetoothDevicePairingNotification")
    static let bluetoothDeviceUnpaired = NSNotification.Name(rawValue: "IOBluetoothDeviceUnpairedNotification")
}

enum DeviceOperationStatus {
    case idle
    case pairing
    case connecting
    case unpairing
}

class AppleDevice: NSObject, Codable, Identifiable, ObservableObject {
    let id: String // MAC address
    let name: String
    @Published var isSaved: Bool
    var lastSeen: Date
    
    // Non-codable properties
    @Published var isConnected: Bool = false
    @Published var operationStatus: DeviceOperationStatus = .idle
    
    // Add function to help with state changes (no longer needs mutating)
    func toggleSaved() {
        isSaved.toggle()
    }
    
    static func == (lhs: AppleDevice, rhs: AppleDevice) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, isSaved, lastSeen
    }
    
    init(id: String, name: String, isSaved: Bool, lastSeen: Date, isConnected: Bool = false) {
        self.id = id
        self.name = name
        self._isSaved = Published(initialValue: isSaved)
        self.lastSeen = lastSeen
        self._isConnected = Published(initialValue: isConnected)
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let savedValue = try container.decode(Bool.self, forKey: .isSaved)
        _isSaved = Published(initialValue: savedValue)
        lastSeen = try container.decode(Date.self, forKey: .lastSeen)
        _isConnected = Published(initialValue: false)
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isSaved, forKey: .isSaved)
        try container.encode(lastSeen, forKey: .lastSeen)
    }
}

class DeviceManager: ObservableObject {
    static let shared = DeviceManager()
    
    @Published var devices: [AppleDevice] = []
    private let savedDevicesKey = "SavedAppleDevices"
    private let allDevicesKey = "AllAppleDevices"
    
    private init() {
        refreshDevices()
        startObservingBluetoothChanges()
    }
    
    deinit {
        stopObservingBluetoothChanges()
    }
    
    private func startObservingBluetoothChanges() {
        // Add a periodic refresh as a backup
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshDevices()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBluetoothChange),
            name: .bluetoothDeviceConnected,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBluetoothChange),
            name: .bluetoothDeviceDisconnected,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBluetoothChange),
            name: .bluetoothDevicePaired,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBluetoothChange),
            name: .bluetoothDeviceUnpaired,
            object: nil
        )
    }
    
    private func stopObservingBluetoothChanges() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleBluetoothChange(_ notification: Notification) {
        Logger.log("Bluetooth device status changed: \(notification.name)", level: .info)
        if let device = notification.object as? IOBluetoothDevice {
            Logger.log("Device: \(device.name ?? "Unknown") (\(device.addressString ?? "No address"))", level: .info)
        }
        DispatchQueue.main.async { [weak self] in
            self?.refreshDevices()
        }
    }
    
    func refreshDevices() {
        // Get current devices
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return
        }
        
        // Get saved device IDs for existing devices
        let savedIds = UserDefaults.standard.stringArray(forKey: savedDevicesKey) ?? []
        
        let currentDevices = pairedDevices
            .filter { $0.deviceClassMajor == kBluetoothDeviceClassMajorPeripheral }
            .compactMap { device -> AppleDevice? in
                guard let deviceId = device.addressString, !deviceId.isEmpty else {
                    Logger.log("Found device with no address, skipping", level: .warning)
                    return nil
                }
                
                let deviceName = device.name ?? "Unknown Device"
                
                // Check if this is an existing device
                let isExistingDevice = devices.contains { $0.id == deviceId }
                
                return AppleDevice(
                    id: deviceId,
                    name: deviceName,
                    isSaved: isExistingDevice ? savedIds.contains(deviceId) : true,  // New devices are saved by default
                    lastSeen: Date(),
                    isConnected: device.isConnected()
                )
            }
        
        // Load existing devices if array is empty
        if devices.isEmpty {
            devices = loadStoredDevices()
        }
        
        // Update or add current devices, never remove
        for currentDevice in currentDevices {
            if let index = devices.firstIndex(where: { $0.id == currentDevice.id }) {
                // Preserve existing device's saved status
                let isSaved = devices[index].isSaved
                let updatedDevice = currentDevice
                updatedDevice.isSaved = isSaved
                devices[index] = updatedDevice
            } else {
                // New device is saved by default
                devices.append(currentDevice)
            }
        }
        
        // Sort devices: Connected first, then by last seen
        devices.sort { (device1, device2) in
            if device1.isConnected != device2.isConnected {
                return device1.isConnected
            }
            return device1.lastSeen > device2.lastSeen
        }
        
        saveDevices(devices)
        
        // Sync saved devices
        let newSavedIds = devices.filter { $0.isSaved }.map { $0.id }
        UserDefaults.standard.set(newSavedIds, forKey: savedDevicesKey)
    }
    
    private func loadStoredDevices() -> [AppleDevice] {
        guard let data = UserDefaults.standard.data(forKey: allDevicesKey),
              let devices = try? JSONDecoder().decode([AppleDevice].self, from: data) else {
            return []
        }
        return devices
    }
    
    private func saveDevices(_ devices: [AppleDevice]) {
        guard let data = try? JSONEncoder().encode(devices) else { return }
        UserDefaults.standard.set(data, forKey: allDevicesKey)
    }
    
    func toggleSaved(deviceId: String) {
        if let index = devices.firstIndex(where: { $0.id == deviceId }) {
            // Create a mutable copy of the device and toggle its state
            let updatedDevice = devices[index]
            updatedDevice.toggleSaved()
            
            // Update the device in the array
            var updatedDevices = devices
            updatedDevices[index] = updatedDevice
            
            // Update the published property with the new array
            self.devices = updatedDevices
            
            // Update saved devices list
            let savedIds = devices.filter { $0.isSaved }.map { $0.id }
            UserDefaults.standard.set(savedIds, forKey: savedDevicesKey)
            
            // Save all devices
            saveDevices(devices)
            
            // Force UI update
            objectWillChange.send()
        }
    }
    
    func getSavedDevices() -> [AppleDevice] {
        return devices.filter { $0.isSaved }
    }
    
    func handleDisplayConnection(hasExternalDisplay: Bool) {
        let savedDevices = devices.filter { $0.isSaved }
        
        Task.detached {
            for device in savedDevices {
                // Skip devices without valid ID
                guard !device.id.isEmpty else {
                    Logger.log("Skipping device with no address", level: .warning)
                    continue
                }
                
                if hasExternalDisplay {
                    // Update UI state immediately
                    self.updateDeviceStatus(device.id, status: .pairing)
                    
                    // Use 30 attempts for external display connection
                    let pairSuccess = await self.pairDeviceAndWait(deviceId: device.id, maxAttempts: 30)
                    if pairSuccess {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                        self.updateDeviceStatus(device.id, status: .connecting)
                        self.connectDevice(deviceId: device.id)
                    } else {
                        self.updateDeviceStatus(device.id, status: .idle)
                    }
                } else {
                    self.unpairDevice(deviceId: device.id)
                }
            }
            
            // Refresh devices after operations are complete
            self.refreshDevices()
        }
    }
    
    func removeDevice(deviceId: String) {
        // Only remove if device is not currently paired
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice],
              !pairedDevices.contains(where: { $0.addressString == deviceId }) else {
            return
        }
        
        devices.removeAll { $0.id == deviceId }
        
        // Update saved devices list
        let savedIds = devices.filter { $0.isSaved }.map { $0.id }
        UserDefaults.standard.set(savedIds, forKey: savedDevicesKey)
        
        // Save updated devices list
        saveDevices(devices)
        
        // Force UI update
        objectWillChange.send()
    }

    // MARK: - Error Detection
    private func isErrorOutput(_ output: String) -> Bool {
        let errorPatterns = [
            "error",
            "Failed",
            "Timeout",
            "0x"  // Hex error codes
        ]
        
        return errorPatterns.contains { output.contains($0) }
    }
    
    private func isPairingSuccessful(deviceId: String) -> Bool {
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return false
        }
        return pairedDevices.contains { $0.addressString == deviceId }
    }

    private func executeWithRetry(command: String, description: String, maxAttempts: Int = 30) async -> Bool {
        for attempt in 1...maxAttempts {
            Logger.log("\(description) (Attempt \(attempt)/\(maxAttempts))", level: .info)
            
            let output = shell(command)
            Logger.log("Command output: '\(output)'", level: .info)
            
            // For pairing, check if device is actually paired
            if description.contains("Pairing") {
                if let deviceId = command.components(separatedBy: " ").last?.replacingOccurrences(of: "\"", with: ""),
                   isPairingSuccessful(deviceId: deviceId) {
                    Logger.log("Device is paired successfully: \(deviceId)", level: .info)
                    return true
                }
            }
            // For connecting, check if device is actually connected
            else if description.contains("Connecting") {
                if let deviceId = command.components(separatedBy: " ").last?.replacingOccurrences(of: "\"", with: ""),
                   isDeviceConnected(deviceId: deviceId) {
                    Logger.log("Device is connected successfully: \(deviceId)", level: .info)
                    return true
                }
            }
            
            // Check for empty output or errors
            if output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Logger.log("Empty output, considering as failure", level: .warning)
                // Continue to next attempt
            } else if !isErrorOutput(output) {
                Logger.log("Success: \(description)", level: .info)
                return true
            }
            
            Logger.log("Failed: \(description) - \(output)", level: .warning)
            
            if attempt < maxAttempts {
                let delay = 1.0 // 1 second delay between attempts
                Logger.log("Retrying in \(delay) seconds...", level: .info)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        Logger.log("All attempts failed for: \(description)", level: .error)
        return false
    }
    
    func pairAllSavedDevices() {
        let savedDevices = devices.filter { $0.isSaved }
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            // Create array of async tasks
            await withTaskGroup(of: Void.self) { group in
                for device in savedDevices {
                    group.addTask {
                        // Update UI state immediately
                        self.updateDeviceStatus(device.id, status: .pairing)
                        
                        let pairSuccess = await self.pairDeviceAndWait(deviceId: device.id)
                        if pairSuccess {
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                            
                            // Update UI state for connecting
                            self.updateDeviceStatus(device.id, status: .connecting)
                            self.connectDevice(deviceId: device.id)
                        } else {
                            // Reset status if pairing failed
                            self.updateDeviceStatus(device.id, status: .idle)
                        }
                    }
                }
            }
        }
    }
    
    private func pairDeviceAndWait(deviceId: String, maxAttempts: Int = 1) async -> Bool {
        let command = "\"\(blueutilPath)\" --pair \(deviceId)"
        return await executeWithRetry(
            command: command,
            description: "Pairing device: \(deviceId)",
            maxAttempts: maxAttempts
        )
    }
    
    private func updateDeviceStatus(_ deviceId: String, status: DeviceOperationStatus) {
        DispatchQueue.main.async {
            if let index = self.devices.firstIndex(where: { $0.id == deviceId }) {
                self.devices[index].operationStatus = status
            }
        }
    }
    
    func pairDevice(deviceId: String) {
        // Update UI state immediately
        updateDeviceStatus(deviceId, status: .pairing)
        
        Task.detached {
            let success = await self.pairDeviceAndWait(deviceId: deviceId)
            self.updateDeviceStatus(deviceId, status: .idle)
            if success {
                self.refreshDevices()
            }
        }
    }
    
    func connectDevice(deviceId: String) {
        // Update UI state immediately
        updateDeviceStatus(deviceId, status: .connecting)
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            Logger.log("Connecting device: \(deviceId)", level: .info)
            let command = "\"\(blueutilPath)\" --connect \(deviceId)"
            let success = await self.executeWithRetry(
                command: command,
                description: "Connecting device: \(deviceId)",
                maxAttempts: 5  // Use fewer attempts for connection
            )
            
            if success {
                Logger.log("Successfully connected device: \(deviceId)", level: .info)
            } else {
                Logger.log("Failed to connect device: \(deviceId)", level: .error)
            }
            
            self.updateDeviceStatus(deviceId, status: .idle)
            
            self.refreshDevices()
        }
    }
    
    private func isDeviceConnected(deviceId: String) -> Bool {
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice],
              let device = pairedDevices.first(where: { $0.addressString == deviceId }) else {
            return false
        }
        return device.isConnected()
    }
    
    func unpairDevice(deviceId: String) {
        // Update UI state immediately
        updateDeviceStatus(deviceId, status: .unpairing)
        
        Task.detached {
            Logger.log("Unpairing device: \(deviceId)", level: .info)
            _ = shell("\"\(blueutilPath)\" --unpair \(deviceId)")
            Logger.log("Done unpairing device: \(deviceId)", level: .info)
            self.updateDeviceStatus(deviceId, status: .idle)
            
            DispatchQueue.main.async {
                self.refreshDevices()
            }
        }
    }
    
    func unpairAllSavedDevices() {
        let savedDevices = devices.filter { $0.isSaved }
        
        Task.detached {
            // Create array of async tasks
            await withTaskGroup(of: Void.self) { group in
                for device in savedDevices {
                    group.addTask {
                        // Update UI state immediately
                        self.updateDeviceStatus(device.id, status: .unpairing)
                        self.unpairDevice(deviceId: device.id)
                    }
                }
            }
        }
    }
}
