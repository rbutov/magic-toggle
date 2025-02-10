import SwiftUI
import IOBluetooth

// MARK: - Main View
struct DevicesView: View {
    @StateObject private var deviceManager = DeviceManager.shared
    @State private var showOnlySaved = true
    
    var filteredDevices: [AppleDevice] {
        showOnlySaved ? deviceManager.devices.filter { $0.isSaved } : deviceManager.devices
    }
    
    var body: some View {
        VStack {
            ToolbarView(
                showOnlySaved: $showOnlySaved,
                hasAnyPairedSavedDevices: hasAnyPairedSavedDevices,
                hasSavedDevices: hasSavedDevices
            )
            
            DeviceListView(devices: filteredDevices)
            
            FooterView()
        }
        .frame(minWidth: 450, minHeight: 400)
    }
    
    private var hasAnyPairedSavedDevices: Bool {
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return false
        }
        let pairedIds = Set(pairedDevices.compactMap { $0.addressString })
        return deviceManager.devices.filter { $0.isSaved }.contains { pairedIds.contains($0.id) }
    }
    
    private var hasSavedDevices: Bool {
        !deviceManager.devices.filter { $0.isSaved }.isEmpty
    }
}

// MARK: - Supporting Views
struct ToolbarView: View {
    @Binding var showOnlySaved: Bool
    let hasAnyPairedSavedDevices: Bool
    let hasSavedDevices: Bool
    @ObservedObject private var deviceManager = DeviceManager.shared
    
    var body: some View {
        HStack {
            Toggle("Show only saved devices", isOn: $showOnlySaved)
            
            Spacer()
            
            if hasSavedDevices {
                PairUnpairButton(hasAnyPairedSavedDevices: hasAnyPairedSavedDevices)
            }
            
            Button("Refresh") {
                deviceManager.refreshDevices()
            }
        }
        .padding([.horizontal, .top])
    }
}

struct DeviceListView: View {
    let devices: [AppleDevice]
    
    var body: some View {
        List {
            ForEach(devices) { device in
                DeviceRow(device: device)
            }
        }
    }
}

struct FooterView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes:")
                .font(.caption)
                .bold()
            Text("• Saved devices will be auto-connected when external display is connected")
            Text("• Last seen times are preserved between app launches")
            Text("• Green dot indicates currently connected devices")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

struct DeviceRow: View {
    @ObservedObject var device: AppleDevice
    @ObservedObject private var deviceManager = DeviceManager.shared
    @State private var isAnimating = false
    
    private var statusColor: Color {
        switch device.operationStatus {
        case .idle:
            if !isPaired {
                return .gray
            }
            return device.isConnected ? .green : .red
        case .pairing:
            return .yellow
        case .connecting:
            return .blue
        case .unpairing:
            return .orange
        }
    }
    
    private var statusIcon: String {
        switch device.operationStatus {
        case .idle:
            return "circle.fill"
        case .pairing:
            return "rays"
        case .connecting:
            return "antenna.radiowaves.left.and.right"
        case .unpairing:
            return "xmark.circle"
        }
    }
    
    private var isPaired: Bool {
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return false
        }
        return pairedDevices.contains { $0.addressString == device.id }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .frame(width: 16)
                .symbolEffect(.pulse, options: .repeating, isActive: device.operationStatus != .idle)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(device.id)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(width: 100)
                    
                    Text("Last seen: \(timeAgo(date: device.lastSeen))")
                        .frame(minWidth: 100, alignment: .leading)
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { device.isSaved },
                set: { _ in 
                    deviceManager.toggleSaved(deviceId: device.id)
                }
            ))
            .toggleStyle(.switch)
            .animation(.easeInOut, value: device.isSaved)
            
            // Only show remove button for unpaired devices
            if !isPaired {
                Button(action: {
                    deviceManager.removeDevice(deviceId: device.id)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Remove device from history")
            }
        }
        .padding(.vertical, 4)
        .onChange(of: device.operationStatus) { oldValue, newValue in
            isAnimating = newValue != .idle
        }
    }
    
    private func timeAgo(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct PairUnpairButton: View {
    let hasAnyPairedSavedDevices: Bool
    @ObservedObject private var deviceManager = DeviceManager.shared
    
    var body: some View {
        Button(action: {
            if hasAnyPairedSavedDevices {
                deviceManager.unpairAllSavedDevices()
            } else {
                deviceManager.pairAllSavedDevices()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: hasAnyPairedSavedDevices ? "minus.circle" : "plus.circle")
                Text(hasAnyPairedSavedDevices ? "Unpair Saved" : "Pair Saved")
            }
        }
        .help(hasAnyPairedSavedDevices ? "Unpair all saved devices" : "Pair and connect all saved devices")
    }
}

class DevicesWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Magic Toggle Devices"
        window.contentView = NSHostingView(rootView: DevicesView())
        window.isReleasedWhenClosed = false
        
        self.init(window: window)
    }
}
